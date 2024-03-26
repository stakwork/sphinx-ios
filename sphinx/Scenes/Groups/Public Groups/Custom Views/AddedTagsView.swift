//
//  AddedTagsView.swift
//  sphinx
//
//  Created by Oko-osi Korede on 26/03/2024.
//  Copyright © 2024 sphinx. All rights reserved.
//

import UIKit

class AddedTagsView: UIView {
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var container: UIView!
//    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var tagLabel: UILabel!
    
    let kNormalColor = UIColor.Sphinx.BodyInverted
    let kTextColor = UIColor.Sphinx.Body
    
    public static let kLeftMargin:CGFloat = 55
    public static let kRightMargin:CGFloat = 20
    
    public static let kDescriptionFont = UIFont(name: "Roboto-Regular", size: 13.0)!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("AddedTagsView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        container.layer.cornerRadius = container.frame.size.height / 2
//        iconImageView.layer.cornerRadius = iconImageView.frame.size.height / 2
    }
    
    func configureWith(tag: GroupsManager.Tag) {
//        iconImageView.image = UIImage(named: tag.image)
        tagLabel.text = tag.description
        tagLabel.textColor = kTextColor
        container.backgroundColor = kNormalColor
    }
    
    public static func getWidthWith(description: String) -> CGFloat {
        return kDescriptionFont.sizeOfString(description, constrainedToWidth: .greatestFiniteMagnitude).width + kLeftMargin + kRightMargin
    }
}
