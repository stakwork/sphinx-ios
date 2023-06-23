//
//  Library
//
//  Created by Tomas Timinskas on 26/04/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class InvoiceReceivedTableViewCell {
    
    @IBOutlet weak var qrCodeIcon: UIImageView!
//    @IBOutlet weak var invoiceContainerView: InvoiceContainerView!
//    @IBOutlet weak var paidInvoiceContainerView: PaymentInvoiceView!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var memoLabel: UILabel!
    @IBOutlet weak var payButtonContainer: UIView!
    @IBOutlet weak var payIcon: UIImageView!
    @IBOutlet weak var lockSign: UILabel!
    
    @IBOutlet weak var requestPaidIcon: UIImageView!
    @IBOutlet weak var amountPaidLabel: UILabel!
    @IBOutlet weak var unitPaidLabel: UILabel!
    @IBOutlet weak var memoPaidLabel: UILabel!
    
    @IBOutlet weak var bubbleLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var dateLabelLeftConstraint: NSLayoutConstraint!
    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        
//        memoLabel.font = UIFont.getMessageFont()
//        amountLabel.font = UIFont.getAmountFont()
//        
//        payIcon.tintColorDidChange()
//        qrCodeIcon.tintColorDidChange()
//        requestPaidIcon.tintColorDidChange()
//        
//        payButtonContainer.layer.cornerRadius = 5.0
//        payButtonContainer.addShadow(offset: CGSize(width: 0, height: 1.5), color: UIColor.Sphinx.GreenBorder, opacity: 1.0, radius: 0.0)
//    }
//
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//    }
//    
//    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
//        super.configureRow(messageRow: messageRow, contact: contact, chat: chat)
//
//        commonConfigurationForMessages()
//        revertPayingAnimation()
//        
//        lockSign.text = messageRow.transactionMessage.encrypted ? "lock" : ""
//
//        let text = messageRow.transactionMessage.messageContent ?? ""
//        var labelHeight = UILabel.getLabelSize(width: InvoiceCommonChatTableViewCell.kLabelWidth, text: text, font: UIFont.getMessageFont()).height
//        labelHeight = text.isEmpty ? -17 : labelHeight
//
//        let bubbleHeight = labelHeight + InvoiceCommonChatTableViewCell.kLabelTopMargin + InvoiceCommonChatTableViewCell.kLabelBottomMargin
//        let bubbleSize = CGSize(width: InvoiceCommonChatTableViewCell.kBubbleWidth, height: bubbleHeight)
//        invoiceContainerView.addDashedBorder(color: UIColor.Sphinx.PrimaryGreen, size: bubbleSize)
//        invoiceContainerView.layer.cornerRadius = 10
//        invoiceContainerView.backgroundColor = UIColor.Sphinx.Body
//
//        addPaidInvoiceView(messageRow: messageRow, labelHeight: labelHeight)
//
//        let amountNumber = messageRow.transactionMessage.amount ?? NSDecimalNumber(value: 0)
//        let amountString = Int(truncating: amountNumber).formattedWithSeparator
//        amountLabel.text = "\(amountString)"
//        amountPaidLabel.text = "\(amountString)"
//
//        memoLabel.text = text
//        addLinksOnLabel(label: memoLabel)
//        
//        memoPaidLabel.text = text
//        addLinksOnLabel(label: memoPaidLabel)
//
//        configureExpiry()
//
//        if messageRow.shouldShowRightLine {
//            addRightLine()
//        }
//
//        if messageRow.shouldShowLeftLine {
//            addLeftLine()
//        }
//    }
//    
//    func addPaidInvoiceView(messageRow: TransactionMessageRow, labelHeight: CGFloat) {
//        let bubbleHeight = labelHeight + InvoiceCommonChatTableViewCell.kLabelTopMargin + InvoiceCommonChatTableViewCell.kLabelBottomMarginWithoutButton
//        let bubbleSize = CGSize(width: InvoiceCommonChatTableViewCell.kBubbleWidth, height: bubbleHeight)
//        paidInvoiceContainerView.showIncomingPaidInvoiceBubble(messageRow: messageRow, size: bubbleSize)
//        paidInvoiceContainerView.removePaidBubbleLayerName()
//
//        paidInvoiceContainerView.bringSubviewToFront(requestPaidIcon)
//        paidInvoiceContainerView.bringSubviewToFront(amountPaidLabel)
//        paidInvoiceContainerView.bringSubviewToFront(unitPaidLabel)
//        paidInvoiceContainerView.bringSubviewToFront(memoPaidLabel)
//
//    }
//    
//    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
//        let text = messageRow.transactionMessage.messageContent ?? ""
//        var labelHeight = UILabel.getLabelSize(width: kLabelWidth, text: text, font: UIFont.getMessageFont()).height
//        labelHeight = text.isEmpty ? -17 : labelHeight
//
//        return labelHeight + kLabelTopMargin + kLabelBottomMargin + kBubbleTopMargin + kBubbleBottomMargin
//    }
//    
//    @IBAction func payButtonSelected() {
//        payButtonContainer.backgroundColor = UIColor.Sphinx.GreenBorder
//    }
//    
//    @IBAction func payButtonDeselected() {
//        payButtonContainer.backgroundColor = UIColor.Sphinx.PrimaryGreen
//    }
//    
//    @IBAction func payButtonTouched() {
//        payButtonDeselected()
//
//        if let messageRow = messageRow {
//            delegate?.didTapPayButton(message: messageRow.transactionMessage, cell: self)
//        }
//    }
//    
//    func animatePayingAction(completion: @escaping () -> ()) {
//        bubbleLeftConstraint.constant = WindowsManager.getWindowWidth() - InvoiceCommonChatTableViewCell.kBubbleWidth - 9.0 //57.5
//        dateLabelLeftConstraint.constant = InvoiceCommonChatTableViewCell.kBubbleWidth - dateLabel.frame.size.width - 6.0 //2.5
//        
//        UIView.animate(withDuration: 0.5, animations: {
//            self.invoiceContainerView.alpha = 0.0
//            self.paidInvoiceContainerView.alpha = 1.0
//            self.chatAvatarView?.alpha = 0.0
//            self.expireLabel.alpha = 0.0
//            self.lockSign.alpha = 0.0
//            self.invoiceContainerView.superview?.layoutIfNeeded()
//            self.dateLabel.superview?.layoutIfNeeded()
//        }, completion: { _ in
//            completion()
//        })
//    }
//    
//    func revertPayingAnimation() {
//        invoiceContainerView.alpha = 1.0
//        paidInvoiceContainerView.alpha = 0.0
//        chatAvatarView?.alpha = 1.0
//        expireLabel.alpha = 1.0
//        bubbleLeftConstraint.constant = 57.5
//        dateLabelLeftConstraint.constant = 2.5
//        invoiceContainerView.superview?.layoutIfNeeded()
//        dateLabel.superview?.layoutIfNeeded()
//    }
}
