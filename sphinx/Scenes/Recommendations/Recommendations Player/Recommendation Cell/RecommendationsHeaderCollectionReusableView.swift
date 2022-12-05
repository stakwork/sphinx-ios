//
//  RecommendationsHeaderCollectionReusableView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/12/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

class RecommendationsHeaderCollectionReusableView: UICollectionReusableView {
    
    @IBOutlet weak var countLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
}

// MARK: - Static Properties
extension RecommendationsHeaderCollectionReusableView {
    
    static let reuseID = "RecommendationsHeaderCollectionReusableView"
    
    static let nib: UINib = .init(
        nibName: "RecommendationsHeaderCollectionReusableView",
        bundle: nil
    )
}

// MARK: - Public RecommendationsHeaderCollectionReusableView
extension RecommendationsHeaderCollectionReusableView {
    
    func configure(withCount count: Int) {
        countLabel.text = String(count)
    }
}
