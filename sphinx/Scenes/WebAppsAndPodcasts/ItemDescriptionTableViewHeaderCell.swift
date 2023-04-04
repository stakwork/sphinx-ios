//
//  ItemDescriptionTableViewHeaderCell.swift
//  sphinx
//
//  Created by James Carucci on 4/4/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class ItemDescriptionTableViewHeaderCell: UITableViewCell {
    static let reuseID = "ItemDescriptionTableViewHeaderCell"
    
    @IBOutlet weak var podcastTitleLabel: UILabel!
    @IBOutlet weak var episodeTitleLabel: UILabel!
    @IBOutlet weak var playButton: UILabel!
    @IBOutlet weak var mediaTypeIcon: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dotView: UIView!
    @IBOutlet weak var timeRemaining: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func configureView(podcast:PodcastFeed,episode:PodcastEpisode){
        podcastTitleLabel.text = podcast.title
        episodeTitleLabel.text = episode.title
        playButton.makeCircular()
        dotView.makeCircular()
        mediaTypeIcon.layer.cornerRadius = 3.0
        dateLabel.text = episode.dateString
        
        let duration = episode.duration ?? 0
        let currentTime = episode.currentTime ?? 0
        
        let timeString = (duration - currentTime).getEpisodeTimeString(
            isOnProgress: currentTime > 0
        )
        timeRemaining.text = timeString
    }
    
    func configureView(videoFeed:VideoFeed,video:Video){
        
    }
    
}
