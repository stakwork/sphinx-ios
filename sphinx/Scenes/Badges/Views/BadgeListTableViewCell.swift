//
//  BadgeListTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 12/28/22.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

class BadgeListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var badgeNameLabel: UILabel!
    @IBOutlet weak var badgeDescriptionLabel: UILabel!
    @IBOutlet weak var remainingAmountLabelContainerView: UIView!
    @IBOutlet weak var remainingAmountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(badge:Badge){
        if let valid_icon = badge.icon_url{
            self.badgeImageView.sd_setImage(with: URL(string: valid_icon))
        }
        self.badgeNameLabel.text = badge.name
        self.badgeDescriptionLabel.text = badge.requirements
        self.badgeDescriptionLabel.sizeToFit()
        self.remainingAmountLabel.text = "100"
        
        styleView()
    }
    
    func styleView(){
        contentView.backgroundColor = UIColor.Sphinx.Body
        remainingAmountLabel.textColor = UIColor.Sphinx.Text
        badgeDescriptionLabel.textColor = UIColor.Sphinx.Text
        badgeNameLabel.textColor = UIColor.Sphinx.Text
        remainingAmountLabelContainerView.backgroundColor = UIColor.Sphinx.TextInverted
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
