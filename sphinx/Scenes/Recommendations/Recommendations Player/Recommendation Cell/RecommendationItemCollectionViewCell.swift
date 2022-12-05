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
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
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
