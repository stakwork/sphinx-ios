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
    case addToQueue
    case removeFromQueue
}

class FeedItemDetailActionCell: UITableViewCell {

    @IBOutlet weak var actionLabel: UILabel!
    @IBOutlet weak var actionIconImage: UIImageView!
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
        actionIconImage.isHidden = false
        circularProgressView.isHidden = true
        
        switch(type){
        case .download:
            actionLabel.text = "download".localized
            actionIconImage.image = UIImage(named: "itemDetailsDownload")
            actionIconImage.tintColor = UIColor.Sphinx.Text.withAlphaComponent(0.5)
            break
        case .copyLink:
            actionLabel.text = "copy.link".localized
            actionIconImage.image = UIImage(named: "itemDetailsCopy")
            actionIconImage.tintColor = UIColor.Sphinx.Text.withAlphaComponent(0.5)
            break
        case .markAsPlayed:
            actionLabel.text = "mark.as.played".localized
            actionIconImage.image = UIImage(named: "itemDetailsMark")
            actionIconImage.tintColor = UIColor.Sphinx.Text.withAlphaComponent(0.5)
            break
        case .share:
            actionLabel.text = "share".localized
            actionIconImage.image = UIImage(named: "itemDetailsShare")
            actionIconImage.tintColor = UIColor.Sphinx.Text.withAlphaComponent(0.5)
            break
        case .markAsUnplayed:
            actionLabel.text = "mark.as.unplayed".localized
            actionIconImage.image = UIImage(named: "itemDetailsPlayed")
            actionIconImage.tintColor = UIColor.Sphinx.ReceivedIcon
            break
        case .erase:
            actionLabel.text = "erase.from.device".localized
            actionIconImage.image = UIImage(named: "itemDetailsDownloaded")
            actionIconImage.tintColor = UIColor.Sphinx.ReceivedIcon
            break
        case .addToQueue:
            actionLabel.text = "add.to.queue".localized
            actionIconImage.image = UIImage(named: "playlist_add")
            actionIconImage.tintColor = UIColor.Sphinx.Text.withAlphaComponent(0.5)
            break
        case .removeFromQueue:
            actionLabel.text = "remove.from.queue".localized
            actionIconImage.image = UIImage(named: "playlist_remove")
            actionIconImage.tintColor = UIColor.Sphinx.Text.withAlphaComponent(0.5)
            break
        }
    }
    
    func configureDownloading(
        download: Download
    ) {
        actionIconImage.isHidden = true
        circularProgressView.isHidden = false
        
        actionLabel.text = (download.isDownloading) ? "pause.download".localized : "resume.download".localized
        
        let progress = CGFloat(download.progress) / CGFloat(100)
        circularProgressView.progressAnimation(to: progress, active: download.isDownloading)
    }
    
}
