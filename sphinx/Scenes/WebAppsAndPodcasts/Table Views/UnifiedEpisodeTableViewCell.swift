//
//  UnifiedEpisodeTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 2/28/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class UnifiedEpisodeTableViewCell: UITableViewCell {
    
    @IBOutlet weak var unifiedEpisodeView: UnifiedEpisodeView!

    
    
    
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
                       playing: Bool){
        unifiedEpisodeView.presentingTableViewCell = self
        unifiedEpisodeView.configureWith(podcast: podcast, and: episode, download: download, delegate: delegate, isLastRow: isLastRow, playing: playing)
    }
    
}
