//
//  KnownBadgeCell.swift
//  sphinx
//
//  Created by James Carucci on 2/2/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class KnownBadgeCell: UITableViewCell {

    @IBOutlet weak var knownBadgeImageView: UIImageView!
    @IBOutlet weak var knownBadgeNameLabel: UILabel!
    @IBOutlet weak var knownBadgeDescriptionLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(badge:Badge){
        let defaultImage = #imageLiteral(resourceName: "appPinIcon")
        knownBadgeImageView.makeCircular()
        knownBadgeImageView.sd_setImage(with: URL(string: badge.icon_url ?? ""),placeholderImage: defaultImage)
        knownBadgeNameLabel.text = badge.name
        knownBadgeDescriptionLabel.text = badge.memo
    }
    
}


// MARK: - Static Properties
extension KnownBadgeCell {
    static let reuseID = "KnownBadgeCell"
    
    static let nib: UINib = {
        UINib(nibName: "KnownBadgeCell", bundle: nil)
    }()
    
}
