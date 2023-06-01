//
//  DirectPaymentView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class DirectPaymentView: UIView {

    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var recipientAvatarView: ChatAvatarView!
    
    @IBOutlet weak var tribeReceivedPaymentContainer: UIView!
    @IBOutlet weak var tribeReceivedPmtAmountLabel: UILabel!
    @IBOutlet weak var tribeReceivedPmtIconImageView: UIImageView!
    
    @IBOutlet weak var receivedPaymentContainer: UIView!
    
    @IBOutlet weak var receivedPmtIconImageView: UIImageView!
    @IBOutlet weak var receivedPmtAmountLabel: UILabel!
    @IBOutlet weak var receivedPmtUnitLabel: UILabel!
    
    @IBOutlet weak var sentPaymentContainer: UIView!
    @IBOutlet weak var sentPmtAmountLabel: UILabel!
    @IBOutlet weak var sentPmtUnitLabel: UILabel!
    @IBOutlet weak var sentPmtIconImageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("DirectPaymentView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }

}
