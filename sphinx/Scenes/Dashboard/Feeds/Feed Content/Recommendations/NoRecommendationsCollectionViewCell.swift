//
//  NoRecommendationsCollectionViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/12/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

class NoRecommendationsCollectionViewCell: UICollectionViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
    }

}

extension NoRecommendationsCollectionViewCell {
    static let reuseID = "NoRecommendationsCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "NoRecommendationsCollectionViewCell", bundle: nil)
    }()
}
