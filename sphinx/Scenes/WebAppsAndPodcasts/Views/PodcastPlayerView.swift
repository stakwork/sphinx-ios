//
//  PodcastPlayerView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol PodcastPlayerViewDelegate: AnyObject {
    func didTapDismissButton()
    func didTapSubscriptionToggleButton()
    func shouldReloadEpisodesTable()
    func shouldShareClip(comment: PodcastComment)
    func shouldSendBoost(message: String, amount: Int, animation: Bool) -> TransactionMessage?
    func shouldSyncPodcast()
    func shouldShowSpeedPicker()
}


class PodcastPlayerView: UIView {
    weak var delegate: PodcastPlayerViewDelegate?
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var imageViewTop: NSLayoutConstraint!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    
    @IBOutlet weak var episodeImageView: UIImageView!
    @IBOutlet weak var episodeLabel: UILabel!
    @IBOutlet weak var liveTableView: UITableView!
    
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var durationLine: UIView!
    @IBOutlet weak var progressLine: UIView!
    @IBOutlet weak var progressLineWidth: NSLayoutConstraint!
    @IBOutlet weak var speedButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var subscriptionToggleButton: UIButton!
    @IBOutlet weak var currentTimeDot: UIView!
    @IBOutlet weak var gestureHandlerView: UIView!
    @IBOutlet weak var boostButtonView: BoostButtonView!
    @IBOutlet weak var subscriptionButton: UIButton!
    
    @IBOutlet weak var audioLoadingWheel: UIActivityIndicatorView!
    
    static let kPlayerHeight: CGFloat = 256
    
    var livePodcastDataSource: PodcastLiveDataSource? = nil
    var liveMessages: [Int: [TransactionMessage]] = [:]

    var wasPlayingOnDrag = false
    
