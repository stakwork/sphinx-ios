//
//  CommonVideoCallTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class CommonVideoCallTableViewCell : CommonChatTableViewCell {
    
    @IBOutlet weak var bubbleView: VideoCallBubbleView!
    @IBOutlet weak var lockSign: UILabel!
    @IBOutlet weak var joinVideoCallView: JoinVideoCallView!
    
    static let kVideoCallSmallBubbleHeight: CGFloat = 160.0
    static let kVideoCallBigBubbleHeight: CGFloat = 212.0
    
    static let kVideoCallSentBubbleWidth: CGFloat = 210.0
    static let kVideoCallReceivedBubbleWidth: CGFloat = 210.0
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let bubbleSize = getBubbleSize(messageRow: messageRow)
        return bubbleSize.height + CommonChatTableViewCell.kBubbleTopMargin + CommonChatTableViewCell.kBubbleBottomMargin
    }
    
    public static func getBubbleSize(messageRow: TransactionMessageRow) -> CGSize {
        let mode = VideoCallHelper.getCallMode(link: messageRow.transactionMessage.messageContent ?? "")
        
        switch(mode) {
        case .Audio:
            return CGSize(width: CommonVideoCallTableViewCell.kVideoCallReceivedBubbleWidth, height: CommonVideoCallTableViewCell.kVideoCallSmallBubbleHeight)
        default:
            return CGSize(width: CommonVideoCallTableViewCell.kVideoCallReceivedBubbleWidth, height: CommonVideoCallTableViewCell.kVideoCallBigBubbleHeight)
        }
    }
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        self.configureRow(messageRow: messageRow, contact: contact, chat: chat)
        
        joinVideoCallView.configure(delegate: self, link: messageRow.transactionMessage.messageContent ?? "")
    }
    
    func configureLockSign() {
        let encrypted = (messageRow?.transactionMessage.encrypted ?? false)
        lockSign.textColor = UIColor.Sphinx.WashedOutReceivedText
        lockSign.text = encrypted ? "lock" : ""
    }
}

extension CommonVideoCallTableViewCell : JoinCallViewDelegate {
    func didTapCopyLink() {
        if let link = messageRow?.transactionMessage.messageContent {
            ClipboardHelper.copyToClipboard(text: link, message: "call.link.copied.clipboard".localized)
        }
    }
    
    func didTapVideoButton() {
        if let link = messageRow?.transactionMessage.messageContent {
            delegate?.shouldStartCall(link: link, audioOnly: false)
        }
    }
    
    func didTapAudioButton() {
        if let link = messageRow?.transactionMessage.messageContent {
            delegate?.shouldStartCall(link: link, audioOnly: true)
        }
    }
}

