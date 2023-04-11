//
//  ItemDescriptionTableViewHeaderCell.swift
//  sphinx
//
//  Created by James Carucci on 4/4/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol ItemDescriptionTableViewHeaderCellDelegate{
    func didTogglePausePlay()
    func itemShareTapped(episode:PodcastEpisode)
    func itemShareTapped(video:Video)
    func itemMoreTapped(episode:PodcastEpisode)
    func itemMoreTapped(video:Video)
    func itemDownloadTapped(episode:PodcastEpisode)
}

class ItemDescriptionTableViewHeaderCell: UITableViewCell {
    static let reuseID = "ItemDescriptionTableViewHeaderCell"
    
    @IBOutlet weak var podcastTitleLabel: UILabel!
    @IBOutlet weak var episodeTitleLabel: UILabel!
    @IBOutlet weak var playButton: UILabel!
    @IBOutlet weak var mediaTypeIcon: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dotView: UIView!
    @IBOutlet weak var timeRemaining: UILabel!
    @IBOutlet weak var playCheckmark: UIImageView!
    @IBOutlet weak var downloadButtonImage: UIImageView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var downloadProgressBar: CircularProgressView!
    
    func isRecommendationVideo() -> Bool {
        if let episode = episode,
           episode.isYoutubeVideo && episode.feed?.feedID == "Recommendations-Feed"{
            return true
        }
        return false
    }
    
    weak var episode:PodcastEpisode?=nil
    weak var video:Video? = nil
    
    var delegate:ItemDescriptionTableViewHeaderCellDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        playButton.makeCircular()
        dotView.makeCircular()
        mediaTypeIcon.layer.cornerRadius = 3.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureView(
        podcast: PodcastFeed,
        episode: PodcastEpisode,
        download: Download?
    ){
        self.episode = episode
        
        playButton.text = PodcastPlayerController.sharedInstance.isPlaying(episodeId: episode.itemID) ? "pause" : "play_arrow"
        podcastTitleLabel.text = podcast.title
        episodeTitleLabel.text = episode.title
        dateLabel.text = episode.dateString
        
        if self.isRecommendationVideo() {
            playCheckmark.isHidden = true
            mediaTypeIcon.image = #imageLiteral(resourceName: "youtubeVideoTypeIcon")
            dotView.isHidden = true
            timeRemaining.isHidden = true
            downloadButtonImage.alpha = 0.25
            downloadButton.isUserInteractionEnabled = false
        }
        else if podcast.isRecommendationsPodcast {
            downloadButton.isEnabled = false
            downloadButtonImage.alpha = 0.25
        } else {
            downloadButton.isEnabled = true
            downloadButtonImage.alpha = 1.0
        }
        
        let duration = episode.duration ?? 0
        let currentTime = episode.currentTime ?? 0
        
        let timeString = (duration - currentTime).getEpisodeTimeString(
            isOnProgress: currentTime > 0
        )
        
        let isPlayed = (self.episode?.wasPlayed ?? false)
        playCheckmark.isHidden = !isPlayed
        timeRemaining.text = isPlayed ? "played".localized : timeString
        
        configureDownload(episode: episode, download: download)
    }
    
    func configureView(
        videoFeed: VideoFeed,
        video: Video
    ){
        self.video = video
        
        downloadButtonImage.alpha = 0.25
        podcastTitleLabel.text = videoFeed.title
        episodeTitleLabel.text = video.title
        dotView.isHidden = true
        dateLabel.text = video.publishDateText
        playCheckmark.isHidden = true
        mediaTypeIcon.image = #imageLiteral(resourceName: "youtubeVideoTypeIcon")
        timeRemaining.isHidden = true
    }
    
    //Networking:
    func configureDownload(
        episode: PodcastEpisode,
        download: Download?
    ) {
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
    
    func updateDownloadState(_ download: Download) {
        let progress = CGFloat(download.progress) / CGFloat(100)
        downloadProgressBar.progressAnimation(to: progress, active: download.isDownloading)
    }
    
    @IBAction func shareButton(_ sender: Any) {
        if let episode = self.episode{
            delegate?.itemShareTapped(episode: episode)
        }
        else if let video = self.video{
            delegate?.itemShareTapped(video: video)
        }
    }
    @IBAction func showMoreTapped(_ sender: Any) {
        if let episode = self.episode{
            delegate?.itemMoreTapped(episode: episode)
        }
        else if let video = self.video{
            delegate?.itemMoreTapped(video: video)
        }
    }
    
    @IBAction func pausePlayTap(){
        self.delegate?.didTogglePausePlay()
    }
    
    @IBAction func downloadButtonTapped(_ sender: Any) {
        print("download tapped")
        if let episode = episode,
           !episode.isDownloaded{
            downloadProgressBar.progressAnimation(to: 0, active: true)
            delegate?.itemDownloadTapped(episode: episode)
        }
    }
    
    
}
