//
//  Library
//
//  Created by Tomas Timinskas on 05/07/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class DirectPaymentReceivedTableViewCell: CommonDirectPaymentTableViewCell, MessageRowProtocol {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        paymentIcon.tintColorDidChange()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        super.configurePayment(messageRow: messageRow, contact: contact, chat: chat, incoming: true)
    }
}
