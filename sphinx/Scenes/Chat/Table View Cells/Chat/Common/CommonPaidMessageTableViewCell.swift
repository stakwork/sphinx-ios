//
//  CommonPaidMessageTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 17/04/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import UIKit

class CommonPaidMessageTableViewCell : CommonReplyTableViewCell {
    
    @IBOutlet weak var bubbleView: MessageBubbleView!
    @IBOutlet weak var lockSign: UILabel!
    
    override func getBubbbleView() -> UIView? {
        return bubbleView
    }
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        super.configureRow(messageRow: messageRow, contact: contact, chat: chat)
        
        showBubble(messageRow: messageRow)
        
        if let url = messageRow.transactionMessage.getMediaUrl(queryDB: false), (messageRow.transactionMessage.messageContent?.isEmpty ?? true) {
            loadData(url: url, messageRow: messageRow)
        }
    }
    
    func loadData(url: URL, messageRow: TransactionMessageRow) {
        MediaLoader.loadMessageData(url: url, messageRow: messageRow, completion: { messageId, message in
            if self.isDifferentRow(messageId: messageId) { return }
            self.delegate?.shouldReloadCell?(cell: self)
        }, errorCompletion: { messageId in
            if self.isDifferentRow(messageId: messageId) { return }
            self.showBubble(messageRow: messageRow, error: true)
        })
    }
    
    func showBubble(messageRow: TransactionMessageRow, error: Bool = false) {}
    
    func configureLockSign() {
        let encrypted = (messageRow?.transactionMessage.encrypted ?? false) && (messageRow?.transactionMessage.hasMediaKey() ?? false)
        lockSign.textColor = UIColor.Sphinx.WashedOutReceivedText
        lockSign.text = encrypted ? "lock" : ""
    }
    
    public static func getBubbleSize(messageRow: TransactionMessageRow,
                                     minimumWidth: CGFloat,
                                     maxWidth: CGFloat,
                                     bubbleMargin: CGFloat = Constants.kBubbleSentArrowMargin) -> CGSize {
        
        let (_, bubbleSize) = MessageBubbleView.getLabelAndBubbleSize(messageRow: messageRow, maxBubbleWidth: maxWidth, bubbleMargin: bubbleMargin)
        let size = CGSize(width: messageRow.shouldShowLinkPreview() ? maxWidth : bubbleSize.width, height: bubbleSize.height)
        return (minimumWidth > size.width ? CGSize(width: minimumWidth, height: size.height) : size)
    }
}
