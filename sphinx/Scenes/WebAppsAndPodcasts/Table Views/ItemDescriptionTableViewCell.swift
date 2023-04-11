//
//  ItemDescriptionTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 4/4/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol ItemDescriptionTableViewCellDelegate{
    func didExpandCell()
}

class ItemDescriptionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var showMoreLabel: UILabel!
    @IBOutlet weak var podcastDescriptionLabel: UILabel!
    
    static let reuseID = "ItemDescriptionTableViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureView(descriptionText: String, isExpanded: Bool){
        if isExpanded {
            podcastDescriptionLabel.text = descriptionText
            podcastDescriptionLabel.numberOfLines = 0
            showMoreLabel.isHidden = true
        } else {
            podcastDescriptionLabel.text = descriptionText
            podcastDescriptionLabel.numberOfLines = 5
            podcastDescriptionLabel.lineBreakMode = .byTruncatingTail
            showMoreLabel.isHidden = false
        }
    }
}
