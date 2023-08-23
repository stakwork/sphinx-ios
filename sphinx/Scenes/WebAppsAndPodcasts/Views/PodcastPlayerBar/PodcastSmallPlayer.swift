//
//  PodcastSmallPlayer.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import Lottie
import AVKit
import MarqueeLabel

class PodcastSmallPlayer: UIView {
    
    weak var delegate: PodcastPlayerVCDelegate?
    weak var boostDelegate: CustomBoostDelegate?

    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var episodeImageView: UIImageView!
    @IBOutlet weak var episodeLabel: MarqueeLabel!
    @IBOutlet weak var contributorLabel: UILabel!
    @IBOutlet weak var durationLine: UIView!
    @IBOutlet weak var progressLine: UIView!
    @IBOutlet weak var progressLineWidth: NSLayoutConstraint!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var audioLoadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var pauseAnimationView: AnimationView!
    
    let podcastPlayerController = PodcastPlayerController.sharedInstance
    
    var podcast: PodcastFeed? = nil
    
    var audioLoading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: audioLoading, loadingWheel: audioLoadingWheel, loadingWheelColor: UIColor.Sphinx.Text, views: [playPauseButton])
        }
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("PodcastSmallPlayer", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        episodeLabel.fadeLength = 10
        
        runAnimation()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(PodcastSmallPlayer.playPauseButtonTouched))
        pauseAnimationView.addGestureRecognizer(gesture)
        
        isHidden = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func configureWith(
        podcastId: String,
        delegate: PodcastPlayerVCDelegate,
        andKey playerDelegateKey: String
    ) {
        if self.podcast?.feedID == podcastId {
            showEpisodeInfo()
            return
        }
        
        if let feed = ContentFeed.getFeedById(feedId: podcastId) {
            self.podcast = PodcastFeed.convertFrom(contentFeed: feed)
            self.delegate = delegate
        } else if podcastId == RecommendationsHelper.kRecommendationPodcastId {
            self.podcast = RecommendationsHelper.sharedInstance.recommendationsPodcast
            self.delegate = delegate
        }
        
        podcastPlayerController.addDelegate(
            self,
            withKey: playerDelegateKey
        )
        
        showEpisodeInfo()
        configureControls(playing: podcastPlayerController.isPlaying(podcastId: podcastId))
        
        isHidden = false
    }
    
    func runAnimation() {
        let darkMode = traitCollection.userInterfaceStyle == .dark
        let pauseAnimation = Animation.named(darkMode ? "pause_animation" : "pause_animation_light")
        pauseAnimationView.animation = pauseAnimation
        pauseAnimationView.loopMode = .autoReverse
    }
    
    func getViewHeight() -> CGFloat {
        return isHidden ? 0 : self.frame.height
    }
    
    func showEpisodeInfo() {
        guard let podcast = podcast else {
            return
        }
        
        let episode = podcast.getCurrentEpisode()
        
        if podcast.isRecommendationsPodcast {
            episodeLabel.text = episode?.episodeDescription ?? "Episode with no title"
            contributorLabel.text = episode?.title ?? ""
        } else {
            episodeLabel.text = episode?.title ?? "Episode with no title"
            contributorLabel.text = podcast.author ?? episode?.showTitle ?? podcast.title ?? ""
        }
        
        if let imageUrl = podcast.getImageURL() {
            
            episodeImageView.sd_setImage(
                with: imageUrl,
                placeholderImage: UIImage(named: "podcastPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            episodeImageView.image = UIImage(named: "podcastPlaceholder")
        }
        
        if let duration = episode?.duration {
            setProgress(
                duration: duration,
                currentTime: podcast.currentTime
            )
        } else if let url = episode?.getAudioUrl() {
            let asset = AVAsset(url: url)
            asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                let duration = Int(Double(asset.duration.value) / Double(asset.duration.timescale))
                episode?.duration = duration
                
                DispatchQueue.main.async {
                    self.setProgress(
                        duration: duration,
                        currentTime: podcast.currentTime
                    )
                }
            })
        }
    }
    
    func configureControls(
        playing: Bool? = nil
    ) {
        guard let podcast = podcast else {
            return
        }
        
        let isMusicEpisode = podcast.getCurrentEpisode()?.isMusicClip == true
        playButton.isEnabled = isMusicEpisode
        skipButton.isEnabled = isMusicEpisode
        
        let isPlaying = playing ?? podcastPlayerController.isPlaying(podcastId: podcast.feedID)
        
        playButton.isHidden = isPlaying
        pauseAnimationView.isHidden = !isPlaying
        
        episodeLabel.labelize = !isPlaying
        
        if isPlaying {
            if !pauseAnimationView.isAnimationPlaying {
                pauseAnimationView.play()
            }
        } else {
            if pauseAnimationView.isAnimationPlaying {
                pauseAnimationView.stop()
            }
        }
    }
    
    func setProgress(duration: Int, currentTime: Int) {
        let progressBarMargin:CGFloat = 32
        let durationLineWidth = UIScreen.main.bounds.width - progressBarMargin
        let progress = (Double(currentTime) * 100 / Double(duration))/100
        var progressWidth = durationLineWidth * CGFloat(progress)
        
        if !progressWidth.isFinite || progressWidth < 0 {
            progressWidth = 0
        }
        
        if (progressLineWidth.constant != progressWidth) {
            progressLineWidth.constant = progressWidth
            progressLine.layoutIfNeeded()
        }
    }
    
    func togglePlayState() {
        guard let podcastData = podcast?.getPodcastData() else {
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
    }
    
    func pauseIfPlaying() {
        guard let podcastData = podcast?.getPodcastData() else {
            return
        }
        
        if podcastPlayerController.isPlaying(podcastId: podcastData.podcastId) {
            podcastPlayerController.submitAction(
                UserAction.Pause(podcastData)
            )
        }
    }
    
    func seekTo(seconds: Double) {
        var newTime = (podcast?.currentTime ?? 0) + Int(seconds)
        newTime = max(newTime, 0)
        newTime = min(newTime, (podcast?.duration ?? 0))
        
        guard let podcastData = podcast?.getPodcastData(
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
    
    @IBAction func playPauseButtonTouched() {
        togglePlayState()
    }
    
    @IBAction func forwardButtonTouched() {
        seekTo(seconds: 30)
    }
    
    @IBAction func playerButtonTouched() {
        if let podcast = podcast {
            delegate?.shouldGoToPlayer(podcast: podcast)
        }
    }
}
