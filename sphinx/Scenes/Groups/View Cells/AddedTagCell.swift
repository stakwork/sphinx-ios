//
//  AddedTagCell.swift
//  sphinx
//
//  Created by Oko-osi Korede on 22/03/2024.
//  Copyright © 2024 sphinx. All rights reserved.
//

import Foundation
import UIKit

class AddedTagCell: UIView {
    
    let tagLabel = UILabel()
    let cancelimageView = UIImageView(image: UIImage(systemName: "xmark"))
    
    let kNormalColor = UIColor.Sphinx.Body
    let kSelectedColor = UIColor.Sphinx.ReceivedMsgBG
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview([tagLabel, cancelimageView])
        layoutCustomViews()

    }
    
    func layoutCustomViews() {
        layoutTagLabel()
        layoutImageView()
        layer.backgroundColor = UIColor.Sphinx.BodyInverted.cgColor
    }
    
    func layoutTagLabel() {
        tagLabel.anchor(trailing: trailingAnchor, leading: leadingAnchor, trailingPadding: -30, leadingPadding: 10)
        tagLabel.center(in: self, axis: .vertical)
    }
    
    func layoutImageView() {
        cancelimageView.anchor(trailing: trailingAnchor, trailingPadding: -10, width: 10, height: 15)
        cancelimageView.center(in: self, axis: .vertical)
        cancelimageView.tintColor = .Sphinx.SecondaryText
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configureWith(tag: String) {
        tagLabel.textAlignment = .center
        tagLabel.numberOfLines = 1
        tagLabel.adjustsFontSizeToFitWidth = true
        tagLabel.font = UIFont(name: "Roboto", size: 14.0)
        tagLabel.text = tag
        tagLabel.textColor = UIColor.Sphinx.Body
        tagLabel.sizeToFit()
        
        layer.cornerRadius = 20.0
    }
}

// MARK: - Static Properties
extension AddedTagCell {
    static let reuseID = "AddedTagCell"
    
    public static let kDescriptionFont = UIFont(name: "Roboto-Regular", size: 13.0)!
    
    public static let kLeftMargin:CGFloat = 55
    public static let kRightMargin:CGFloat = 20
    
    public static func getWidthWith(description: String) -> CGFloat {
        return kDescriptionFont.sizeOfString(description, constrainedToWidth: .greatestFiniteMagnitude).width + kLeftMargin + kRightMargin
    }
}
