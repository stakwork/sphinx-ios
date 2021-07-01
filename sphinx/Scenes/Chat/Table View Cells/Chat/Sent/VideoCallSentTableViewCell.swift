//
//  VideoCallSentTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/03/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import UIKit

class VideoCallSentTableViewCell: CommonVideoCallTableViewCell, MessageRowProtocol {
    
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
        
        let bubbleSize = CommonVideoCallTableViewCell.getBubbleSize(messageRow: messageRow)
        bubbleView.showOutgoingVideoCallBubble(messageRow: messageRow, size: bubbleSize)

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
        configureLockSign()
        
        seenSign.text = received ? "flash_on" : ""
        seenSign.alpha = received ? 1.0 : 0.0
        errorContainer.alpha = failed ? 1.0 : 0.0
        errorMessageLabel.text = "message.failed".localized
    }
}