    var audioLoading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: audioLoading, loadingWheel: audioLoadingWheel, loadingWheelColor: UIColor.Sphinx.Text)
        }
    }
    
    var playerHelper: PodcastPlayerHelper! = nil
    var chat: Chat?
    
    public enum ControlButtons: Int {
        case PlayerSpeed
        case ShareClip
        case Replay15
        case PlayPause
        case Forward30
    }
    
    convenience init(
        playerHelper: PodcastPlayerHelper,
        chat: Chat?,
        delegate: PodcastPlayerViewDelegate
    ) {
        let windowWidth = WindowsManager.getWindowWidth()
        let frame = CGRect(x: 0, y: 0, width: windowWidth, height: windowWidth + PodcastPlayerView.kPlayerHeight)
        
        self.init(frame: frame)
        
        self.delegate = delegate
        self.playerHelper = playerHelper
        self.chat = chat
        self.playerHelper.delegate = self
        
        setup()
    }
    
    private var subscriptionToggleButtonTitle: String {
        (playerHelper.podcast?.isSubscribedFromPodcastIndex ?? false) ?
        "unsubscribe.upper".localized
        : "subscribe.upper".localized
    }

    private func setup() {
        Bundle.main.loadNibNamed("PodcastPlayerView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        let windowInset = getWindowInsets()
        imageViewTop.constant = -windowInset.top
        imageHeight.constant = windowInset.top
        episodeImageView.layoutIfNeeded()
        
        boostButtonView.delegate = self
        
        playPauseButton.layer.cornerRadius = playPauseButton.frame.size.height / 2
        currentTimeDot.layer.cornerRadius = currentTimeDot.frame.size.height / 2
        subscriptionButton.layer.cornerRadius = subscriptionButton.frame.size.height / 2
        
        
        subscriptionToggleButton.setTitle(
            subscriptionToggleButtonTitle,
            for: .normal
        )
        
        subscriptionToggleButton.isHidden = chat != nil
        
        showInfo()
        configureControls()
        addDotGesture()
    }
    
    func showInfo() {
        let imageURL = playerHelper.getImageURL()
        loadImage(imageURL: imageURL)
        episodeLabel.text = playerHelper.getCurrentEpisode()?.title ?? ""
        
        loadMessages()
    }
    
    func loadImage(imageURL: URL?) {
        guard let imageURL = imageURL else {
            self.episodeImageView.image = UIImage(named: "profile_avatar")!
            return
        }
        
        MediaLoader.asyncLoadImage(imageView: episodeImageView, nsUrl: imageURL, placeHolderImage: nil, completion: { img in
            self.episodeImageView.image = img
        }, errorCompletion: { _ in
            self.episodeImageView.image = UIImage(named: "profile_avatar")!
        })
    }
    
    func loadMessages() {
        guard let chat = chat else { return }
        
        liveMessages = [:]
        
        let episodeId = playerHelper.getCurrentEpisode()?.id ?? -1
        let messages = TransactionMessage.getLiveMessagesFor(chat: chat, episodeId: Int(episodeId))
        
        for m in messages {
            addToLiveMessages(message: m)
        }
        
        if livePodcastDataSource == nil {
            livePodcastDataSource = PodcastLiveDataSource(tableView: liveTableView, chat: chat)
        }
        livePodcastDataSource?.resetData()
    }
    
    func addToLiveMessages(message: TransactionMessage) {
        if let ts = message.getTimeStamp() {
            var existingM = liveMessages[ts] ?? Array<TransactionMessage>()
            existingM.append(message)
            liveMessages[ts] = existingM
        }
    }
    
    func preparePlayer() {
        playerHelper.preparePlayer(completion: {
            self.onEpisodePlayed()
        })
    }
    
    func onEpisodePlayed() {
        playerHelper?.updateCurrentTime()
        configureControls()
    }
    
    func configureControls() {
        let isPlaying = playerHelper.isPlaying()
        playPauseButton.setTitle(isPlaying ? "pause" : "play_arrow", for: .normal)
        speedButton.setTitle(playerHelper.playerSpeed.speedDescription + "x", for: .normal)
    }
    
    func setLabels(duration: Int, currentTime: Int) {
        let (ctHours, ctMinutes, ctSeconds) = currentTime.getTimeElements()
        let (dHours, dMinutes, dSeconds) = duration.getTimeElements()
        currentTimeLabel.text = "\(ctHours):\(ctMinutes):\(ctSeconds)"
        durationLabel.text = "\(dHours):\(dMinutes):\(dSeconds)"
        
        let progress = (Double(currentTime) * 100 / Double(duration))/100
        let durationLineWidth = UIScreen.main.bounds.width - 64
        var progressWidth = durationLineWidth * CGFloat(progress)
        
        if !progressWidth.isFinite || progressWidth < 0 {
            progressWidth = 0
        }
        
        progressLineWidth.constant = progressWidth
        progressLine.layoutIfNeeded()
    }
    
    func addMessagesFor(ts: Int) {
        if !playerHelper.isPlaying() {
            return
        }
        
        if let liveM = liveMessages[ts] {
            livePodcastDataSource?.insert(messages: liveM)
        }
    }
    
    func addDotGesture() {
        let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(wasDragged))
        gestureHandlerView.addGestureRecognizer(dragGesture)
    }
    
    @objc func wasDragged(gestureRecognizer: UIPanGestureRecognizer) {
        let gestureXLocation = gestureRecognizer.location(in: durationLine).x
        
        if gestureRecognizer.state == .began {
            livePodcastDataSource?.resetData()
            gestureDidBegin(gestureXLocation: gestureXLocation)
        } else if gestureRecognizer.state == .changed {
            updateProgressLineAndLabel(gestureXLocation: gestureXLocation)
        } else if gestureRecognizer.state == .ended {
            let progress = ((progressLineWidth.constant * 100) / durationLine.frame.size.width) / 100
            playerHelper.seekTo(progress: Double(progress), play: wasPlayingOnDrag)
            wasPlayingOnDrag = false
            
            delegate?.shouldSyncPodcast()
        }
    }
    
    func gestureDidBegin(gestureXLocation: CGFloat) {
        wasPlayingOnDrag = playerHelper.isPlaying()
        playerHelper.shouldPause()
        updateProgressLineAndLabel(gestureXLocation: gestureXLocation)
    }
    
    func updateProgressLineAndLabel(gestureXLocation: CGFloat) {
        let totalProgressWidth = CGFloat(durationLine.frame.size.width)
        let translation = (gestureXLocation < 0) ? 0 : ((gestureXLocation > totalProgressWidth) ? totalProgressWidth : gestureXLocation)
        
        if !translation.isFinite || translation < 0 {
            return
        }
        
        progressLineWidth.constant = translation
        progressLine.layoutIfNeeded()
        
        let progress = ((progressLineWidth.constant * 100) / durationLine.frame.size.width) / 100
        playerHelper.shouldUpdateTimeLabels(progress: Double(progress))
    }
    
    func togglePlayState() {
        playerHelper.togglePlayState()
        configureControls()
        delegate?.shouldReloadEpisodesTable()
    }
    
    @IBAction func dismissButtonTouched() {
        delegate?.didTapDismissButton()
    }
    
    @IBAction func subscriptionToggleButtonTouched() {
        playerHelper.podcast?.isSubscribedFromPodcastIndex.toggle()
        
        subscriptionToggleButton.setTitle(
            subscriptionToggleButtonTitle,
            for: .normal
        )
    }
    
    @IBAction func controlButtonTouched(_ sender: UIButton) {
        switch(sender.tag) {
        case ControlButtons.PlayerSpeed.rawValue:
            delegate?.shouldShowSpeedPicker()
            break
        case ControlButtons.ShareClip.rawValue:
            let comment = playerHelper.getPodcastComment()
            delegate?.shouldShareClip(comment: comment)
            break
        case ControlButtons.Replay15.rawValue:
            seekTo(seconds: -15)
            break
        case ControlButtons.Forward30.rawValue:
            seekTo(seconds: 30)
            break
        case ControlButtons.PlayPause.rawValue:
            togglePlayState()
            break
        default:
            break
        }
    }
    
    func seekTo(seconds: Double) {
        livePodcastDataSource?.resetData()
        playerHelper.seekTo(seconds: seconds)
    }
}

