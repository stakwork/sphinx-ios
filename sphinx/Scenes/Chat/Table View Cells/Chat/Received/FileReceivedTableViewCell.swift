//
//  FileReceivedTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class FileReceivedTableViewCell: CommonFileTableViewCell, MessageRowProtocol {
    
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var errorContainer: UIView!
    @IBOutlet weak var paidAttachmentView: PaidAttachmentView!
    @IBOutlet weak var separatorLine: UIView!

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
        configureFile()
        configurePayment()

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func configureFile() {
        guard let messageRow = messageRow else {
            return
        }
        
        let hasContent = messageRow.transactionMessage.hasMessageContent()
        let bubbleSize = CGSize(width: CommonFileTableViewCell.kFileBubbleWidth, height: CommonFileTableViewCell.kFileBubbleHeight)
        bubbleView.showIncomingFileBubble(messageRow: messageRow, size: bubbleSize)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: bubbleSize, incoming: true)
        
        tryLoadingData(messageRow: messageRow, bubbleSize: bubbleSize)
        
        messageBubbleView.clearBubbleView()
        separatorLine.isHidden = !hasContent
        
        if hasContent {
            let (label, _) = messageBubbleView.showIncomingMessageBubble(messageRow: messageRow, fixedBubbleWidth: CommonFileTableViewCell.kFileBubbleWidth)
            addLinksOnLabel(label: label)
        }
    }
    
    func configurePayment() {
        guard let messageRow = messageRow else {
            paidAttachmentView.isHidden = true
            return
        }
        paidAttachmentView.configure(messageRow: messageRow, delegate: self)
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
    
    func tryLoadingData(messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        if let nsUrl = messageRow.transactionMessage.getMediaUrl() {
            loadFile(url: nsUrl, messageRow: messageRow, bubbleSize: bubbleSize)
        } else {
            fileLoadingFailed()
        }
    }
}

extension FileReceivedTableViewCell : PaidAttachmentViewDelegate {
    func didTapPayButton() {
        if let message = messageRow?.transactionMessage {
            let price = message.getAttachmentPrice() ?? 0
            paidAttachmentView.configure(status: TransactionMessage.TransactionMessageType.purchase, price: price)
            delegate?.didTapPayAttachment(message: message)
        }
    }
}
