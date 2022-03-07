//
//  PodcastPlayerView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import AVFoundation

protocol PodcastPlayerViewDelegate: AnyObject {
    func didTapSubscriptionToggleButton()
    func shouldReloadEpisodesTable()
    func shouldShareClip(comment: PodcastComment)
    func shouldSyncPodcast()
    func shouldShowSpeedPicker()
}

class PodcastPlayerView: UIView {
    
    weak var delegate: PodcastPlayerViewDelegate?
    weak var boostDelegate: CustomBoostDelegate?
    
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
    @IBOutlet weak var customBoostView: CustomBoostView!
    @IBOutlet weak var shareClipButton: UIButton!
    
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
    
    let feedBoostHelper = FeedBoostHelper()
    var playerHelper: PodcastPlayerHelper = PodcastPlayerHelper.sharedInstance
    
    var podcast: PodcastFeed! = nil
    
    var chat: Chat? {
        get {
            return podcast?.chat
        }
    }
    
    public enum ControlButtons: Int {
        case PlayerSpeed
        case ShareClip
        case Replay15
        case PlayPause
        case Forward30
    }
    
    convenience init(
        podcast: PodcastFeed,
        delegate: PodcastPlayerViewDelegate,
        boostDelegate: CustomBoostDelegate,
        fromDashboard: Bool
    ) {
        let windowWidth = WindowsManager.getWindowWidth()
        let frame = CGRect(x: 0, y: 0, width: windowWidth, height: windowWidth + PodcastPlayerView.kPlayerHeight)
        
        self.init(frame: frame)
        
        self.delegate = delegate
        self.boostDelegate = boostDelegate
        self.podcast = podcast
        
        self.playerHelper.addDelegate(
            self,
            withKey: PodcastPlayerHelper.DelegateKeys.podcastPlayerVC.rawValue
        )
        
        feedBoostHelper.configure(with: podcast.objectID, and: chat)
        
        setupView()
        setupActions(fromDashboard)
    }
    
    private var subscriptionToggleButtonTitle: String {
        podcast.isSubscribedToFromSearch ?
        "unsubscribe.upper".localized
        : "subscribe.upper".localized
    }

    private func setupView() {
        Bundle.main.loadNibNamed("PodcastPlayerView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        let windowInset = getWindowInsets()
        imageViewTop.constant = -windowInset.top
        imageHeight.constant = windowInset.top
        episodeImageView.layoutIfNeeded()
        
        playPauseButton.layer.cornerRadius = playPauseButton.frame.size.height / 2
        currentTimeDot.layer.cornerRadius = currentTimeDot.frame.size.height / 2
        subscriptionToggleButton.layer.cornerRadius = subscriptionToggleButton.frame.size.height / 2
        
        subscriptionToggleButton.setTitle(
            subscriptionToggleButtonTitle,
            for: .normal
        )
        
        subscriptionToggleButton.isHidden = chat != nil
        
        showInfo()
        configureControls()
        addDotGesture()
    }
    
    func setupActions(_ fromDashboard: Bool) {
        customBoostView.delegate = self
        
        if podcast.destinationsArray.count == 0 {
            customBoostView.alpha = 0.3
            customBoostView.isUserInteractionEnabled = false
        }
        
        if chat == nil || fromDashboard {
            shareClipButton.alpha = 0.3
            shareClipButton.isUserInteractionEnabled = false
        }
    }
    
    func showInfo() {
        audioLoading = true
        
        if let imageURL = podcast?.getImageURL() {
            loadImage(imageURL: imageURL)
        }

        episodeLabel.text = podcast.getCurrentEpisode()?.title ?? ""
        
        loadTime()
        loadMessages()
    }
    
    func loadTime() {
        let episode = podcast.getCurrentEpisode()
        
        if let duration = episode?.duration {
            setProgress(
                duration: duration,
                currentTime: podcast.currentTime
            )
            audioLoading = false
        } else if let url = episode?.getAudioUrl() {
            let asset = AVAsset(url: url)
            asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                let duration = Double(asset.duration.value) / Double(asset.duration.timescale)
                
                DispatchQueue.main.async {
                    self.setProgress(
                        duration: Int(duration),
                        currentTime: self.podcast.currentTime
                    )
                    self.audioLoading = false
                }
            })
        }
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
        
        let episodeId = Int(playerHelper.getCurrentEpisode()?.itemID ?? "") ?? -1
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
    
    func configureControls(
        forcePlaying: Bool? = nil
    ) {
        let isPlaying = forcePlaying ?? playerHelper.isPlaying(podcast.feedID)
        playPauseButton.setTitle(isPlaying ? "pause" : "play_arrow", for: .normal)
        speedButton.setTitle(playerHelper.playerSpeed.speedDescription + "x", for: .normal)
    }
    
    func setProgress(duration: Int, currentTime: Int) {
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
        if !playerHelper.isPlaying(podcast.feedID) {
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
            
            playerHelper.seek(podcast, to: Double(progress), playAfterSeek: wasPlayingOnDrag)
            wasPlayingOnDrag = false
            
            delegate?.shouldSyncPodcast()
        }
    }
    
    func gestureDidBegin(gestureXLocation: CGFloat) {
        wasPlayingOnDrag = playerHelper.isPlaying(podcast.feedID)
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
        playerHelper.shouldUpdateTimeLabels(progress: Double(progress), podcastId: podcast.feedID)
    }
    
    func togglePlayState() {
        playerHelper.togglePlayStateFor(podcast)
        delegate?.shouldReloadEpisodesTable()
    }
    
    @IBAction func subscriptionToggleButtonTouched() {
        delegate?.didTapSubscriptionToggleButton()
        
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
            let comment = podcast.getPodcastComment()
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
        playerHelper.seek(podcast, to: seconds)
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
    
    func playingState(podcastId: String, duration: Int, currentTime: Int) {
        guard podcastId == podcast.feedID else {
            return
        }
        audioLoading = false
        setProgress(duration: duration, currentTime: currentTime)
        configureControls()
    }
    
    func pausedState(podcastId: String, duration: Int, currentTime: Int) {
        guard podcastId == podcast.feedID else {
            return
        }
        audioLoading = false
        setProgress(duration: duration, currentTime: currentTime)
        configureControls()
    }
    
    func loadingState(podcastId: String, loading: Bool) {
        guard podcastId == podcast.feedID else {
            return
        }
        configureControls(forcePlaying: loading)
        showInfo()
        delegate?.shouldReloadEpisodesTable()
        audioLoading = loading
    }
}

extension PodcastPlayerView: CustomBoostViewDelegate {
    func didTouchBoostButton(withAmount amount: Int) {
        let itemID = playerHelper.getCurrentEpisode()?.itemID ?? "-1"
        let currentTime = playerHelper.currentTime
        
        if let boostMessage = feedBoostHelper.getBoostMessage(itemID: itemID, amount: amount, currentTime: currentTime) {
            
            let podcastAnimationVC = PodcastAnimationViewController.instantiate(amount: amount)
            WindowsManager.sharedInstance.showConveringWindowWith(rootVC: podcastAnimationVC)
            podcastAnimationVC.showBoostAnimation()
            
            feedBoostHelper.processPayment(itemID: itemID, amount: amount, currentTime: currentTime)
            feedBoostHelper.sendBoostMessage(message: boostMessage, completion: { (message, success) in
                self.boostDelegate?.didSendBoostMessage(success: success, message: message)
            })
        }
    }
}
