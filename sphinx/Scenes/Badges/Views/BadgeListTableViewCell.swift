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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(badge:Badge){
        self.contentView.backgroundColor = UIColor.Sphinx.Body
        self.badgeImageView.sd_setImage(with: URL(string: "https://static-00.iconduck.com/assets.00/whale-icon-512x415-xtgxbil4.png"))
        self.badgeNameLabel.text = badge.name
        self.badgeDescriptionLabel.text = "lorum ipsum blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah"
        self.badgeDescriptionLabel.sizeToFit()
    }
    
}
