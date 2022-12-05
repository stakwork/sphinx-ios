//
//  RecommendationItemCollectionViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/12/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

class RecommendationItemCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var typeIconImageView: UIImageView!
    @IBOutlet weak var itemTitleLabel: UILabel!
    @IBOutlet weak var itemDescriptionLabel: UILabel!
    @IBOutlet weak var separatorLine: UIView!
    
    var recommendation: RecommendationResult! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithVideoEpisode()
            }
        }
    }

}

// MARK: - Static Properties
extension RecommendationItemCollectionViewCell {
    
    static let reuseID = "RecommendationItemCollectionViewCell"
    
    static let nib: UINib = .init(
        nibName: "RecommendationItemCollectionViewCell",
        bundle: nil
    )
}

// MARK: - Lifecycle
extension RecommendationItemCollectionViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        itemImageView.layer.cornerRadius = 4.0
        itemImageView.clipsToBounds = true
        
        typeIconImageView.layer.cornerRadius = 2.0
        typeIconImageView.clipsToBounds = true
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
 

// MARK: - Public Methods
extension RecommendationItemCollectionViewCell {
    
    func configure(withRecommendation recommendation: RecommendationResult) {
        self.recommendation = recommendation
    }
}


// MARK: - Private Helpers
extension RecommendationItemCollectionViewCell {
    
    private func updateViewsWithVideoEpisode() {
        itemImageView.sd_cancelCurrentImageLoad()
        
        if let imageURLString = recommendation.imageURLPath, let url = URL(string: imageURLString) {
            itemImageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: recommendation.placeholderImageName ?? "podcastPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            itemImageView.image = UIImage(named: recommendation.placeholderImageName ?? "podcastPlaceholder")
        }

        if let typeIcon = recommendation.typeIconImage {
            typeIconImageView.image = UIImage(named: typeIcon)
            typeIconImageView.isHidden = false
        } else {
            typeIconImageView.isHidden = true
        }

        itemTitleLabel.text = recommendation.title
        itemDescriptionLabel.text = recommendation.subtitle
    }
}
