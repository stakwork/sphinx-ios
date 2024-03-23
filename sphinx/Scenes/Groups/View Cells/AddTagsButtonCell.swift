//
//  AddTagsButtonCell.swift
//  sphinx
//
//  Created by Oko-osi Korede on 22/03/2024.
//  Copyright © 2024 sphinx. All rights reserved.
//

import UIKit

class AddTagsButtonCell: UICollectionReusableView {
    static let reuseIdentifier = "AddTagsButtonCell"
    var plusImage: UIImageView!
    var titleLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        plusImage = UIImageView(image: UIImage(systemName: "plus"))
        titleLabel = UILabel()
        titleLabel.textAlignment = .left
        addSubview([titleLabel, plusImage])
        layoutCustomViews()
    }
    
    func layoutCustomViews() {
        layoutPlusImage()
        layoutTitleLabel()
    }
    
    func layoutPlusImage() {
        plusImage.anchor(top: topAnchor,
                         bottom: bottomAnchor,
                         leading: leadingAnchor,
                         bottomPadding: -25,
                         leadingPadding: 20,
                         width: 20)
        plusImage.tintColor = .Sphinx.SecondaryText
    }
    
    func layoutTitleLabel() {
        titleLabel.anchor(top: topAnchor,
                          trailing: trailingAnchor,
                          bottom: bottomAnchor,
                          leading: plusImage.trailingAnchor,
                          trailingPadding: -10,
                          bottomPadding: -20,
                          leadingPadding: 10)
        titleLabel.textColor = .Sphinx.SecondaryText
        titleLabel.font = UIFont(name: "Roboto", size: 14.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

