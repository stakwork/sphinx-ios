//
//  FeedItemDetailHeaderCell.swift
//  sphinx
//
//  Created by James Carucci on 3/2/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class FeedItemDetailHeaderCell: UITableViewCell {
    
    
    @IBOutlet weak var feedItemImageView: UIImageView!
    @IBOutlet weak var feedNameLabel: UILabel!
    @IBOutlet weak var feedSubtitleLabel: UILabel!
    @IBOutlet weak var sourceTypeImageView: UIImageView!
    @IBOutlet weak var sourceTypeNameLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dotView1: UIView!
    @IBOutlet weak var dotView2: UIView!
    
    static let reuseID = "FeedItemDetailHeaderCell"
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        feedItemImageView.layer.cornerRadius = 10.0
        sourceTypeImageView.layer.cornerRadius = 3.0
        dotView1.makeCircular()
        dotView2.makeCircular()
    }
    
    func configureView(
        episode: PodcastEpisode
    ){
        feedNameLabel.text = episode.feed?.title
        feedSubtitleLabel.text = episode.title
        feedItemImageView.sd_setImage(with: URL(string: episode.imageToShow ?? ""))
        dateLabel.text = episode.dateString
        
        let duration = episode.duration ?? 0
        let currentTime = episode.currentTime ?? 0
        
        let timeString = (duration - currentTime).getEpisodeTimeString(
            isOnProgress: currentTime > 0
        )
        
        dotView2.isHidden = false
        timeRemainingLabel.text = timeString
        
        if let typeIconImage = episode.typeIconImage {
            sourceTypeImageView.image = UIImage(named: typeIconImage)
            sourceTypeNameLabel.text = episode.typeLabel
        }
    }
    
    func configureView(video: Video){
        feedNameLabel.text = video.videoFeed?.title
        feedSubtitleLabel.text = video.title
        feedItemImageView.sd_setImage(with: video.thumbnailURL)
        dateLabel.text = video.publishDateText
        
        timeRemainingLabel.text = ""
        dotView2.isHidden = true
        timeRemainingLabel.isHidden = true
        
        if let _ = video.videoID.range(of: "yt:") {
            sourceTypeImageView.image = UIImage(named: "youtubeVideoTypeIcon")
            sourceTypeNameLabel.text = "YouTube"
        }
    }
    
}
