//
//  MediaStorageSourceTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 5/23/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class MediaStorageSourceTableViewCell: UITableViewCell {
    
    @IBOutlet weak var mediaSourceLabel: UILabel!
    @IBOutlet weak var mediaSourceSizeLabel: UILabel!
    
    
    static let reuseID = "MediaStorageSourceTableViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(forSource:StorageMediaManagerSource){
        switch(forSource){
        case .chats:
            mediaSourceLabel.text = "Chats"
            break
        case .podcasts:
            mediaSourceLabel.text = "Podcasts"
            break
        }
    }
    
}
