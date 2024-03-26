//
//  GroupTagView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class GroupTagView: UIView {
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var tagLabel: UILabel!
    
    let kNormalColor = UIColor.Sphinx.Body
    let kSelectedColor = UIColor.Sphinx.ReceivedMsgBG
    
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
        Bundle.main.loadNibNamed("GroupTagView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        container.layer.cornerRadius = container.frame.size.height / 2
        iconImageView.layer.cornerRadius = iconImageView.frame.size.height / 2
    }
    
    func configureWith(tag: GroupsManager.Tag) {
        iconImageView.image = UIImage(named: tag.image)
        tagLabel.text = tag.description
        container.backgroundColor = tag.selected ? kSelectedColor : kNormalColor
    }
}
