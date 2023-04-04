//
//  ItemDescriptionImageTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 4/4/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class ItemDescriptionImageTableViewCell: UITableViewCell {

    static let reuseID = "ItemDescriptionImageTableViewCell"
    
    @IBOutlet weak var itemImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureView(imageURL:URL){
        itemImageView.sd_setImage(with: imageURL)
    }
    
}
