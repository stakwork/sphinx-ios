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
        self.badgeImageView.sd_setImage(with: URL(string: "https://static-00.iconduck.com/assets.00/whale-icon-512x415-xtgxbil4.png"))
        self.badgeNameLabel.text = badge.name
        self.badgeDescriptionLabel.text = "My badge is the best badge. Ok folks?👌👌 All other badges are a disgrace. My badges are for winners only folks. Everyone agrees."
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
    
}
