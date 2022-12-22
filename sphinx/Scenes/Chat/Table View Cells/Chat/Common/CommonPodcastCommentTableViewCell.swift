//
//  CommonPodcastCommentTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class CommonPodcastCommentTableViewCell : CommonReplyTableViewCell, AudioCollectionViewItem {

    @IBOutlet weak var bubbleView: AudioBubbleView!
    @IBOutlet weak var messageBubbleView: MessageBubbleView!
    @IBOutlet weak var lockSign: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var audioPlayerContainer: UIView!
    @IBOutlet weak var playButtonCircle: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var audioTrackLine: UIView!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var currentTimeDot: UIView!
    @IBOutlet weak var dotGestureHandler: UIView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var currentTimeDotLeftConstraint: NSLayoutConstraint!

    static let kAudioBubbleHeight: CGFloat = 70.0
    static let kAudioSentBubbleWidth: CGFloat = 282.0
    static let kAudioReceivedBubbleWidth: CGFloat = 280.0
    static let kComposedBubbleMessageMargin: CGFloat = 2
    
    var wasPlayingOnDrag = false
    
    var loading = false {
        didSet {
            playButton.alpha = loading ? 0.0 : 1.0
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.Sphinx.Text)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        audioTrackLine.layer.cornerRadius = audioTrackLine.frame.size.height / 2
        currentTimeDot.layer.cornerRadius = currentTimeDot.frame.size.height / 2
        playButtonCircle.layer.cornerRadius = playButtonCircle.frame.width / 2
        
        addDotGesture()
    }
    
    override func getBubbbleView() -> UIView? {
        return messageBubbleView
    }
    
    func addDotGesture() {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(wasDragged))
        dotGestureHandler.addGestureRecognizer(gesture)
        dotGestureHandler.isUserInteractionEnabled = true
    }
    
    @objc func wasDragged(gestureRecognizer: UIPanGestureRecognizer) {
        guard let podcastPlayer = messageRow?.podcastPlayerHelper else {
            return
        }
        
        let x = getGestureXPosition(gestureRecognizer)
        
        switch(gestureRecognizer.state) {
        case .began:
            shouldPreventOtherGestures = true
            wasPlayingOnDrag = podcastPlayer.playing
            podcastPlayer.stopPlaying()
            break
        case .changed:
            let totalProgressWidth = audioTrackLine.frame.size.width
            let translation = (x < 0) ? 0 : ((x > totalProgressWidth) ? totalProgressWidth : x)
            let progress = ((translation * 100) / audioTrackLine.frame.size.width) / 100

            podcastPlayer.shouldUpdateTimeLabels(progress: Double(progress))
            break
        case .ended:
            shouldPreventOtherGestures = false
            loading = wasPlayingOnDrag
            let progress = ((currentTimeDotLeftConstraint.constant * 100) / audioTrackLine.frame.size.width) / 100
            podcastPlayer.seekTo(progress: Double(progress), play: wasPlayingOnDrag)
            wasPlayingOnDrag = false
            break
        default:
            break
        }
    }
    
    func getGestureXPosition(_ gestureRecognizer: UIPanGestureRecognizer) -> CGFloat {
        let totalProgressWidth = CGFloat(audioTrackLine.frame.size.width)
        let dotMinimumX = audioTrackLine.frame.origin.x
        let x = gestureRecognizer.location(in: self.audioPlayerContainer).x - dotMinimumX
        return (x < 0) ? 0 : ((x > totalProgressWidth) ? totalProgressWidth : x)
    }
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        self.configureRow(messageRow: messageRow, contact: contact, chat: chat)
        messageRow.configurePodcastPlayer()
        
        titleLabel.text = messageRow.transactionMessage.podcastComment?.title ?? "title.not.available".localized
        
        resetPlayer()
    }
    
    func loadAudio(podcastComment: PodcastComment, podcast: PodcastFeed?, messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        toggleLoadingAudio(loading: true)

        let messageId = messageRow.transactionMessage.id
        
        messageRow.podcastPlayerHelper?.setCallbacks(progressCallback: updateCurrentTime, endCallback: audioDidFinishPlaying, pauseCallback: audioDidPausePlaying, playCallback: audioDidResumePlaying)
        
        messageRow.podcastPlayerHelper?.createPlayerItemWith(podcastComment: podcastComment, podcast: podcast, delegate: self, for: messageId, completion: { (messageId) in
            if self.isDifferentRow(messageId: messageId) { return }
            self.setAudioPlayerInitialTime()
            self.audioReady()
        })
    }
    
    func toggleLoadingAudio(loading: Bool) {
        self.loading = loading
    }
    
    func audioReady() {
        setCurrentTime()
        toggleLoadingAudio(loading: false)
    }
    
    func setCurrentTime() {
        if let audioPlayerHelper = messageRow?.podcastPlayerHelper, audioPlayerHelper.currentTime > 0 {
            let playing = audioPlayerHelper.playing
            updateControls(buttonTitle: playing ? "pause" : "play_arrow", color: CommonAudioTableViewCell.kBlueControlsColor)
            updateCurrentTime(duration: getAudioDuration(), currentTime: Double(audioPlayerHelper.currentTime), animated: false)
        } else {
            updateControls(buttonTitle: "play_arrow", color: CommonAudioTableViewCell.kBlueControlsColor)
            updateTimeLabel(duration: getAudioDuration(), currentTime: 0.0)
        }
    }
    
    func getAudioDuration() -> Double {
        if let audioPlayerHelper = messageRow?.podcastPlayerHelper {
            return audioPlayerHelper.getAudioDuration()
        }
        return 0
    }
    
    func audioLoadingFailed() {
        playButton.isEnabled = false
        toggleLoadingAudio(loading: false)
    }
    
    func configureLockSign() {
        let encrypted = (messageRow?.transactionMessage.encrypted ?? false)
        lockSign.textColor = UIColor.Sphinx.WashedOutReceivedText
        lockSign.text = encrypted ? "lock" : ""
    }
    
    @IBAction func playButtonTouched() {
        if let messageId = self.messageRow?.transactionMessage.id, let audioPlayerHelper = messageRow?.podcastPlayerHelper {
            audioDelegate?.shouldStopPlayingAudios(cell: self)
            let didPlay = audioPlayerHelper.playAudioFrom(messageId: messageId)
            loading = didPlay
            
            if didPlay {
                updateControls(buttonTitle: "pause", color: CommonAudioTableViewCell.kBlueControlsColor)
            }
        }
    }
    
    func setAudioPlayerInitialTime() {
        if let audioPlayerHelper = messageRow?.podcastPlayerHelper {
            let ts = messageRow?.transactionMessage.podcastComment?.timestamp ?? 0
            audioPlayerHelper.setInitialTime(startTime: Double(ts))
        }
    }
    
    func getTimePercentage() -> Double {
        let totalWidth = CGFloat(audioTrackLine.frame.size.width) - CGFloat(currentTimeDot.frame.size.width)
        let startTimePercentage = currentTimeDotLeftConstraint.constant * 100 / totalWidth
        return Double(startTimePercentage)
    }
    
    func audioDidPausePlaying() {
        updateControls(buttonTitle: "play_arrow", color: CommonAudioTableViewCell.kBlueControlsColor)
    }
    
    func audioDidResumePlaying() {
        if let chat = chat,
            PodcastPlayerHelper.sharedInstance.isPlaying(chat.id) {
            PodcastPlayerHelper.sharedInstance.shouldPause()
        }
        updateControls(buttonTitle: "pause", color: CommonAudioTableViewCell.kBlueControlsColor)
    }
    
    func audioDidFinishPlaying() {
        DelayPerformedHelper.performAfterDelay(seconds: 0.2, completion: {
            self.resetPlayer()
        })
    }
    
    func stopPlaying() {
        if let audioPlayerHelper = messageRow?.podcastPlayerHelper {
            audioPlayerHelper.stopPlaying()
            
            if audioPlayerHelper.currentTime > 0 {
                updateControls(buttonTitle: "play_arrow", color: CommonAudioTableViewCell.kBlueControlsColor, dotVisible: true)
            }
        }
    }
    
    func resetPlayer() {
        updateControls(buttonTitle: "play_arrow", color: CommonAudioTableViewCell.kBlueControlsColor, dotVisible: false)
        updateTimeLabel(duration: 0, currentTime: 0)
        currentTimeDotLeftConstraint.constant = 0
        currentTimeDot.superview?.layoutIfNeeded()
    }
    
    func updateCurrentTime(duration: Double, currentTime: Double) {
        updateCurrentTime(duration: duration, currentTime: currentTime, animated: true)
    }
    
    func updateCurrentTime(duration: Double, currentTime: Double, animated: Bool) {
        let totalWidth = CGFloat(audioTrackLine.frame.size.width)
        let expectedWith = (CGFloat(currentTime) * totalWidth) / CGFloat(duration)
        
        if !expectedWith.isFinite || expectedWith < 0 {
            return
        }
        
        currentTimeDotLeftConstraint.constant = expectedWith
        updateTimeLabel(duration: duration, currentTime: currentTime)
        
        if !animated {
            currentTimeDot.superview?.layoutIfNeeded()
            return
        }
        
        UIView.animate(withDuration: 0.05, animations: {
            self.currentTimeDot.superview?.layoutIfNeeded()
        })
    }
    
    func updateTimeLabel(duration: Double, currentTime: Double) {
        playButton.isEnabled = duration > 0
        
        durationLabel.text = Int(duration).getPodcastTimeString()
        currentTimeLabel.text = Int(currentTime).getPodcastTimeString()
    }
    
    func updateControls(buttonTitle: String, color: UIColor, dotVisible: Bool = true) {
        currentTimeDot.alpha = dotVisible ? 1.0 : 0.0
        playButton.setTitleColor(color, for: .normal)
        playButton.setTitle(buttonTitle, for: .normal)
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let replyTopPadding = CommonChatTableViewCell.getReplyTopPadding(message: messageRow.transactionMessage)
        let audioBubbleHeight = kAudioBubbleHeight + CommonChatTableViewCell.kBubbleTopMargin + CommonChatTableViewCell.kBubbleBottomMargin + replyTopPadding
        
        if messageRow.transactionMessage.hasMessageContent() {
            let bubbleWidth = messageRow.isIncoming() ? kAudioReceivedBubbleWidth : kAudioSentBubbleWidth
            let (_, bubbleSize) = MessageBubbleView.getLabelAndBubbleSize(messageRow: messageRow, maxBubbleWidth: bubbleWidth)
            
            return bubbleSize.height + audioBubbleHeight + kComposedBubbleMessageMargin
        }
        
        return audioBubbleHeight
    }
}

extension CommonPodcastCommentTableViewCell : PodcastPlayerRowDelegate {
    func shouldToggleLoadingWheel(loading: Bool) {
        toggleLoadingAudio(loading: loading)
    }
    
    func shouldUpdateLabels(duration: Int, currentTime: Int) {
        guard let podcastPlayer = messageRow?.podcastPlayerHelper else {
            return
        }
        
        updateCurrentTime(duration: Double(duration), currentTime: Double(currentTime))

        if currentTime >= duration && podcastPlayer.playing {
            audioDidFinishPlaying()
        }
    }
}
