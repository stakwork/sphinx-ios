//
//  CommonAudioTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 28/02/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol AudioCollectionViewItem {
    func stopPlaying()
}

protocol AudioCellDelegate {
    func shouldStopPlayingAudios(cell: AudioCollectionViewItem?)
}

class CommonAudioTableViewCell : CommonReplyTableViewCell, AudioCollectionViewItem {
    
    @IBOutlet weak var bubbleView: AudioBubbleView!
    @IBOutlet weak var lockSign: UILabel!
    @IBOutlet weak var audioPlayerContainer: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var audioTrackLine: UIView!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var currentTimeDot: UIView!
    @IBOutlet weak var dotGestureHandler: UIView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var currentTimeDotLeftConstraint: NSLayoutConstraint!
    
    static let kAudioBubbleHeight: CGFloat = 62.0
    static let kAudioSentBubbleWidth: CGFloat = 262.0
    static let kAudioReceivedBubbleWidth: CGFloat = 260.0
    
    static let kBlueControlsColor = UIColor.Sphinx.ReceivedIcon
    static let kGrayControlsColor = UIColor.Sphinx.Text
    
    var audioDuration: Double = 0
    
    var loading = false {
        didSet {
            playButton.alpha = loading ? 0.0 : 1.0
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.Sphinx.Text)
        }
    }
    
    var audioData : Data? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        audioTrackLine.layer.cornerRadius = audioTrackLine.frame.size.height / 2
        currentTimeDot.layer.cornerRadius = currentTimeDot.frame.size.height / 2
        
        addDotGesture()
    }
    
    func addDotGesture() {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(wasDragged))
        dotGestureHandler.addGestureRecognizer(gesture)
        dotGestureHandler.isUserInteractionEnabled = true
    }
    
    @objc func wasDragged(gestureRecognizer: UIPanGestureRecognizer) {
        switch(gestureRecognizer.state) {
        case .began:
            shouldPreventOtherGestures = true
            setPorgressOnDrag(gestureRecognizer)
            break
        case .changed:
            setPorgressOnDrag(gestureRecognizer)
            break
        case .ended:
            shouldPreventOtherGestures = false
            break
        default:
            break
        }
    }
    
    func setPorgressOnDrag(_ gestureRecognizer: UIPanGestureRecognizer) {
        let totalProgressWidth = CGFloat(audioTrackLine.frame.size.width) - CGFloat(currentTimeDot.frame.size.width)
        let dotMinimumX = audioTrackLine.frame.origin.x
        var translation = gestureRecognizer.location(in: self.audioPlayerContainer).x - dotMinimumX
        translation = (translation < 0) ? 0 : ((translation > totalProgressWidth) ? totalProgressWidth : translation)
        
        currentTimeDotLeftConstraint.constant = translation
        currentTimeDot.superview?.layoutIfNeeded()
        
        updateTimeLabel(duration: audioDuration, currentTime: audioDuration / 100 * getTimePercentage())
    }
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        self.configureRow(messageRow: messageRow, contact: contact, chat: chat)
        self.audioData = nil
        
        messageRow.configureAudioPlayer()
        
        resetPlayer()
    }
    
    override func getBubbbleView() -> UIView? {
        return bubbleView
    }
    
    func getBubbleSize() -> CGSize {
        let isIncoming = messageRow?.transactionMessage.isIncoming() ?? false
        let bottomBoostedPadding = (messageRow?.isBoosted ?? false) ? Constants.kReactionsViewHeight : 0
        
        if isIncoming {
            return CGSize(width: CommonAudioTableViewCell.kAudioReceivedBubbleWidth, height: CommonAudioTableViewCell.kAudioBubbleHeight + bottomBoostedPadding)
        } else {
            return CGSize(width: CommonAudioTableViewCell.kAudioSentBubbleWidth, height: CommonAudioTableViewCell.kAudioBubbleHeight + bottomBoostedPadding)
        }
    }

    
    func loadAudio(url: URL, messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        toggleLoadingAudio(loading: true)

        MediaLoader.loadAudio(url: url, message: messageRow.transactionMessage, completion: { (messageId, data) in
            if self.isDifferentRow(messageId: messageId) { return }
            self.audioData = data
            self.audioReady()
        }, errorCompletion: { messageId in
            if self.isDifferentRow(messageId: messageId) { return }
            self.audioLoadingFailed()
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
        if let audioPlayerHelper = messageRow?.audioHelper, audioPlayerHelper.currentTime > 0 {
            updateControls(buttonTitle: "play_arrow", color: CommonAudioTableViewCell.kBlueControlsColor, dotVisible: true)
            updateCurrentTime(duration: getAudioDuration(), currentTime: Double(audioPlayerHelper.currentTime), animated: false)
        } else {
            updateControls(buttonTitle: "play_arrow", color: CommonAudioTableViewCell.kGrayControlsColor, dotVisible: false)
            updateTimeLabel(duration: getAudioDuration(), currentTime: 0.0)
        }
    }
    
    func getAudioDuration() -> Double {
        if let audioPlayerHelper = messageRow?.audioHelper {
            if let data = self.audioData, let audioDuration = audioPlayerHelper.getAudioDuration(data: data) {
                self.audioDuration = audioDuration
            } else if let data = self.messageRow?.transactionMessage.uploadingObject?.getDecryptedData(), let audioDuration = audioPlayerHelper.getAudioDuration(data: data) {
                self.audioDuration = audioDuration
            }
        }
        return self.audioDuration
    }
    
    func audioLoadingFailed() {
        dotGestureHandler.isUserInteractionEnabled = false
        playButton.isEnabled = false
        toggleLoadingAudio(loading: false)
    }
    
    func configureLockSign() {
        let encrypted = (messageRow?.transactionMessage.encrypted ?? false) && (messageRow?.transactionMessage.hasMediaKey() ?? false)
        lockSign.textColor = UIColor.Sphinx.WashedOutReceivedText
        lockSign.text = encrypted ? "lock" : ""
    }
    
    @IBAction func playButtonTouched() {
        if let data = audioData, let messageId = self.messageRow?.transactionMessage.id, let audioPlayerHelper = messageRow?.audioHelper {
            audioDelegate?.shouldStopPlayingAudios(cell: self)
            
            updateControls(buttonTitle: "pause", color: CommonAudioTableViewCell.kBlueControlsColor, dotVisible: true)
         
            setAudioPlayerInitialTime(messageId: messageId, data: data)
            audioPlayerHelper.playAudioFrom(data: data, messageId: messageId, progressCallback: updateCurrentTime, endCallback: audioDidFinishPlaying, pauseCallback: audioDidPausePlaying)
        }
    }
    
    func setAudioPlayerInitialTime(messageId: Int, data: Data) {
        if let audioPlayerHelper = messageRow?.audioHelper {
            audioPlayerHelper.setInitialTime(messageId: messageId, data: data, startTimePercentage: getTimePercentage())
        }
    }
    
    func getTimePercentage() -> Double {
        let totalWidth = CGFloat(audioTrackLine.frame.size.width) - CGFloat(currentTimeDot.frame.size.width)
        let startTimePercentage = currentTimeDotLeftConstraint.constant * 100 / totalWidth
        return Double(startTimePercentage)
    }
    
    func audioDidPausePlaying() {
        updateControls(buttonTitle: "play_arrow", color: CommonAudioTableViewCell.kBlueControlsColor, dotVisible: true)
    }
    
    func audioDidFinishPlaying() {
        DelayPerformedHelper.performAfterDelay(seconds: 0.2, completion: {
            self.resetPlayer()
        })
    }
    
    func stopPlaying() {
        if let audioPlayerHelper = messageRow?.audioHelper {
            audioPlayerHelper.stopPlaying()
            
            if audioPlayerHelper.currentTime > 0 {
                updateControls(buttonTitle: "play_arrow", color: CommonAudioTableViewCell.kBlueControlsColor, dotVisible: true)
            }
        }
    }
    
    func resetPlayer() {
        updateControls(buttonTitle: "play_arrow", color: CommonAudioTableViewCell.kGrayControlsColor, dotVisible: false)
        updateTimeLabel(duration: getAudioDuration(), currentTime: 0.0)
        currentTimeDotLeftConstraint.constant = 0
        currentTimeDot.superview?.layoutIfNeeded()
    }
    
    func updateCurrentTime(duration: Double, currentTime: Double) {
        updateCurrentTime(duration: duration, currentTime: currentTime, animated: true)
    }
    
    func updateCurrentTime(duration: Double, currentTime: Double, animated: Bool) {
        let totalWidth = CGFloat(audioTrackLine.frame.size.width) - CGFloat(currentTimeDot.frame.size.width)
        let expectedWith = (CGFloat(currentTime) * totalWidth) / CGFloat(duration)
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
        let current:Int = Int(duration - currentTime)
        let minutes:Int = current / 60
        let seconds:Int = current % 60
        durationLabel.text = "\(minutes):\(seconds.timeString)"
    }
    
    func updateControls(buttonTitle: String, color: UIColor, dotVisible: Bool) {
        currentTimeDot.alpha = dotVisible ? 1.0 : 0.0
        playButton.setTitleColor(color, for: .normal)
        playButton.setTitle(buttonTitle, for: .normal)
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let replyTopPading = CommonChatTableViewCell.getReplyTopPadding(message: messageRow.transactionMessage)
        let boostBottomPadding = messageRow.isBoosted ? Constants.kReactionsViewHeight : 0
        return kAudioBubbleHeight + CommonChatTableViewCell.kBubbleTopMargin + CommonChatTableViewCell.kBubbleBottomMargin + replyTopPading + boostBottomPadding
    }
}
