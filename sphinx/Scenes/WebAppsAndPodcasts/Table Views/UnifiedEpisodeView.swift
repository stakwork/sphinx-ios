//
//  UnifiedEpisodeView.swift
//  sphinx
//
//  Created by James Carucci on 3/6/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

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
    @IBOutlet weak var downloadProgressLabel: UILabel!
    @IBOutlet weak var didPlayImageView: UIImageView!
    
    var videoEpisode: Video! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithVideoEpisode()
            }
        }
    }
    
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
    }
    
    var episode: PodcastEpisode! = nil
    weak var delegate: PodcastEpisodeRowDelegate?
    weak var presentingTableViewCell : UITableViewCell?
    weak var presentingCollectionViewCell : UICollectionViewCell?
    
    
    func configure(withVideoEpisode videoEpisode: Video) {
        self.videoEpisode = videoEpisode
    }
    
    func configureWith(podcast: PodcastFeed?,
                       and episode: PodcastEpisode,
                       download: Download?,
                       delegate: PodcastEpisodeRowDelegate,
                       isLastRow: Bool,
                       playing: Bool) {
        
        self.episode = episode
        self.delegate = delegate
        
        episodeLabel.textColor = !playing ? UIColor.Sphinx.Text : UIColor.Sphinx.BlueTextAccent
        progressView.backgroundColor = !playing ? UIColor.Sphinx.Text : UIColor.Sphinx.BlueTextAccent
        progressView.alpha = !playing ? 0.3 : 1.0
        playArrow.text = !playing ? "play_arrow" : "pause"
        playArrow.makeCircular()
        
        episodeLabel.text = episode.title ?? "No title"
        descriptionLabel.text = episode.episodeDescription?.nonHtmlRawString ?? "No description"
        divider.isHidden = isLastRow
        
        dotView.makeCircular()
        
        if(episode.type == "youtube") {
            mediaTypeImageView.image = #imageLiteral(resourceName: "youtubeVideoTypeIcon")
            downloadButton.isHidden = true
        }
        else if let feed = episode.feed,
                feed.isRecommendationsPodcast{
            downloadButton.isHidden = true
        }
        else{
            mediaTypeImageView.image = #imageLiteral(resourceName: "podcastTypeIcon")
        }
        
        dateLabel.text = episode.dateString
        
        setProgress()
        
        if let playedStatus = episode.wasPlayed,
           playedStatus == true{
            setUIAsPlayed()
        }
        else if let valid_string = episode.getTimeString(type: .remaining){
            if valid_string == "Played"{
                setUIAsPlayed()
            }
            else{
                timeRemainingLabel.text = "\(valid_string) left"
                didPlayImageView.isHidden = true
            }
        }
        else{
            timeRemainingLabel.text = ""
            didPlayImageView.isHidden = true
        }
        
        configureDownload(episode: episode, download: download)
        
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
        
        roundCorners()
    }
    
    private func updateViewsWithVideoEpisode() {
        if let id = videoEpisode.videoID as? String,
           let _ = id.range(of: "yt:"){
            mediaTypeImageView.image = #imageLiteral(resourceName: "youtubeVideoTypeIcon")
        }
        else{
            mediaTypeImageView.isHidden = true
        }
        timeRemainingLabel.isHidden = true
        downloadButton.isHidden = true
        progressView.isHidden = true
        durationView.isHidden = true
        downloadProgressLabel.isHidden = true
        playArrow.makeCircular()
        
        episodeImageView.sd_cancelCurrentImageLoad()
        
        if let imageURL = thumbnailImageViewURL {
            episodeImageView.sd_setImage(
                with: imageURL,
                placeholderImage: UIImage(named: "videoPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            // 📝 TODO:  Use a video placeholder here
            episodeImageView.image = UIImage(named: "videoPlaceholder")
        }

        descriptionLabel.text = videoEpisode.videoDescription
        episodeLabel.text = videoEpisode.titleForDisplay
        dateLabel.text = videoEpisode.publishDateText
    }
    
    func setUIAsPlayed(){
        timeRemainingLabel.text = "Played"
        didPlayImageView.isHidden = false
        if episode.wasPlayed == false {episode.wasPlayed = true}
    }
    //UI Stuff
    func roundCorners(){
        mediaTypeImageView.layer.cornerRadius = 3.0
        episodeImageView.layer.cornerRadius = 6.0
        durationView.layer.cornerRadius = 3.0
        progressView.layer.cornerRadius = 3.0
        
    }
    
    func setProgress(){
        let fullWidth = durationWidthConstraint.constant
        if let feed = episode.feed,
           feed.isRecommendationsPodcast{
            durationView.isHidden = true
            progressView.isHidden = true
        }
        else if let valid_duration = episode.duration,
           let valid_time = episode.currentTime{
            let percentage = Float(valid_time) / Float(valid_duration)
            let newProgressWidth = (percentage * Float(fullWidth))
            progressWidthConstraint.constant = CGFloat(newProgressWidth)
        }
        else{
            durationView.isHidden = true
            progressView.isHidden = true
        }
        
        durationView.alpha = 0.1
    }
    
    //Networking:
    func configureDownload(episode: PodcastEpisode, download: Download?) {
        
        //contentView.alpha = episode.isAvailable ? 1.0 : 0.5

        //recognizer?.isEnabled = episode.isDownloaded
        
        downloadProgressLabel.text = ""

        if episode.isDownloaded {
            downloadButton.setTitle("download_done", for: .normal)
            downloadButton.setTitleColor(UIColor.Sphinx.PrimaryGreen, for: .normal)
        } else {
            downloadButton.setTitle("download", for: .normal)
            downloadButton.setTitleColor(UIColor.Sphinx.SecondaryText, for: .normal)
        }
        
        if let download = download {
            updateProgress(progress: download.progress)
        }
         
    }
    
    func updateProgress(progress: Int) {
        print(progress)
        downloadProgressLabel.text = (progress > 0) ? "\(progress)%" : ""
        downloadButton.setTitle((progress > 0) ? "" : "hourglass_top", for: .normal)
    }
    
    @IBAction func downloadButtonTouched() {
        if let delegate = delegate,
           let presentingTableViewCell = presentingTableViewCell{
            delegate.shouldStartDownloading(episode: episode, cell: presentingTableViewCell)
        }
    }
    
    @IBAction func shareButtonTouched(){
        if let video = videoEpisode{
            
        }
        else{
            self.delegate?.shouldShare(episode: episode)
        }
    }
    
    @IBAction func moreButtonTouched(){
        if let delegate = delegate,
           let presentingTableViewCell = presentingTableViewCell{
            delegate.shouldShowMore(episode: episode, cell: presentingTableViewCell)
        }
        else if let delegate = delegate,
                let presentingCollectionViewCell = presentingCollectionViewCell{
            delegate.shouldShowMore(episode: episode, cell: presentingCollectionViewCell)
        }
    }
    
}
