//
//  LoadingRecommendationsCollectionViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/12/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

class LoadingRecommendationsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        loadingWheel.color = UIColor.Sphinx.Text
        loadingWheel.startAnimating()
    }

    func startAnimating() {
        loadingWheel.startAnimating()
    }
}

extension LoadingRecommendationsCollectionViewCell {
    static let reuseID = "LoadingRecommendationsCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "LoadingRecommendationsCollectionViewCell", bundle: nil)
    }()
}
