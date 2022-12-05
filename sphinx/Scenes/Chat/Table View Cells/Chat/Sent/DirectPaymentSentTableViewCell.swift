//
//  Library
//
//  Created by Tomas Timinskas on 05/07/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class DirectPaymentSentTableViewCell: CommonDirectPaymentTableViewCell, MessageRowProtocol {
    
    @IBOutlet weak var errorContainer: UIView!
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var seenSign: UILabel!
    @IBOutlet weak var errorContainerRightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        paymentIcon.tintColorDidChange()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureMessageRow(
        messageRow: TransactionMessageRow,
        contact: UserContact?,
        chat: Chat?
    ) {
        super.configurePayment(messageRow: messageRow, contact: contact, chat: chat, incoming: false)
        
        configureMessageStatus()
    }
    
    func configureMessageStatus() {
        guard let messageRow = messageRow else {
            return
        }
        
        let failed = messageRow.transactionMessage.failed()
        let encrypted = messageRow.encrypted
        
        seenSign.alpha = failed ? 0.0 : 1.0
        lockSign.text = (encrypted && !failed) ? "lock" : ""
        errorContainer.alpha = failed ? 1.0 : 0.0
        errorMessageLabel.text = "message.failed".localized
        
        errorContainer.layoutIfNeeded()
        let bubbleWidth = CommonDirectPaymentTableViewCell.getBubbleAndLabelWidth(messageRow: messageRow).0 + MessageBubbleView.kBubbleSentRightMargin
        let rightConstraint = bubbleWidth - errorContainer.frame.width
        errorMessageLabel.alpha = rightConstraint < 60 ? 0.0 : 1.0
        errorContainerRightConstraint.constant = rightConstraint
        errorContainer.superview?.layoutIfNeeded()
    }
    
}
