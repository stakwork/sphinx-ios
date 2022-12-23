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
    @IBOutlet weak var pauseAnimationView: AnimationView!
    
    let playerHelper: PodcastPlayerHelper = PodcastPlayerHelper.sharedInstance
    
    var wasPlayingOnDrag = false
    
    var podcast: PodcastFeed? = nil
    
    var audioLoading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: audioLoading, loadingWheel: audioLoadingWheel, loadingWheelColor: UIColor.Sphinx.Text)
        }
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("PodcastSmallPlayer", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        episodeLabel.fadeLength = 10
        
        runAnimation()
        
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
        and delegate: PodcastPlayerVCDelegate
    ) -> Bool {
        
        if self.podcast?.feedID == podcastId {
            return false
        }
        
        if let feed = ContentFeed.getFeedWith(feedId: podcastId) {
            self.podcast = PodcastFeed.convertFrom(contentFeed: feed)
            self.delegate = delegate
            
            return true
        } else if podcastId == RecommendationsHelper.kRecommendationPodcastId {
            self.podcast = playerHelper.recommendationsPodcast
            self.delegate = delegate
            
            return true
        }
        
        return false
    }
    
    func configureWith(
        podcast: PodcastFeed,
        and delegate: PodcastPlayerVCDelegate,
        completion: @escaping () -> ()
    ) {
        self.podcast = podcast
        self.delegate = delegate
        
        audioLoading = true
        
        showPodcastInfo(completion: {
            self.audioLoading = false
        })
        
        playerHelper.addDelegate(
            self,
            withKey: PodcastPlayerHelper.DelegateKeys.smallPlayer.rawValue
        )
        
        isHidden = false
        
        completion()
    }
    
    func runAnimation() {
        let pauseAnimation = Animation.named("pause_animation")
        pauseAnimationView.animation = pauseAnimation
        pauseAnimationView.loopMode = .autoReverse
    }
    
    func getViewHeight() -> CGFloat {
        return isHidden ? 0 : self.frame.height
    }

    func showPodcastInfo(
        completion: (() -> ())? = nil
    ) {
        showEpisodeInfo(completion: completion)
        configureControls()
    }
    
    func showEpisodeInfo(
        completion: (() -> ())? = nil
    ) {
        guard let podcast = podcast else {
            return
        }
        
        let episode = podcast.getCurrentEpisode()
        
        episodeLabel.text = episode?.title ?? "Episode with no title"
        contributorLabel.text = podcast.author ?? episode?.showTitle ?? podcast.title ?? ""
        
        if let imageUrlString = episode?.imageURLPath,
           let imageURL = URL(string: imageUrlString), !imageUrlString.isEmpty {
            
            episodeImageView.sd_setImage(
                with: imageURL,
                placeholderImage: UIImage(named: "podcastPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            episodeImageView.image = UIImage(named: "podcastPlaceholder")
        }
        
        if let duration = episode?.duration {
            let _ = setProgress(
                duration: duration,
                currentTime: podcast.currentTime
            )
            completion?()
        } else if let url = episode?.getAudioUrl() {
            let asset = AVAsset(url: url)
            asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                let duration = Int(Double(asset.duration.value) / Double(asset.duration.timescale))
                episode?.duration = duration
                
                DispatchQueue.main.async {
                    let _ = self.setProgress(
                        duration: duration,
                        currentTime: podcast.currentTime
                    )
                    completion?()
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
        
        let isPlaying = playing ?? playerHelper.isPlaying(podcast.feedID)
        
        playButton.isHidden = isPlaying
        pauseAnimationView.isHidden = !isPlaying
        
        episodeLabel.labelize = !isPlaying
        
        if isPlaying {
            pauseAnimationView.play()
        } else {
            pauseAnimationView.stop()
        }
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(PodcastSmallPlayer.playPauseButtonTouched))
        pauseAnimationView.addGestureRecognizer(gesture)
    }
    
    func setProgress(duration: Int, currentTime: Int) -> Bool {
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
            return true
        }
        return false
    }
    
    func togglePlayState() {
        if let podcast = podcast {
            playerHelper.togglePlayStateFor(podcast)
        }
    }
    
    func pauseIfPlaying() {
        playerHelper.shouldPause()
    }
    
    @IBAction func playPauseButtonTouched() {
        togglePlayState()
        configureControls()
    }
    
    @IBAction func forwardButtonTouched() {
        if let podcast = podcast {
            playerHelper.seek(podcast, to: 30)
        }
    }
    
    @IBAction func playerButtonTouched() {
        if let podcast = podcast {
            delegate?.shouldGoToPlayer(podcast: podcast)
        }
    }
}

extension PodcastSmallPlayer : PodcastPlayerDelegate {
    func playingState(podcastId: String, duration: Int, currentTime: Int) {
        guard podcastId == podcast?.feedID else {
            return
        }
        let didUpdateTime = setProgress(duration: duration, currentTime: currentTime)
        configureControls(playing: true)
        audioLoading = !didUpdateTime
    }
    
    func pausedState(podcastId: String, duration: Int, currentTime: Int) {
        guard podcastId == podcast?.feedID else {
            return
        }
        audioLoading = false
        let _ = setProgress(duration: duration, currentTime: currentTime)
        configureControls(playing: false)
    }
    
    func loadingState(podcastId: String, loading: Bool) {
        guard podcastId == podcast?.feedID else {
            return
        }
        configureControls(playing: loading)
        showEpisodeInfo()
        audioLoading = loading
    }
    
    func errorState(podcastId: String) {}
}
