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

protocol PodcastEpisodeRowDelegate : class {
    func shouldStartDownloading(episode: PodcastEpisode, cell: UITableViewCell)
    func shouldStartDownloading(episode: PodcastEpisode, cell: UICollectionViewCell)
    func shouldDeleteFile(episode: PodcastEpisode, cell: UITableViewCell)
    func shouldDeleteFile(episode: PodcastEpisode, cell: UICollectionViewCell)
    func shouldShowMore(episode: PodcastEpisode,cell:UICollectionViewCell)
    func shouldShowMore(video:Video,cell:UICollectionViewCell)
    func shouldShowMore(episode: PodcastEpisode,cell:UITableViewCell)
    func shouldShare(episode: PodcastEpisode)
    func shouldShare(video:Video)
}

class UnifiedEpisodeView : UIView {
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var episodeLabel: UILabel!
    @IBOutlet weak var playArrow: UILabel!
    @IBOutlet weak var episodeImageView: UIImageView!
    @IBOutlet weak var divider: UIView!
    @IBOutlet weak var downloadButton: UIButton!
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
    @IBOutlet weak var downloadProgressBar: CircularProgressView!
    @IBOutlet weak var animationContainer: UIView!
    @IBOutlet weak var animationView: AnimationView!
    
    var episode: PodcastEpisode! = nil
    var videoEpisode: Video! = nil
    
    weak var delegate: PodcastEpisodeRowDelegate?
    
    weak var presentingTableViewCell : UITableViewCell?
    weak var presentingCollectionViewCell : UICollectionViewCell?
    
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
        
        dotView.makeCircular()
        playArrow.makeCircular()
        roundCorners()
    }
    
    func roundCorners(){
        mediaTypeImageView.layer.cornerRadius = 3.0
        episodeImageView.layer.cornerRadius = 6.0
        animationContainer.layer.cornerRadius = 6.0
        durationView.layer.cornerRadius = 3.0
        progressView.layer.cornerRadius = 3.0
    }
    
    func configure(withVideoEpisode videoEpisode: Video) {
        self.videoEpisode = videoEpisode
        
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
       playing: Bool
    ) {
        self.episode = episode
        self.delegate = delegate
        
        animationContainer.isHidden = !playing
        episodeLabel.textColor = !playing ? UIColor.Sphinx.Text : UIColor.Sphinx.BlueTextAccent
        progressView.backgroundColor = !playing ? UIColor.Sphinx.Text : UIColor.Sphinx.BlueTextAccent
        progressView.alpha = !playing ? 0.3 : 1.0
        playArrow.text = !playing ? "play_arrow" : "pause"
        
        episodeLabel.text = episode.title ?? "No title"
        descriptionLabel.text = episode.episodeDescription?.nonHtmlRawString ?? "No description"
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
        
        if let playedStatus = episode.wasPlayed, playedStatus == true {
            setAsPlayed()
        } else {
            let duration = episode.duration ?? 0
            let currentTime = episode.currentTime ?? 0
            
            let timeString = (duration - currentTime).getEpisodeTimeString(
                isOnProgress: currentTime > 0
            )
            
            timeRemainingLabel.text = timeString
            didPlayImageView.isHidden = true
        }

        setProgress()
        configureDownload(episode: episode, download: download)
        setImage(podcast: podcast, and: episode)
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
        
        if let valid_duration = episode.duration, let valid_time = episode.currentTime, valid_time > 0 {
            let percentage = Float(valid_time) / Float(valid_duration)
            let newProgressWidth = (percentage * Float(fullWidth))
            progressWidthConstraint.constant = CGFloat(newProgressWidth)
            
            durationView.isHidden = false
            progressView.isHidden = false
        }
    }
    
    //Networking:
    func configureDownload(episode: PodcastEpisode, download: Download?) {
        if episode.isDownloaded {
            downloadButton.setImage(UIImage(named: "playerListMark"), for: .normal)
            downloadButton.tintColor = UIColor.Sphinx.PrimaryGreen
        } else {
            downloadButton.setImage(UIImage(named: "playerListDownload"), for: .normal)
            downloadButton.tintColor = UIColor.Sphinx.SecondaryText
        }
        
        downloadButton.tintColorDidChange()
        
        if let download = download {
            updateProgress(progress: download.progress)
        } else {
            downloadProgressBar.progressAnimation(to: 0)
            downloadButton.isHidden = false
            downloadProgressBar.isHidden = true
        }
    }
    
    func updateProgress(progress: Int) {
        let progress = CGFloat(progress) / CGFloat(100)
        downloadButton.isHidden = true
        downloadProgressBar.isHidden = false
        downloadProgressBar.progressAnimation(to: progress)
    }
    
    @IBAction func downloadButtonTouched() {
        if let delegate = delegate,
           let presentingTableViewCell = presentingTableViewCell, !episode.isDownloaded {
            delegate.shouldStartDownloading(episode: episode, cell: presentingTableViewCell)
        }
    }
    
    @IBAction func shareButtonTouched(){
        if let video = videoEpisode{
            self.delegate?.shouldShare(video: video)
        }
        else{
            self.delegate?.shouldShare(episode: episode)
        }
    }
    
    @IBAction func moreButtonTouched(){
        if let delegate = delegate,let presentingTableViewCell = presentingTableViewCell {
            delegate.shouldShowMore(episode: episode, cell: presentingTableViewCell)
        } else if let delegate = delegate, let presentingCollectionViewCell = presentingCollectionViewCell {
            if let episode = episode {
                delegate.shouldShowMore(episode: episode, cell: presentingCollectionViewCell)
            } else if let video = videoEpisode {
                delegate.shouldShowMore(video: video, cell: presentingCollectionViewCell)
            }
        }
    }
    
}
