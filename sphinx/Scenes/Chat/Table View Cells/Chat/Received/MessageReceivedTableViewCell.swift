//
//  Library
//
//  Created by Tomas Timinskas on 26/02/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class MessageReceivedTableViewCell: CommonReplyTableViewCell, MessageRowProtocol {

    @IBOutlet weak var bubbleView: MessageBubbleView!
    @IBOutlet weak var lockSign: UILabel!
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
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, tribeAdminId: Int?) {
        super.configureRow(messageRow: messageRow, contact: contact, chat: chat)

        let minimumWidth:CGFloat = CommonChatTableViewCell.getMinimumWidth(message: messageRow.transactionMessage)
        let (label, bubbleSize) = bubbleView.showIncomingMessageBubble(messageRow: messageRow, minimumWidth: minimumWidth)
        setBubbleWidth(bubbleSize: bubbleSize)
        addLinksOnLabel(label: label)
        
        commonConfigurationForMessages()
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: bubbleSize, incoming: true)
        
        lockSign.text = messageRow.transactionMessage.encrypted ? "lock" : ""

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
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let maxWidth = CommonBubbleView.getBubbleMaxWidth(message: messageRow.transactionMessage)
        let labelMargin = MessageBubbleView.getLabelMargin(messageRow: messageRow)
        let (_, bubbleSize) = MessageBubbleView.getLabelAndBubbleSize(messageRow: messageRow, maxBubbleWidth: maxWidth, bubbleMargin: Constants.kBubbleReceivedArrowMargin, labelMargin: labelMargin)
        let replyTopPading = CommonChatTableViewCell.getReplyTopPadding(message: messageRow.transactionMessage)
        let rowHeight = bubbleSize.height + CommonChatTableViewCell.kBubbleTopMargin + CommonChatTableViewCell.kBubbleBottomMargin + replyTopPading
        let linksHeight = CommonChatTableViewCell.getLinkPreviewHeight(messageRow: messageRow)
        return rowHeight + linksHeight
    }
    
}
