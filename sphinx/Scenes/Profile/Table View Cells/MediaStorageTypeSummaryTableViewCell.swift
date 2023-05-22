//
//  MediaStorageTypeSummaryTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 5/22/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class MediaStorageTypeSummaryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var dotView: UIView!
    @IBOutlet weak var storageAmountLabel: UILabel!
    @IBOutlet weak var mediaTypeLabel: UILabel!
    
    static let reuseID = "MediaStorageTypeSummaryTableViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func finishSetup(){
        dotView.makeCircular()
        mediaTypeLabel.text = "Blah"
        storageAmountLabel.text = "blah"
        storageAmountLabel.backgroundColor = .purple
        bringSubviewToFront(self.mediaTypeLabel)
    }
    
}
