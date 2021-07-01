//
//  PodcastBoostReceivedTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 28/10/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import UIKit

class PodcastBoostReceivedTableViewCell: CommonPodcastBoostTableViewCell, MessageRowProtocol {
    
    @IBOutlet weak var errorContainer: UIView!
    @IBOutlet weak var errorMessageLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat)

        commonConfigurationForMessages()
        configureStatus()
        
        let bubbleSize = CGSize(width: CommonPodcastBoostTableViewCell.kReceivedBubbleWidth, height: CommonPodcastBoostTableViewCell.kBubbleHeight)
        bubbleView.showIncomingBoostBubble(messageRow: messageRow, size: bubbleSize)

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func configureStatus() {
        guard let messageRow = messageRow else {
            return
        }
        
        configureLockSign()
        
        let expired = messageRow.transactionMessage.isMediaExpired()
        errorMessageLabel.text = "media.terms.expired".localized
        errorContainer.alpha = expired ? 1.0 : 0.0
    }
}
