//
//  Library
//
//  Created by Tomas Timinskas on 19/04/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class TransactionPaymentSentTableViewCell: TransactionCommonTableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        super.initialConfiguration()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func configureCell(transaction: PaymentTransaction?) {
        super.configureCell(transaction: transaction)
    }
}
