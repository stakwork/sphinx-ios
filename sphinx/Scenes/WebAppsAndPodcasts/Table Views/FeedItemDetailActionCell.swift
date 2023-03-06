//
//  FeedItemDetailActionCell.swift
//  sphinx
//
//  Created by James Carucci on 3/2/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

public enum FeedItemActionType{
    case download
    case share
    case markAsPlayed
    case copyLink
}

class FeedItemDetailActionCell: UITableViewCell {

    @IBOutlet weak var actionLabel: UILabel!
    @IBOutlet weak var actionIconButton: UIButton!
    
    var actionType : FeedItemActionType? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureView(type:FeedItemActionType){
        self.backgroundColor = .clear
        switch(type){
        case .download:
            actionLabel.text = "download".localized
            actionIconButton.setTitle("download", for: .normal)
            break
        case .copyLink:
            actionLabel.text = "copy.link".localized
            actionIconButton.setTitle("content_copy", for: .normal)
            break
        case .markAsPlayed:
            actionLabel.text = "mark.as.played".localized
            actionIconButton.setTitle("done", for: .normal)
            break
        case .share:
            actionLabel.text = "share".localized
            actionIconButton.setTitle("ios_share", for: .normal)
            break
        }
    }
    
}
