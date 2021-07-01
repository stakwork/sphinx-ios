//
//  MessageOptionView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 13/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol MessageOptionViewDelegate: class {
    func didTapButton(tag: Int)
}

class MessageOptionView: UIView {

    weak var delegate: MessageOptionViewDelegate?

    @IBOutlet private var contentView: UIView!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var separator: UIView!
    
    var buttonTag: Int = -1
    
    struct Option {
        var icon: String? = nil
        var iconImage: String? = nil
        var title: String
        var tag: Int
        var color: UIColor
        var showLine: Bool
        
        init(icon: String?,
             iconImage: String?,
             title: String,
             tag: Int,
             color: UIColor,
             showLine: Bool) {
            
            self.icon = icon
            self.iconImage = iconImage
            self.title = title
            self.tag = tag
            self.color = color
            self.showLine = showLine
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("MessageOptionView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func configure(option: Option, delegate: MessageOptionViewDelegate) {
        self.delegate = delegate
        self.buttonTag = option.tag
        
        iconLabel.textColor = option.color
        titleLabel.textColor = option.color
        iconImageView.tintColor = option.color
        
        if let iconText = option.icon {
            iconLabel.text = iconText
            iconLabel.isHidden = false
        } else if let iconImage = option.iconImage {
            iconImageView.image = UIImage(named: iconImage)
            iconImageView.isHidden = false
        }
        
        iconLabel.text = option.icon
        titleLabel.text = option.title
        separator.isHidden = !option.showLine
    }
    
    @IBAction func buttonTouched() {
        if buttonTag >= 0 {
            delegate?.didTapButton(tag: buttonTag)
        }
    }
    
}
