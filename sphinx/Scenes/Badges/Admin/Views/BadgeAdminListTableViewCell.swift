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
    }
    
    func configureCell(
        badge: Badge,
        type: BadgeAdminCellType
    ){
        if let valid_icon = badge.icon_url {
            
            let bitmapSize = CGSize(width: 500, height: 500)
            let defaultImage = #imageLiteral(resourceName: "appPinIcon")

            self.badgeImageView.sd_setImage(
                with: URL(string: valid_icon),
                placeholderImage: defaultImage,
                options: [],
                context: [.imageThumbnailPixelSize : bitmapSize]
            )
            
        }
        self.badgeNameLabel.text = badge.name
        self.badgeDescriptionLabel.text = badge.memo
        self.badgeDescriptionLabel.sizeToFit()
        
        if let badgesCreated = badge.amount_created,
           let badgesIssued = badge.amount_issued{
            let remainingAmountText = String(max(0, badgesCreated - badgesIssued))
            remainingAmountLabel.text = remainingAmountText
            remainingAmountLabel.textColor = UIColor.Sphinx.BodyInverted
            totalAvailableLabel.text = String(format: "badges.badges-left".localized, badgesCreated)
            totalAvailableLabel.textColor = UIColor.Sphinx.PlaceholderText
        }
        
        configureStatusButton(type:type)
        
        styleView()
    }
    
    func configureStatusButton(type: BadgeAdminCellType) {
        statusButton.isUserInteractionEnabled = false
        statusButton.layer.cornerRadius = statusButton.frame.height/2.0
        
        totalAvailableLabel.textColor = UIColor.Sphinx.PlaceholderText
        totalAvailableLabel.isHidden = false
        
        remainingAmountLabelContainerView.isHidden = false
        remainingAmountLabel.backgroundColor = .clear
        
        self.cellType = type
        
        configureCellByType()
    }
    
    func configureCellByType() {
        if(cellType != nil) {
            switch(cellType!) {
            case .active:
                statusButton.backgroundColor = UIColor.Sphinx.BodyInverted
                statusButton.setTitleColor(UIColor.Sphinx.Body, for: .normal)
                statusButton.titleLabel?.text = "active.upper".localized
                statusButton.setTitle( "active.upper".localized, for: .normal)
                break
            case .inactive:
                statusButton.backgroundColor = UIColor.Sphinx.PlaceholderText.withAlphaComponent(0.07)
                statusButton.setTitleColor(UIColor.Sphinx.SecondaryText, for: .normal)
                statusButton.titleLabel?.text = "inactive.upper".localized
                statusButton.setTitle("inactive.upper".localized, for: .normal)
                break
            case .template:
                statusButton.backgroundColor = UIColor.Sphinx.PrimaryBlue.withAlphaComponent(1.0)
                statusButton.setTitleColor(UIColor.white, for: .normal)
                remainingAmountLabelContainerView.isHidden = true
                totalAvailableLabel.isHidden = true
                statusButton.titleLabel?.text = "template.upper".localized
                statusButton.setTitle("template.upper".localized, for: .normal)
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