extension PodcastPlayerView : PodcastPlayerDelegate {
    func didTapEpisodeAt(index: Int) {
        playerHelper.prepareEpisode(index: index, autoPlay: true, resetTime: true, completion: {
            self.configureControls()
            self.delegate?.shouldReloadEpisodesTable()
        })
        delegate?.shouldReloadEpisodesTable()
        showInfo()
    }
    
    func shouldUpdateLabels(duration: Int, currentTime: Int) {
        setLabels(duration: duration, currentTime: currentTime)
    }
    
    func shouldInsertMessagesFor(currentTime: Int) {
        addMessagesFor(ts: currentTime)
    }
    
    func shouldToggleLoadingWheel(loading: Bool) {
        audioLoading = loading
    }
    
    func shouldUpdatePlayButton() {
        configureControls()
    }
    
    func shouldUpdateEpisodeInfo() {
        showInfo()
        delegate?.shouldReloadEpisodesTable()
    }
}

extension PodcastPlayerView : BoostButtonViewDelegate {
    func didTouchButton() {
        let amount = UserContact.kTipAmount
        
        if let boostMessage = playerHelper.getBoostMessage(amount: amount) {
            playerHelper.processPayment(amount: amount)
            
            if let message = delegate?.shouldSendBoost(message: boostMessage, amount: amount, animation: false) {
                addToLiveMessages(message: message)
                livePodcastDataSource?.insert(messages: [message])
            }
        }
    }
}
