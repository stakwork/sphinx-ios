//
//  UnifiedEpisodeTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 2/28/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class UnifiedEpisodeTableViewCell: UITableViewCell {

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
    
    
    //TODO:
    //1. Make media type image dynamic -> x
    //2. Make select pause if the pod is already playing
    //3. Add download button
    //4. Add more button action + view
    //5. Add share button action
    
    var episode: PodcastEpisode! = nil
    weak var delegate: PodcastEpisodeRowDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
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
        playArrow.text = !playing ? "play_arrow" : "pause"
        playArrow.makeCircular()
        
        episodeLabel.text = episode.title ?? "No title"
        descriptionLabel.text = episode.episodeDescription?.nonHtmlRawString ?? "No description"
        divider.isHidden = isLastRow
        
        dotView.makeCircular()
        
        mediaTypeImageView.image = #imageLiteral(resourceName: "podcastTypeIcon")
        
        let date = episode.datePublished
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        if let valid_date = date{
            let dateString = formatter.string(from: valid_date)
            dateLabel.text = dateString
        }
        
        setProgress()
        
        if let valid_elapsed = episode.currentTime,
           let valid_duration = episode.duration{
            let remaining = valid_duration - valid_elapsed
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .abbreviated
            formatter.allowedUnits = (remaining > 3599) ? [.hour, .minute] : [.minute]
            formatter.zeroFormattingBehavior = .pad
            var components = DateComponents()
            components.second = remaining
            let remainingString = formatter.string(from: components)
            if let valid_string = remainingString{
                timeRemainingLabel.text = "\(valid_string) left"
            }
            else{
                timeRemainingLabel.text = ""
            }
        }
        
        //configureDownload(episode: episode, download: download)
        
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
    
    func roundCorners(){
        mediaTypeImageView.layer.cornerRadius = 3.0
        episodeImageView.layer.cornerRadius = 6.0
        durationView.layer.cornerRadius = 3.0
        progressView.layer.cornerRadius = 3.0
    }
    
    func setProgress(){
        let fullWidth = durationWidthConstraint.constant
        if let valid_duration = episode.duration,
           let valid_time = episode.currentTime{
            let percentage = Float(valid_time) / Float(valid_duration)
            let newProgressWidth = (percentage * Float(fullWidth))
            progressWidthConstraint.constant = CGFloat(newProgressWidth)
        }
        durationView.alpha = 0.1
    }
    
}
