//
//  UnifiedEpisodeView.swift
//  sphinx
//
//  Created by James Carucci on 3/6/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit
import Lottie

protocol FeedItemRowDelegate : class {
    func shouldStartDownloading(episode: PodcastEpisode, cell: UITableViewCell)
    func shouldDeleteFile(episode: PodcastEpisode, cell: UITableViewCell)
    func shouldShowMore(episode: PodcastEpisode, cell: UITableViewCell)
    func shouldShare(episode: PodcastEpisode)
    
    func shouldStartDownloading(episode: PodcastEpisode, cell: UICollectionViewCell)
    func shouldDeleteFile(episode: PodcastEpisode, cell: UICollectionViewCell)
    func shouldShowMore(episode: PodcastEpisode,cell: UICollectionViewCell)
    func shouldShowDescription(episode: PodcastEpisode,cell:UITableViewCell)
    
    func shouldShowMore(video:Video,cell: UICollectionViewCell)
    func shouldShare(video:Video)
    func shouldShowDescription(video: Video)
}

protocol PodcastEpisodeRowDelegate : class {
    func shouldStartDownloading(episode: PodcastEpisode)
    func shouldDeleteFile(episode: PodcastEpisode)
    func shouldShowMore(episode: PodcastEpisode)
    func shouldShare(episode: PodcastEpisode)
    func shouldShowDescription(episode:PodcastEpisode)
}

protocol VideoRowDelegate : class {
    func shouldShowMore(video: Video)
    func shouldShare(video: Video)
    func shouldShowDescription(video:Video)
    func shouldStartDownloading(video:Video)
}

class UnifiedEpisodeView : UIView {
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var episodeLabel: UILabel!
    @IBOutlet weak var playArrow: UILabel!
    @IBOutlet weak var episodeImageView: UIImageView!
    @IBOutlet weak var divider: UIView!
    @IBOutlet weak var sharebutton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var moreDetailsButton: UIButton!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var progressWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var durationWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var dotView: UIView!
    @IBOutlet weak var mediaTypeImageView: UIImageView!
    @IBOutlet weak var durationView: UIView!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var didPlayImageView: UIImageView!
    @IBOutlet weak var downloadButtonImage: UIImageView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var downloadProgressBar: CircularProgressView!
    @IBOutlet weak var animationContainer: UIView!
    @IBOutlet weak var animationView: AnimationView!
    
    
    var episode: PodcastEpisode! = nil
    var videoEpisode: Video! = nil
    
    weak var podcastDelegate: PodcastEpisodeRowDelegate?
    weak var videoDelegate: VideoRowDelegate?
    
