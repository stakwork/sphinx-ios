//
//  NewThreadOnlyMessageTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 7/18/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class NewThreadOnlyMessageTableViewCell: UITableViewCell,ChatTableViewCellProtocol {

    @IBOutlet weak var senderAvatarImageView: UIImageView!
    @IBOutlet weak var contactAliasLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(){
        senderAvatarImageView.makeCircular()
    }
    
    
    func configureWith(messageCellState: MessageTableCellState, mediaData: MessageTableCellState.MediaData?, tribeData: MessageTableCellState.TribeData?, linkData: MessageTableCellState.LinkData?, botWebViewData: MessageTableCellState.BotWebViewData?, uploadProgressData: MessageTableCellState.UploadProgressData?, delegate: NewMessageTableViewCellDelegate?, searchingTerm: String?, indexPath: IndexPath) {
        
    }
}
