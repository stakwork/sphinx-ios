//
//  BadgeListTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 12/28/22.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

public enum BadgeAdminCellType {
    case template
    case active
    case inactive
}

class BadgeAdminListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var badgeNameLabel: UILabel!
    @IBOutlet weak var badgeDescriptionLabel: UILabel!
    @IBOutlet weak var remainingAmountLabelContainerView: UIView!
    @IBOutlet weak var remainingAmountLabel: UILabel!
    @IBOutlet weak var statusButton: UIButton!
    @IBOutlet weak var totalAvailableLabel: UILabel!
    var cellType: BadgeAdminCellType? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(badge:Badge,type:BadgeAdminCellType){
        if let valid_icon = badge.icon_url{
            self.badgeImageView.sd_setImage(with: URL(string: valid_icon))
            
        }
        self.badgeNameLabel.text = badge.name
        self.badgeDescriptionLabel.text = badge.memo
        self.badgeDescriptionLabel.sizeToFit()
        
        if let badgesCreated = badge.amount_created,
           let badgesIssued = badge.amount_issued{
            let remainingAmountText = String(max(0, badgesCreated - badgesIssued))
            let fullText = "\(remainingAmountText) of \(badgesCreated) left"
            remainingAmountLabel.text = remainingAmountText
            remainingAmountLabel.textColor = UIColor.Sphinx.BodyInverted
            totalAvailableLabel.text = "of \(badgesCreated) left"
            totalAvailableLabel.textColor = UIColor.Sphinx.PlaceholderText
        }
        
        configureStatusButton(type:type)
        
        styleView()
    }
    
    func configureStatusButton(type:BadgeAdminCellType){
        statusButton.isUserInteractionEnabled = false
        statusButton.layer.cornerRadius = statusButton.frame.height/2.0
        remainingAmountLabelContainerView.backgroundColor = .clear
        totalAvailableLabel.textColor = UIColor.Sphinx.PlaceholderText
        remainingAmountLabelContainerView.isHidden = false
        remainingAmountLabel.backgroundColor = .clear
        totalAvailableLabel.isHidden = false
        self.cellType = type
        configureCellByType()
    }
    
    func configureCellByType(){
        if(cellType != nil){
            switch(cellType!){
            case .active:
                //statusButton.setTitle("ACTIVE", for: [.normal])
                statusButton.backgroundColor = UIColor.Sphinx.BodyInverted.withAlphaComponent(1.0)
                statusButton.setTitleColor(UIColor.Sphinx.Body, for: [.normal,.selected])
                
                let string = "ACTIVE"
                let attributedString = NSMutableAttributedString(string: string)
                attributedString.addAttribute(.foregroundColor, value: UIColor.Sphinx.Body, range: NSRange(location: 0, length: string.count))
                attributedString.addAttribute(.font, value: UIFont(name: "Roboto", size: 11.0), range: NSRange(location: 0, length: string.count))
                statusButton.titleLabel?.attributedText = attributedString
                break
            case .inactive:
                //statusButton.setTitle("INACTIVE", for: [.normal])
                statusButton.backgroundColor = UIColor.Sphinx.PlaceholderText.withAlphaComponent(0.07)
                statusButton.setTitleColor(UIColor.Sphinx.SecondaryText, for: [.normal,.selected])
                
                let string = "INACTIVE"
                let attributedString = NSMutableAttributedString(string: string)
            attributedString.addAttribute(.foregroundColor, value: UIColor.Sphinx.SecondaryText, range: NSRange(location: 0, length: string.count))
                attributedString.addAttribute(.font, value: UIFont(name: "Roboto", size: 11.0), range: NSRange(location: 0, length: string.count))
                statusButton.titleLabel?.attributedText = attributedString
                
                break
            case .template:
                //statusButton.setTitle("TEMPLATE", for: [.normal])
                statusButton.backgroundColor = UIColor.Sphinx.PrimaryBlue.withAlphaComponent(1.0)
                statusButton.setTitleColor(UIColor.white, for: [.normal,.selected])
                remainingAmountLabelContainerView.isHidden = true
                totalAvailableLabel.isHidden = true
                
                let string = "TEMPLATE"
                let attributedString = NSMutableAttributedString(string: string)
                attributedString.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: string.count))
                attributedString.addAttribute(.font, value: UIFont(name: "Roboto", size: 11.0), range: NSRange(location: 0, length: string.count))
                statusButton.titleLabel?.attributedText = attributedString
                break
            }
        }
    }
    
    func styleView(){
        contentView.backgroundColor = UIColor.Sphinx.Body
        remainingAmountLabel.textColor = UIColor.Sphinx.Text
        badgeDescriptionLabel.textColor = UIColor.Sphinx.Text
        badgeNameLabel.textColor = UIColor.Sphinx.Text
        remainingAmountLabelContainerView.layer.cornerRadius = 8
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        badgeNameLabel.text = ""
        badgeDescriptionLabel.text = ""
        remainingAmountLabel.text = ""
        badgeImageView.image = nil
    }
    
}
