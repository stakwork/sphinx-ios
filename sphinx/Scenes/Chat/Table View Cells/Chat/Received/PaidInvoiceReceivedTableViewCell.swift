//
//  Library
//
//  Created by Tomas Timinskas on 26/04/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class PaidInvoiceReceivedTableViewCell: InvoiceCommonChatTableViewCell, MessageRowProtocol {
    
    @IBOutlet weak var bubbleView: PaymentInvoiceView!
    @IBOutlet weak var requestPaidIcon: UIImageView!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var memoLabel: UILabel!
    @IBOutlet weak var bottomRightLineContainer: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        memoLabel.font = UIFont.getMessageFont()
        amountLabel.font = UIFont.getAmountFont()
        requestPaidIcon.tintColorDidChange()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        super.configureRow(messageRow: messageRow, contact: contact, chat: chat)

        commonConfigurationForMessages()

        let text = messageRow.transactionMessage.messageContent ?? ""
        var labelHeight = UILabel.getLabelSize(width: InvoiceCommonChatTableViewCell.kLabelWidth, text: text, font: UIFont.getMessageFont()).height
        labelHeight = text.isEmpty ? -17 : labelHeight

        let bubbleHeight = labelHeight + InvoiceCommonChatTableViewCell.kLabelTopMargin + InvoiceCommonChatTableViewCell.kLabelBottomMarginWithoutButton
        let bubbleSize = CGSize(width: InvoiceCommonChatTableViewCell.kBubbleWidth, height: bubbleHeight)
        bubbleView.showIncomingPaidInvoiceBubble(messageRow: messageRow, size: bubbleSize)

        let amountNumber = messageRow.transactionMessage.amount ?? NSDecimalNumber(value: 0)
        let amountString = Int(truncating: amountNumber).formattedWithSeparator
        amountLabel.text = "\(amountString)"

        memoLabel.text = text
        addLinksOnLabel(label: memoLabel)

        bubbleView.bringSubviewToFront(requestPaidIcon)
        bubbleView.bringSubviewToFront(amountLabel)
        bubbleView.bringSubviewToFront(unitLabel)
        bubbleView.bringSubviewToFront(memoLabel)

        bottomRightLineContainer?.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        if messageRow.shouldShowRightLine {
            addRightLine()
        } else if messageRow.transactionMessage.isPaid() {
            addBottomRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func addBottomRightLine() {
        if let bottomRightLineContainer = bottomRightLineContainer {
            let y:CGFloat = 0
            let lineFrame = CGRect(x: 0.0, y: y, width: 3, height: bottomRightLineContainer.frame.size.height - y)
            let lineLayer = getVerticalDottedLine(color: UIColor.Sphinx.WashedOutReceivedText, frame: lineFrame)
            bottomRightLineContainer.layer.addSublayer(lineLayer)
        }
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let text = messageRow.transactionMessage.messageContent ?? ""
        var labelHeight = UILabel.getLabelSize(width: kLabelWidth, text: text, font: UIFont.getMessageFont()).height
        labelHeight = text.isEmpty ? -17 : labelHeight
        
        return labelHeight + kLabelTopMargin + kLabelBottomMarginWithoutButton + kBubbleTopMargin + kBubbleBottomMargin
    }
    
}
