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
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureView(episode:PodcastEpisode){
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        dotView1.makeCircular()
        dotView2.makeCircular()
        
        feedNameLabel.text = episode.feed?.title
        feedSubtitleLabel.text = episode.title
        feedItemImageView.sd_setImage(with: URL(string: episode.imageToShow ?? ""))
        feedItemImageView.layer.cornerRadius = 10.0
        sourceTypeImageView.layer.cornerRadius = 3.0
        dateLabel.text = episode.dateString
        timeRemainingLabel.text = episode.getTimeString(type: .total)
        if episode.isYoutubeVideo{
            sourceTypeImageView.image = #imageLiteral(resourceName: "youtubeVideoTypeIcon")
            sourceTypeNameLabel.text = "YouTube"
        }
        else{
            sourceTypeImageView.image = #imageLiteral(resourceName: "podcastTypeIcon")
            sourceTypeNameLabel.text = "Podcast"
        }
    }
    
    func configureView(video:Video){
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        dotView1.makeCircular()
        dotView2.makeCircular()
        
        feedNameLabel.text = video.videoFeed?.title
        feedSubtitleLabel.text = video.title
        feedItemImageView.sd_setImage(with: video.thumbnailURL)
        feedItemImageView.layer.cornerRadius = 10.0
        sourceTypeImageView.layer.cornerRadius = 3.0
        dateLabel.text = video.publishDateText
        timeRemainingLabel.isHidden = true
        //timeRemainingLabel.text = episode.getTimeString(type: .total)
        if let id = video.videoID as? String,
           let _ = id.range(of: "yt:"){
            sourceTypeImageView.image = #imageLiteral(resourceName: "youtubeVideoTypeIcon")
            sourceTypeNameLabel.text = "YouTube"
        }
    }
    
}
