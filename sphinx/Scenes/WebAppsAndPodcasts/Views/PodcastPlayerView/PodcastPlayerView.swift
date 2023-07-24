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
    func didFailPlayingPodcast()
    func shouldReloadEpisodesTable()
    func shouldShareClip(comment: PodcastComment)
    func shouldSyncPodcast()
    func shouldShowSpeedPicker()
}

class PodcastPlayerView: UIView {
    
    weak var delegate: PodcastPlayerViewDelegate?
    weak var boostDelegate: CustomBoostDelegate?
    
    @IBOutlet var contentView: UIView!
    
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
    @IBOutlet weak var satsPerMinuteView: PodcastSatsView!
    
    @IBOutlet weak var audioLoadingWheel: UIActivityIndicatorView!
    
    static let kPlayerHeight: CGFloat = 256
    
    var livePodcastDataSource: PodcastLiveDataSource? = nil
    var liveMessages: [Int: [TransactionMessage]] = [:]
    
    var audioLoading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: audioLoading, loadingWheel: audioLoadingWheel, loadingWheelColor: UIColor.Sphinx.Text, views: [playPauseButton])
        }
    }
    
    let feedBoostHelper = FeedBoostHelper()
    
    var podcastPlayerController = PodcastPlayerController.sharedInstance
    
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
        
        feedBoostHelper.configure(with: podcast.feedID, and: chat)
        
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
        
        playPauseButton.layer.cornerRadius = playPauseButton.frame.size.height / 2
        currentTimeDot.layer.cornerRadius = currentTimeDot.frame.size.height / 2
        subscriptionToggleButton.layer.cornerRadius = subscriptionToggleButton.frame.size.height / 2
        
        subscriptionToggleButton.setTitle(
            subscriptionToggleButtonTitle,
            for: .normal
        )
        
        subscriptionToggleButton.isHidden = chat != nil
        
        audioLoading = podcastPlayerController.isPlaying(podcastId: podcast.feedID)
        
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
        
        satsPerMinuteView.configureWith(podcast: podcast)
    }
    
    func addToLiveMessages(message: TransactionMessage) {
        if let ts = message.getTimeStamp() {
            var existingM = liveMessages[ts] ?? Array<TransactionMessage>()
            existingM.append(message)
            liveMessages[ts] = existingM
        }
    }
    
    func addDotGesture() {
        let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(wasDragged))
        gestureHandlerView.addGestureRecognizer(dragGesture)
    }
    
    var dragging = false
    @objc func wasDragged(gestureRecognizer: UIPanGestureRecognizer) {
        let gestureXLocation = gestureRecognizer.location(in: durationLine).x
        
        if gestureRecognizer.state == .began {
            dragging = true
            livePodcastDataSource?.resetData()
            gestureDidBegin(gestureXLocation: gestureXLocation)
        } else if gestureRecognizer.state == .changed {
            updateProgressLineAndLabel(gestureXLocation: gestureXLocation)
        } else if gestureRecognizer.state == .ended {
            dragging = false
            
            guard let episode = podcast.getCurrentEpisode(), let duration = episode.duration else {
                return
            }
            
            let progress = ((progressLineWidth.constant * 100) / durationLine.frame.size.width) / 100
            let currentTime = Int(Double(duration) * progress)
            
            guard let podcastData = podcast.getPodcastData(
                currentTime: currentTime
            ) else {
                return
            }
            
            podcastPlayerController.submitAction(
                UserAction.Seek(podcastData)
            )
            
            delegate?.shouldSyncPodcast()
        }
    }
    
    func gestureDidBegin(gestureXLocation: CGFloat) {
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
        
        guard let episode = podcast.getCurrentEpisode(), let duration = episode.duration else {
            return
        }
        
        let progress = ((progressLineWidth.constant * 100) / durationLine.frame.size.width) / 100
        let currentTime = Int(Double(duration) * progress)
        setProgress(duration: duration, currentTime: currentTime)
    }
    
    func togglePlayState() {
        guard let podcastData = podcast.getPodcastData() else {
            return
        }
        
        if podcastPlayerController.isPlaying(podcastId: podcastData.podcastId) {
            podcastPlayerController.submitAction(
                UserAction.Pause(podcastData)
            )
        } else {
            podcastPlayerController.submitAction(
                UserAction.Play(podcastData)
            )
        }
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
    
    func playEpisode(episode:PodcastEpisode){
        guard let podcastData = podcast.getPodcastData(
            episodeId: episode.itemID
        ) else {
            return
        }
        
        podcastPlayerController.submitAction(
            UserAction.TogglePlay(podcastData)
        )
        
        delegate?.shouldReloadEpisodesTable()
    }
    
    func didTapEpisodeWith(
        episodeId: String
    ) {
        guard let episode = podcast.getEpisodeWith(id: episodeId) else {
            return
        }
        audioLoading = true
        
        playEpisode(episode: episode)
    }
    
    func seekToFixedTime(seconds:Int){
        guard let podcastData = podcast.getPodcastData(
            currentTime: seconds
        ) else {
            return
        }
        
        setProgress(
            duration: podcastData.duration ?? 0,
            currentTime: seconds
        )
        
        podcastPlayerController.submitAction(
            UserAction.Seek(podcastData)
        )
    }
    
    func seekTo(seconds: Double) {
        livePodcastDataSource?.resetData()
        
        var newTime = podcast.currentTime + Int(seconds)
        newTime = max(newTime, 0)
        newTime = min(newTime, podcast.duration)
        
        guard let podcastData = podcast.getPodcastData(
            currentTime: newTime
        ) else {
            return
        }
        
        setProgress(
            duration: podcastData.duration ?? 0,
            currentTime: newTime
        )
        
        podcastPlayerController.submitAction(
            UserAction.Seek(podcastData)
        )
    }
}
