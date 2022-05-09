//
//  Library
//
//  Created by Tomas Timinskas on 05/07/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class DirectPaymentReceivedTableViewCell: CommonDirectPaymentTableViewCell, MessageRowProtocol {
    
    @IBOutlet weak var paymentDetailsContainer: UIView!
    @IBOutlet weak var tribePaymentDetailsContainer: UIView!
    @IBOutlet weak var tribePaymentIcon: UIImageView!
    @IBOutlet weak var tribePaymentAmountLabel: UILabel!
    @IBOutlet weak var tribePaymentUnitLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        paymentIcon.tintColorDidChange()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, tribeAdminId: Int?) {
        super.configurePayment(messageRow: messageRow, contact: contact, chat: chat, incoming: true, tribeAdminId: tribeAdminId)

        configureTribePaymentLayout(messageRow: messageRow, contact: contact, chat: chat, tribeAdminId: tribeAdminId)
    }
    
    func configureTribePaymentLayout(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, tribeAdminId: Int?) {
        bubbleView.bringSubviewToFront(paymentDetailsContainer)
        bubbleView.bringSubviewToFront(tribePaymentDetailsContainer)
        
        paymentDetailsContainer.isHidden = (chat?.isPublicGroup() ?? false)
        tribePaymentDetailsContainer.isHidden = !(chat?.isPublicGroup() ?? false)
        
        setTribePaymentAmount(messageRow: messageRow)
    }
    
    func setTribePaymentAmount(messageRow: TransactionMessageRow) {
        let amountString = messageRow.getAmountString()
        tribePaymentAmountLabel.text = amountString
    }
}
