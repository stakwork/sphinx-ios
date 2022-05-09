//
//  Library
//
//  Created by Tomas Timinskas on 26/04/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class InvoiceSentTableViewCell: InvoiceCommonChatTableViewCell, MessageRowProtocol {

    @IBOutlet weak var qrCodeIcon: UIImageView!
    @IBOutlet weak var invoiceContainerView: InvoiceContainerView!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var memoLabel: UILabel!
    @IBOutlet weak var cancelButtonContainer: UIView!
    @IBOutlet weak var lockSign: UILabel!
    @IBOutlet weak var seenSign: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        memoLabel.font = UIFont.getMessageFont()
        amountLabel.font = UIFont.getAmountFont()
        qrCodeIcon.tintColorDidChange()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, tribeAdminId: Int?) {
        super.configureRow(messageRow: messageRow, contact: contact, chat: chat)

        commonConfigurationForMessages()
        
        let received = messageRow.transactionMessage.received()
        seenSign.text = received ? "flash_on" : ""
        lockSign.text = messageRow.transactionMessage.encrypted ? "lock" : ""

        let text = messageRow.transactionMessage.messageContent ?? ""
        var labelHeight = UILabel.getLabelSize(width: InvoiceReceivedTableViewCell.kLabelWidth, text: text, font: UIFont.getMessageFont()).height
        labelHeight = text.isEmpty ? -17 : labelHeight

        let bubbleHeight = labelHeight + InvoiceReceivedTableViewCell.kLabelTopMargin + InvoiceReceivedTableViewCell.kLabelBottomMarginWithoutButton
        let bubbleSize = CGSize(width: InvoiceReceivedTableViewCell.kBubbleWidth, height: bubbleHeight)
        invoiceContainerView.addDashedBorder(color: UIColor.Sphinx.SecondaryText, size: bubbleSize)
        invoiceContainerView.layer.cornerRadius = 10
        invoiceContainerView.backgroundColor = UIColor.Sphinx.Body

        let result = messageRow.transactionMessage.amount ?? NSDecimalNumber(value: 0)
        let amountString = Int(truncating: result).formattedWithSeparator
        amountLabel.text = "\(amountString)"

        memoLabel.text = text
        addLinksOnLabel(label: memoLabel)

        configureExpiry()

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let text = messageRow.transactionMessage.messageContent ?? ""
        var labelHeight = UILabel.getLabelSize(width: kLabelWidth, text: text, font: UIFont.getMessageFont()).height
        labelHeight = text.isEmpty ? -17 : labelHeight

        return labelHeight + kLabelTopMargin + kLabelBottomMarginWithoutButton + kBubbleTopMargin + kBubbleBottomMargin
    }
    
    @IBAction func cancelButtonSelected() {
//        cancelButtonContainer.backgroundColor = UIColor(hex: "#ffc7c0")
    }
    
    @IBAction func cancelButtonDeselected() {
//        cancelButtonContainer.backgroundColor = UIColor(hex: "#FFDFDB")
    }
    
    @IBAction func cancelButtonTouched() {
//        cancelButtonDeselected()
        
//        if let messageRow = messageRow {
//            delegate?.didTapCancelButton(transactionMessage: messageRow.transactionMessage)
//        }
    }
}
