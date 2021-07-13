//
//  PodcastBoostSentTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 28/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class PodcastBoostSentTableViewCell: CommonPodcastBoostTableViewCell, MessageRowProtocol {
    
    @IBOutlet weak var seenSign: UILabel!
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
        configureMessageStatus()
        
        let bubbleSize = CGSize(width: CommonPodcastBoostTableViewCell.kSentBubbleWidth, height: CommonPodcastBoostTableViewCell.kBubbleHeight)
        bubbleView.showOutgoingBoostBubble(messageRow: messageRow, size: bubbleSize)

        if messageRow.shouldShowRightLine {
           addRightLine()
        }

        if messageRow.shouldShowLeftLine {
           addLeftLine()
        }
    }
    
    func configureMessageStatus() {
        guard let messageRow = messageRow else {
            return
        }
        
        let received = messageRow.transactionMessage.received()
        let failed = messageRow.transactionMessage.failed()
        let expired = messageRow.transactionMessage.isMediaExpired()
        configureLockSign()
        
        seenSign.text = received ? "flash_on" : ""
        seenSign.alpha = received ? 1.0 : 0.0
        errorContainer.alpha = failed || expired ? 1.0 : 0.0
        errorMessageLabel.text = expired ? "media.terms.expired".localized : "message.failed".localized
    }
    
}
