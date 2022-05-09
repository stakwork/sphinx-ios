//
//  Library
//
//  Created by Tomas Timinskas on 26/04/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class ExpiredInvoiceSentTableViewCell: ExpiredInvoiceCommonChatTableViewCell, MessageRowProtocol {
    
    @IBOutlet weak var bubbleView: PaymentInvoiceView!
    @IBOutlet weak var qrCodeIcon: UIImageView!
    @IBOutlet weak var expiredInvoiceLine: UIView!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        amountLabel.font = UIFont.getAmountFont()
        qrCodeIcon.tintColorDidChange()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, tribeAdminId: Int?) {
        super.configureRow(messageRow: messageRow, contact: contact, chat: chat)
        
        let bubbleWidth = ExpiredInvoiceCommonChatTableViewCell.getExpiredInvoiceBubbleWidth(messageRow: messageRow)
        bubbleWidthConstraint.constant = bubbleWidth
        
        commonConfigurationForMessages()
        
        bubbleView.showOutgoingExpiredInvoiceBubble(messageRow: messageRow, bubbleWidth: bubbleWidth)
        
        let amountString = messageRow.getAmountString()
        amountLabel.text = "\(amountString)"
        
        drawDiagonalLine(lineContainer: expiredInvoiceLine, incoming: false)
        
        bubbleView.bringSubviewToFront(qrCodeIcon)
        bubbleView.bringSubviewToFront(amountLabel)
        bubbleView.bringSubviewToFront(unitLabel)
        bubbleView.bringSubviewToFront(expiredInvoiceLine)
        
        if messageRow.shouldShowRightLine {
            addRightLine()
        }
        
        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    public static func getRowHeight() -> CGFloat {
        return ExpiredInvoiceCommonChatTableViewCell.kExpiredBubbleHeight + CommonChatTableViewCell.kBubbleTopMargin + CommonChatTableViewCell.kBubbleBottomMargin
    }
    
}
