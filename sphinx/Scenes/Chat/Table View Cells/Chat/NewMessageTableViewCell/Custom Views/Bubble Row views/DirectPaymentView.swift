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
    
    func configureWith(
        directPayment: BubbleMessageLayoutState.DirectPayment,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        let isIncoming = bubble.direction.isIncoming()
        let isTribePmt = directPayment.isTribePmt
        
        tribeReceivedPaymentContainer.isHidden = !isIncoming || !isTribePmt
        receivedPaymentContainer.isHidden = !isIncoming || isTribePmt
        sentPaymentContainer.isHidden = isIncoming
        
        let amountString = directPayment.amount.formattedWithSeparator
        tribeReceivedPmtAmountLabel.text = amountString
        receivedPmtAmountLabel.text = amountString
        sentPmtAmountLabel.text = amountString
        
        recipientAvatarView.isHidden = true
        
        if let recipientPic = directPayment.recipientPic {
            recipientAvatarView.configureForUserWith(
                color: directPayment.recipientColor ?? UIColor.Sphinx.SecondaryText,
                alias: directPayment.recipientAlias ?? "Unknown",
                picture: recipientPic
            )
            recipientAvatarView.isHidden = false
        } else if let recipientAlias = directPayment.recipientAlias {
            recipientAvatarView.configureForUserWith(
                color: directPayment.recipientColor ?? UIColor.Sphinx.SecondaryText,
                alias: recipientAlias,
                picture: directPayment.recipientPic
            )
            recipientAvatarView.isHidden = false
        }
    }

}
