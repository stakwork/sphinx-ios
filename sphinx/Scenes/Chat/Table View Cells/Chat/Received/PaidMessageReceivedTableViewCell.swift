//
//  PaidMessageReceivedTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 17/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class PaidMessageReceivedTableViewCell: CommonPaidMessageTableViewCell, MessageRowProtocol {
    
    @IBOutlet weak var paidAttachmentView: PaidAttachmentView!
    @IBOutlet weak var bubbleWidth: NSLayoutConstraint!
    
    public static let kMinimumWidth:CGFloat = 220
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        paidAttachmentView.backgroundColor = UIColor.red
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, tribeAdminId: Int?) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat)
        
        commonConfigurationForMessages()
        
        lockSign.text = messageRow.transactionMessage.encrypted ? "lock" : ""

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    override func showBubble(messageRow: TransactionMessageRow, error: Bool = false) {
        messageRow.transactionMessage.paidMessageError = error
        
        let minimumWidth = PaidMessageReceivedTableViewCell.kMinimumWidth
        let (label, bubbleSize) = bubbleView.showIncomingMessageBubble(messageRow: messageRow, minimumWidth: minimumWidth)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: bubbleSize, incoming: true)
        setBubbleWidth(bubbleSize: bubbleSize)
        addLinksOnLabel(label: label)
        paidAttachmentView.configure(messageRow: messageRow, delegate: self)
    }
    
    func setBubbleWidth(bubbleSize: CGSize) {
        bubbleWidth.constant = bubbleSize.width
        bubbleView.superview?.layoutIfNeeded()
        bubbleView.layoutIfNeeded()
    }
    
    public static func getBubbleSize(messageRow: TransactionMessageRow) -> CGSize {
        let minimumWidth = PaidMessageReceivedTableViewCell.kMinimumWidth
        let bubbleMaxWidth = CommonBubbleView.getBubbleMaxWidth(message: messageRow.transactionMessage)
        let bubbleMargin = Constants.kBubbleReceivedArrowMargin
        return CommonPaidMessageTableViewCell.getBubbleSize(messageRow: messageRow, minimumWidth: minimumWidth, maxWidth: bubbleMaxWidth, bubbleMargin: bubbleMargin)
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let bubbleSize = getBubbleSize(messageRow: messageRow)
        let replyTopPading = CommonChatTableViewCell.getReplyTopPadding(message: messageRow.transactionMessage)
        let rowHeight = bubbleSize.height + CommonChatTableViewCell.kBubbleTopMargin + CommonChatTableViewCell.kBubbleBottomMargin + replyTopPading
        let payButtonHeight: CGFloat = messageRow.shouldShowPaidAttachmentView() ? PaidAttachmentView.kViewHeight : 0.0
        let linksHeight = CommonChatTableViewCell.getLinkPreviewHeight(messageRow: messageRow)
        return rowHeight + linksHeight + payButtonHeight
    }
}

extension PaidMessageReceivedTableViewCell : PaidAttachmentViewDelegate {
    func didTapPayButton() {
        if let message = messageRow?.transactionMessage {
            let price = message.getAttachmentPrice() ?? 0
            paidAttachmentView.configure(status: TransactionMessage.TransactionMessageType.purchase, price: price)
            delegate?.didTapPayAttachment(message: message)
        }
    }
}
