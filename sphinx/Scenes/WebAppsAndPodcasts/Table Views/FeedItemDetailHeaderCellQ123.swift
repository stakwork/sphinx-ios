//
//  FeedItemDetailHeaderCellQ123.swift
//  sphinx
//
//  Created by James Carucci on 3/2/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class FeedItemDetailHeaderCellQ123: UITableViewCell {
    
    
    @IBOutlet weak var feedItemImageView: UIImageView!
    @IBOutlet weak var feedNameLabel: UILabel!
    @IBOutlet weak var feedSubtitleLabel: UILabel!
    @IBOutlet weak var sourceTypeImageView: UIImageView!
    @IBOutlet weak var sourceTypeNameLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dotView1: UIView!
    @IBOutlet weak var dotView2: UIView!
    
    static let reuseID = "FeedItemDetailHeaderCellQ123"
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureView(episode:PodcastEpisode){
        dotView1.makeCircular()
        dotView2.makeCircular()
        
        feedNameLabel.text = episode.feed?.title
        feedSubtitleLabel.text = episode.title
        feedItemImageView.sd_setImage(with: URL(string: episode.imageToShow ?? ""))
        feedItemImageView.layer.cornerRadius = 10.0
        sourceTypeImageView.layer.cornerRadius = 3.0
        dateLabel.text = episode.dateString
        timeRemainingLabel.text = episode.getTimeString(type: .total)
        sourceTypeNameLabel.text = "Podcast"
    }
    
}
