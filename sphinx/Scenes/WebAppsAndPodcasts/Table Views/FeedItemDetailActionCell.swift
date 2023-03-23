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
    @IBOutlet weak var circularProgressView: CircularProgressView!
    
    var actionType : FeedItemActionType? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureView(
        type: FeedItemActionType
    ){
        actionIconButton.isHidden = false
        circularProgressView.isHidden = true
        
        switch(type){
        case .download:
            actionLabel.text = "download".localized
            actionIconButton.setImage(UIImage(named: "itemDetailsDownload"), for: .normal)
            actionIconButton.tintColor = UIColor.Sphinx.Text.withAlphaComponent(0.5)
            break
        case .copyLink:
            actionLabel.text = "copy.link".localized
            actionIconButton.setImage(UIImage(named: "itemDetailsCopy"), for: .normal)
            actionIconButton.tintColor = UIColor.Sphinx.Text.withAlphaComponent(0.5)
            break
        case .markAsPlayed:
            actionLabel.text = "mark.as.played".localized
            actionIconButton.setImage(UIImage(named: "itemDetailsMark"), for: .normal)
            actionIconButton.tintColor = UIColor.Sphinx.Text.withAlphaComponent(0.5)
            break
        case .share:
            actionLabel.text = "share".localized
            actionIconButton.setImage(UIImage(named: "itemDetailsShare"), for: .normal)
            actionIconButton.tintColor = UIColor.Sphinx.Text.withAlphaComponent(0.5)
            break
        case .markAsUnplayed:
            actionLabel.text = "mark.as.unplayed".localized
            actionIconButton.setImage(UIImage(named: "itemDetailsPlayed"), for: .normal)
            actionIconButton.tintColor = UIColor.Sphinx.ReceivedIcon
            break
        case .erase:
            actionLabel.text = "erase.from.device".localized
            actionIconButton.setImage(UIImage(named: "itemDetailsDownloaded"), for: .normal)
            actionIconButton.tintColor = UIColor.Sphinx.ReceivedIcon
            break
        }
    }
    
    func configureDownloading(
        download: Download
    ) {
        actionIconButton.isHidden = true
        circularProgressView.isHidden = false
        
        actionLabel.text = (download.isDownloading) ? "pause".localized : "resume".localized
        
        let progress = CGFloat(download.progress) / CGFloat(100)
        circularProgressView.progressAnimation(to: progress, active: download.isDownloading)
    }
    
}