    var thumbnailImageViewURL: URL? {
        videoEpisode.thumbnailURL
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("UnifiedEpisodeView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        durationView.alpha = 0.1
        
        roundCorners()
        configureAnimation()
        configureButtons()
    }
    
    func configureButtons() {
        downloadButton.tintColor = UIColor.Sphinx.Text.withAlphaComponent(0.5)
        sharebutton.tintColor = UIColor.Sphinx.Text.withAlphaComponent(0.5)
        moreDetailsButton.tintColor = UIColor.Sphinx.Text.withAlphaComponent(0.5)
    }
    
    func roundCorners(){
        dotView.makeCircular()
        playArrow.makeCircular()
        
        mediaTypeImageView.layer.cornerRadius = 3.0
        episodeImageView.layer.cornerRadius = 6.0
        animationContainer.layer.cornerRadius = 6.0
        durationView.layer.cornerRadius = 3.0
        progressView.layer.cornerRadius = 3.0
    }
    
    func configureAnimation() {
        let playingAnimation = Animation.named("playing_bar")
        animationView.animation = playingAnimation
        animationView.loopMode = .autoReverse
    }
    
    func configure(
        withVideoEpisode videoEpisode: Video,
        download: VideoDownload?,
        and delegate: VideoRowDelegate
    ) {
        self.videoEpisode = videoEpisode
        self.videoDelegate = delegate
        
        let id = videoEpisode.videoID
        
        if let _ = id.range(of: "yt:") {
            mediaTypeImageView.image = UIImage(named: "youtubeVideoTypeIcon")
        } else {
            mediaTypeImageView.isHidden = true
        }
        
        timeRemainingLabel.isHidden = true
        progressView.isHidden = true
        durationView.isHidden = true
        downloadProgressBar.isHidden = true
        didPlayImageView.isHidden = true
        dotView.isHidden = true
        
        downloadButton.alpha = 0.5
        downloadButton.isEnabled = false
        
        playArrow.isHidden = true
        
        episodeImageView.sd_cancelCurrentImageLoad()
        
        if let imageURL = thumbnailImageViewURL {
            episodeImageView.sd_setImage(
                with: imageURL,
                placeholderImage: UIImage(named: "videoPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            episodeImageView.image = UIImage(named: "videoPlaceholder")
        }
        
        downloadButton.isEnabled = true
        downloadButton.isHidden = false
        
        configureDownload(video: videoEpisode, download: download)

        
        descriptionLabel.text = videoEpisode.videoDescription
        episodeLabel.text = videoEpisode.titleForDisplay
        dateLabel.text = videoEpisode.publishDateText
    }
    
    func configureWith(
       podcast: PodcastFeed?,
       and episode: PodcastEpisode,
       download: Download?,
       delegate: PodcastEpisodeRowDelegate,
       isLastRow: Bool,
       playing: Bool,
       playingSound: Bool = false
    ) {
        self.episode = episode
        self.podcastDelegate = delegate
        
        configurePlayingAnimation(
            playing: playing,
            playingSound: playingSound
        )
        
        episodeLabel.textColor = !playing ? UIColor.Sphinx.Text : UIColor.Sphinx.ReceivedIcon
        progressView.backgroundColor = !playing ? UIColor.Sphinx.Text : UIColor.Sphinx.ReceivedIcon
        
        progressView.alpha = !playing ? 0.3 : 1.0
        playArrow.text = !playing ? "play_arrow" : "pause"
        playArrow.isHidden = false
        
        episodeLabel.text = episode.title ?? "No title"
        
        descriptionLabel.text = episode.episodeDescription?.nonHtmlRawString
        descriptionLabel.isHidden = (episode.episodeDescription?.nonHtmlRawString ?? "").isEmpty
        
        divider.isHidden = isLastRow
        
        if let typeIconImage = episode.typeIconImage {
            mediaTypeImageView.image = UIImage(named: typeIconImage)
        }
        
        if podcast?.isRecommendationsPodcast == true {
            downloadButton.isEnabled = false
            downloadButton.alpha = 0.5
        } else {
            downloadButton.isEnabled = true
            downloadButton.alpha = 1.0
        }
        
        dateLabel.text = episode.dateString
        
        if let playedStatus = episode.wasPlayed,
            playedStatus == true {
            setAsPlayed()
        } else {
            let duration = episode.duration ?? 0
            let currentTime = episode.currentTime ?? 0
            
            let timeString = (duration - currentTime).getEpisodeTimeString(isOnProgress: currentTime > 0)
            
            timeRemainingLabel.text = timeString
            dotView.isHidden = timeString.isEmpty
            didPlayImageView.isHidden = true
        }

        setProgress()
        configureDownload(episode: episode, download: download)
        setImage(podcast: podcast, and: episode)
        
        episodeImageView.isUserInteractionEnabled = true
        descriptionLabel.isUserInteractionEnabled = true
        
        if (episode.feed?.feedID == "Recommendations-Feed"){
            timeRemainingLabel.isHidden = episode.isYoutubeVideo
            didPlayImageView.isHidden = (didPlayImageView.isHidden || episode.isYoutubeVideo)
            dotView.isHidden = true
            downloadButtonImage.alpha = 0.25
        }
    }
    
    func configurePlayingAnimation(
        playing: Bool,
        playingSound: Bool
    ) {
        animationContainer.isHidden = !playing
        
        if playing && playingSound && !animationView.isAnimationPlaying {
            animationView.play()
        } else if (!playing || !playingSound) && animationView.isAnimationPlaying {
            animationView.stop()
        }
    }
    
    func setImage(
        podcast: PodcastFeed?,
        and episode: PodcastEpisode
    ) {
        episodeImageView.sd_cancelCurrentImageLoad()
        
        if let episodeURLPath = episode.imageURLPath, let url = URL(string: episodeURLPath) {
            episodeImageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "podcastPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else if let podcastURLPath = podcast?.imageURLPath, let url = URL(string: podcastURLPath) {
            episodeImageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "podcastPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        }
    }
    
    func setAsPlayed() {
        timeRemainingLabel.text = "played".localized
        didPlayImageView.isHidden = false
    }
    
    func setProgress() {
        let fullWidth = durationWidthConstraint.constant
        
        durationView.isHidden = true
        progressView.isHidden = true
        
        if let episode = episode,
            let valid_duration = episode.duration,
            let valid_time = episode.currentTime, valid_time > 0 {
            let percentage = max(Float(valid_time) / Float(valid_duration), Float(0.075))
            let newProgressWidth = (percentage * Float(fullWidth))
            DispatchQueue.main.async {
                self.progressWidthConstraint.constant = CGFloat(newProgressWidth)
                
                self.durationView.isHidden = false
                self.progressView.isHidden = false
            }
        }
    }
    
    //Networking:
    func configureDownload(episode: PodcastEpisode, download: Download?) {
        downloadButtonImage.isHidden = true
        downloadProgressBar.isHidden = true
        
        if episode.isDownloaded {
            downloadButtonImage.isHidden = false
            downloadButtonImage.image = UIImage(named: "playerListDownloaded")
            downloadButtonImage.tintColor = UIColor.Sphinx.ReceivedIcon
        } else if let download = download {
            downloadProgressBar.isHidden = false
            updateDownloadState(download)
        } else {
            downloadButtonImage.isHidden = false
            downloadButtonImage.image = UIImage(named: "playerListDownload")
            downloadButtonImage.tintColor = UIColor.Sphinx.Text.withAlphaComponent(0.5)
        }
        
        downloadButton.tintColorDidChange()
    }
    
    func configureDownload(video: Video, download: VideoDownload?) {
        downloadButtonImage.isHidden = true
        downloadProgressBar.isHidden = true
        
        if video.isDownloaded {
            downloadButtonImage.isHidden = false
            downloadButtonImage.image = UIImage(named: "playerListDownloaded")
            downloadButtonImage.tintColor = UIColor.Sphinx.ReceivedIcon
        } else if let download = download {
            downloadProgressBar.isHidden = false
            updateDownloadState(download)
        } else {
            downloadButtonImage.isHidden = false
            downloadButtonImage.image = UIImage(named: "playerListDownload")
            downloadButtonImage.tintColor = UIColor.Sphinx.Text.withAlphaComponent(0.5)
        }
        
        downloadButton.tintColorDidChange()
    }
    
    //End Networking
    
    func updateDownloadState(_ download: Download) {
        let progress = CGFloat(download.progress) / CGFloat(100)
        downloadProgressBar.progressAnimation(to: progress, active: download.isDownloading)
    }
    
    func updateDownloadState(_ download: VideoDownload) {
        let progress = CGFloat(download.progress) / CGFloat(100)
        downloadProgressBar.progressAnimation(to: progress, active: download.isDownloading)
    }
    
    @IBAction func shouldShowDescription(){
        if let delegate = podcastDelegate,
        let episode = episode {
            delegate.shouldShowDescription(episode: episode)
        } else if let delegate = videoDelegate, let video = videoEpisode{
            delegate.shouldShowDescription(video: video)
        }
    }
    
    @IBAction func downloadButtonTouched() {
        print("touched!")
        if let episode = episode,
           !episode.isDownloaded {
            downloadProgressBar.progressAnimation(to: 0, active: true)
            podcastDelegate?.shouldStartDownloading(episode: episode)
        }
        else if let video = videoEpisode,
                !video.isDownloaded,
            let vd = videoDelegate as? RecommendationItemWUnifiedViewCollectionViewCell{
            print("downloading video!")
            vd.shouldStartDownloading(video: video)
        }
    }
    
    @IBAction func shareButtonTouched(){
        if let video = videoEpisode {
            self.videoDelegate?.shouldShare(video: video)
        } else if let episode = episode {
            self.podcastDelegate?.shouldShare(episode: episode)
        }
    }
    
    @IBAction func moreButtonTouched(){
        if let video = videoEpisode {
            videoDelegate?.shouldShowMore(video: video)
        } else if let episode = episode {
            podcastDelegate?.shouldShowMore(episode: episode)
        }
    }
    
}
