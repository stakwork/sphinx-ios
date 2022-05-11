//
//  PaidMessageSentTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 17/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class PaidMessageSentTableViewCell: CommonPaidMessageTableViewCell, MessageRowProtocol {
    
    @IBOutlet weak var seenSign: UILabel!
    @IBOutlet weak var errorContainer: UIView!
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var attachmentPriceView: AttachmentPriceView!
    @IBOutlet weak var bubbleWidth: NSLayoutConstraint!
    
    public static let kMinimumWidth:CGFloat = 200

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat)

        commonConfigurationForMessages()
        configurePrice(messageRow: messageRow)

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func configurePrice(messageRow: TransactionMessageRow) {
        let price = messageRow.transactionMessage.getAttachmentPrice() ?? 0
        let statusAttributes = messageRow.transactionMessage.getPurchaseStatusLabel(queryDB: false)
        attachmentPriceView.configure(price: price, status: statusAttributes, forceShow: true)
    }
    
    override func showBubble(messageRow: TransactionMessageRow, error: Bool = false) {
        let minimumWidth:CGFloat = PaidMessageSentTableViewCell.kMinimumWidth
        let (label, bubbleSize) = bubbleView.showOutgoingMessageBubble(messageRow: messageRow, minimumWidth: minimumWidth)
        
        setBubbleWidth(bubbleSize: bubbleSize)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: bubbleSize, incoming: false)
        addLinksOnLabel(label: label)
        configureMessageStatus(bubbleSize: bubbleSize)
    }
    
    func setBubbleWidth(bubbleSize: CGSize) {
        bubbleWidth.constant = bubbleSize.width
        bubbleView.superview?.layoutIfNeeded()
        bubbleView.layoutIfNeeded()
    }
    
    func configureMessageStatus(bubbleSize: CGSize) {
        guard let messageRow = messageRow else {
            return
        }
        
        let received = messageRow.transactionMessage.received()
        let failed = messageRow.transactionMessage.failed()
        let encrypted = messageRow.encrypted
        
        errorMessageLabel.text = "message.failed".localized
        seenSign.alpha = received ? 1.0 : 0.0
        lockSign.text = (encrypted && !failed) ? "lock" : ""
        errorContainer.alpha = failed ? 1.0 : 0.0
        
        errorContainer.layoutIfNeeded()
        let shouldShowMessage = bubbleSize.width + MessageBubbleView.kBubbleSentRightMargin - errorContainer.frame.width > 75
        errorMessageLabel.alpha = shouldShowMessage ? 1.0 : 0.0
    }
    
    public static func getBubbleSize(messageRow: TransactionMessageRow) -> CGSize {
        let minimumWidth:CGFloat = PaidMessageSentTableViewCell.kMinimumWidth
        let bubbleMaxWidth = CommonBubbleView.getBubbleMaxWidth(message: messageRow.transactionMessage)
        return CommonPaidMessageTableViewCell.getBubbleSize(messageRow: messageRow, minimumWidth: minimumWidth, maxWidth: bubbleMaxWidth)
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let bubbleSize = getBubbleSize(messageRow: messageRow)
        let replyTopPading = CommonChatTableViewCell.getReplyTopPadding(message: messageRow.transactionMessage)
        let rowHeight = bubbleSize.height + CommonChatTableViewCell.kBubbleTopMargin + CommonChatTableViewCell.kBubbleBottomMargin + Constants.kPaidMessageTopPadding + replyTopPading
        let linksHeight = CommonChatTableViewCell.getLinkPreviewHeight(messageRow: messageRow)
        return rowHeight + linksHeight
    }
    
}
