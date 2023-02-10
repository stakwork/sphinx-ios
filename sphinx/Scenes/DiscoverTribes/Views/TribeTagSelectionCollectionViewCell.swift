//
//  TribeTagSelectionCollectionViewCell.swift
//  sphinx
//
//  Created by James Carucci on 1/16/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class TribeTagSelectionCollectionViewCell: UICollectionViewCell {
    
    let tagLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(tagLabel)
        tagLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let leftConstraint = contentView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: tagLabel.leadingAnchor)
        leftConstraint.constant = -16
        leftConstraint.isActive = true
        
        let rightConstraint = contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: tagLabel.trailingAnchor)
        rightConstraint.constant = 16
        rightConstraint.isActive = true
        
        contentView.layoutMarginsGuide.centerYAnchor.constraint(equalTo: tagLabel.centerYAnchor).isActive = true

    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configureWith(tag: String, selected: Bool) {
        layer.backgroundColor = selected ? UIColor.Sphinx.BodyInverted.cgColor : UIColor.clear.cgColor
        layer.borderColor = selected ? UIColor.clear.cgColor : UIColor.Sphinx.PlaceholderText.cgColor
        layer.borderWidth = selected ? 0.0 : 1.0
        
        tagLabel.textAlignment = .center
        tagLabel.numberOfLines = 1
        tagLabel.adjustsFontSizeToFitWidth = true
        tagLabel.font = UIFont(name: "Roboto", size: 14.0)
        tagLabel.text = tag
        tagLabel.textColor = selected ? UIColor.Sphinx.Body : UIColor.Sphinx.BodyInverted
        tagLabel.sizeToFit()
        
        layer.cornerRadius = 24.0
    }
}

// MARK: - Static Properties
extension TribeTagSelectionCollectionViewCell {
    static let reuseID = "TribeTagSelectionCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "TribeTagSelectionCollectionViewCell", bundle: nil)
    }()
}
