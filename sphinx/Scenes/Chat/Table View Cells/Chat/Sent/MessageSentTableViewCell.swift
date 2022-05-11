//
//  Library
//
//  Created by Tomas Timinskas on 26/02/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class MessageSentTableViewCell: CommonReplyTableViewCell, MessageRowProtocol {

    @IBOutlet weak var bubbleView: MessageBubbleView!
    @IBOutlet weak var seenSign: UILabel!
    @IBOutlet weak var lockSign: UILabel!
    @IBOutlet weak var errorContainer: UIView!
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var bubbleWidth: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func getBubbbleView() -> UIView? {
        return bubbleView
    }
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        super.configureRow(messageRow: messageRow, contact: contact, chat: chat)
        
        commonConfigurationForMessages()

        let minimumWidth:CGFloat = CommonChatTableViewCell.getMinimumWidth(message: messageRow.transactionMessage)
        let (label, bubbleSize) = bubbleView.showOutgoingMessageBubble(messageRow: messageRow, minimumWidth: minimumWidth)
        
        setBubbleWidth(bubbleSize: bubbleSize)
        addLinksOnLabel(label: label)
        configureMessageStatus(bubbleSize: bubbleSize)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: bubbleSize, incoming: false)

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
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
        let minimumWidth:CGFloat = getMinimumWidth(message: messageRow.transactionMessage)
        let bubbleMaxWidth = CommonBubbleView.getBubbleMaxWidth(message: messageRow.transactionMessage)
        let labelMargin = MessageBubbleView.getLabelMargin(messageRow: messageRow)
        let (_, bubbleSize) = MessageBubbleView.getLabelAndBubbleSize(messageRow: messageRow, maxBubbleWidth: bubbleMaxWidth, labelMargin: labelMargin)
        return (minimumWidth > bubbleSize.width ? CGSize(width: minimumWidth, height: bubbleSize.height) : bubbleSize)
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let bubbleSize = getBubbleSize(messageRow: messageRow)
        let replyTopPading = CommonChatTableViewCell.getReplyTopPadding(message: messageRow.transactionMessage)
        let rowHeight = bubbleSize.height + CommonChatTableViewCell.kBubbleTopMargin + CommonChatTableViewCell.kBubbleBottomMargin + replyTopPading
        let linksHeight = CommonChatTableViewCell.getLinkPreviewHeight(messageRow: messageRow)
        return rowHeight + linksHeight
    }
}
