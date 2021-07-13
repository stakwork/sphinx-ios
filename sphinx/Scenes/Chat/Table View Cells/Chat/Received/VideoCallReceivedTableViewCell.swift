//
//  VideoCallReceivedTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class VideoCallReceivedTableViewCell: CommonVideoCallTableViewCell, MessageRowProtocol {

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
        
        let bubbleSize = CommonVideoCallTableViewCell.getBubbleSize(messageRow: messageRow)
        bubbleView.showIncomingVideoCallBubble(messageRow: messageRow, size: bubbleSize)

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func configureStatus() {
        configureLockSign()
    }
}
