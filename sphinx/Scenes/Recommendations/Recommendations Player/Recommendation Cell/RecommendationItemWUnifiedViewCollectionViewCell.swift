//
//  RecommendationItemWUnifiedViewCollectionViewCell.swift
//  sphinx
//
//  Created by James Carucci on 3/6/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class RecommendationItemWUnifiedViewCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var unifiedEpisodeView: UnifiedEpisodeView!
    weak var delegate : PodcastEpisodeRowDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(withItem item: PodcastEpisode) {
        if let feed = item.feed,
         let delegate = delegate{
            unifiedEpisodeView.configureWith(podcast: feed, and: item, download: nil, delegate: delegate, isLastRow: false, playing: false)
        }
    }
}

// MARK: - Static Properties
extension RecommendationItemWUnifiedViewCollectionViewCell {
    
    static let reuseID = "RecommendationItemWUnifiedViewCollectionViewCell"
    
    static let nib: UINib = .init(
        nibName: "RecommendationItemWUnifiedViewCollectionViewCell",
        bundle: nil
    )
}
