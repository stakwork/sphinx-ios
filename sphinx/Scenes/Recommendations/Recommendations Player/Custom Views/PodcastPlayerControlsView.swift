//
//  PodcastPlayerControlsView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/12/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

protocol RecommendationPlayerViewDelegate: AnyObject {
    func shouldShowSpeedPicker()
    func shouldSetProgress(duration: Int, currentTime: Int)
    func shouldReloadList()
}

class PodcastPlayerControlsView: UIView {
    
    weak var delegate: RecommendationPlayerViewDelegate?

    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var speedButton: UIButton!
    @IBOutlet weak var clipButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var skip15BackwardView: UIView!
    @IBOutlet weak var skip30ForwardView: UIView!
    @IBOutlet weak var boostView: CustomBoostView!
    
    let feedBoostHelper = FeedBoostHelper()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("PodcastPlayerControlsView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        playPauseButton.layer.cornerRadius = playPauseButton.frame.size.height / 2
    }
    
    public enum ControlButtons: Int {
        case PlayerSpeed
        case ShareClip
        case Replay15
        case PlayPause
        case Forward30
    }
    
    var podcastPlayerController = PodcastPlayerController.sharedInstance
    var podcast: PodcastFeed!
}

// MARK: - Actions handlers
extension PodcastPlayerControlsView {
    @IBAction func controlButtonTouched(_ sender: UIButton) {
        switch(sender.tag) {
        case ControlButtons.PlayerSpeed.rawValue:
            delegate?.shouldShowSpeedPicker()
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
        
        delegate?.shouldReloadList()
    }
    
    func seekTo(seconds: Double) {
        var newTime = (podcast?.currentTime ?? 0) + Int(seconds)
        newTime = max(newTime, 0)
        newTime = min(newTime, (podcast?.duration ?? 0))
        
        guard let podcastData = podcast.getPodcastData(
            currentTime: newTime
        ) else {
            return
        }
        
        delegate?.shouldSetProgress(
            duration: podcastData.duration ?? 0,
            currentTime: newTime
        )
        
        podcastPlayerController.submitAction(
            UserAction.Seek(podcastData)
        )
    }
}

// MARK: - Public methods
extension PodcastPlayerControlsView {
    
    func configure(
        podcast: PodcastFeed,
        andDelegate delegate: RecommendationPlayerViewDelegate?
    ) {
        self.delegate = delegate
        self.podcast = podcast
        
        if let item = podcast.getCurrentEpisode() {
            speedButton.isHidden = item.isYoutubeVideo
            clipButton.isHidden = item.isYoutubeVideo
            playPauseButton.isHidden = item.isYoutubeVideo
            skip15BackwardView.isHidden = item.isYoutubeVideo
            skip30ForwardView.isHidden = item.isYoutubeVideo
            
            let canBoost = (item.destination != nil)
            boostView.alpha = canBoost ? 1.0 : 0.5
            boostView.isUserInteractionEnabled = canBoost
        }
        
        clipButton.alpha = 0.5
        clipButton.isEnabled = false
    
        boostView.delegate = self
    }
    
    func configureControls(
        playing: Bool,
        speedDescription: String
    ) {
        playPauseButton.setTitle(playing ? "pause" : "play_arrow", for: .normal)
        speedButton.setTitle(speedDescription + "x", for: .normal)
    }
}


extension PodcastPlayerControlsView : CustomBoostViewDelegate{
    func didTouchBoostButton(withAmount amount: Int) {
        if let episode = podcast.getCurrentEpisode() {
            
            let itemID = episode.itemID
            let currentTime = podcast.getCurrentEpisode()?.currentTime ?? 0
                
            let podcastAnimationVC = PodcastAnimationViewController.instantiate(amount: amount)
            WindowsManager.sharedInstance.showConveringWindowWith(rootVC: podcastAnimationVC)
            podcastAnimationVC.showBoostAnimation()
                
            feedBoostHelper.sendBoostOnRecommendation(
                itemID: itemID,
                currentTime:currentTime,
                amount: amount
            )
        }
    }
    
    func didStartBoostAmountEdit() {}
}
