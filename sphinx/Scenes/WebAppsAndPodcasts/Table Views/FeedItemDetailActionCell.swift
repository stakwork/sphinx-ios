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
    case markAsUnplayed
    case erase
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
            actionIconButton.setImage(UIImage(named: "itemDetailsDownload"), for: .normal)
            break
        case .copyLink:
            actionLabel.text = "copy.link".localized
            actionIconButton.setImage(UIImage(named: "itemDetailsCopy"), for: .normal)
            break
        case .markAsPlayed:
            actionLabel.text = "mark.as.played".localized
            actionIconButton.setImage(UIImage(named: "itemDetailsMark"), for: .normal)
            break
        case .share:
            actionLabel.text = "share".localized
            actionIconButton.setImage(UIImage(named: "itemDetailsShare"), for: .normal)
            break
        case .markAsUnplayed:
            actionLabel.text = "mark.as.unplayed".localized
            actionIconButton.setImage(UIImage(named: "itemDetailsMark"), for: .normal)
            break
        case .erase:
            actionLabel.text = "erase.from.device".localized
            actionIconButton.setImage(UIImage(named: "itemDetailsDownload"), for: .normal)
            break
        }
    }
    
}
