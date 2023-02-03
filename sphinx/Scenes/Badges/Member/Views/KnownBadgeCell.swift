//
//  KnownBadgeCell.swift
//  sphinx
//
//  Created by James Carucci on 2/2/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class KnownBadgeCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}


// MARK: - Static Properties
extension KnownBadgeCell {
    static let reuseID = "KnownBadgeCell"
    
    static let nib: UINib = {
        UINib(nibName: "KnownBadgeCell", bundle: nil)
    }()
    
}
