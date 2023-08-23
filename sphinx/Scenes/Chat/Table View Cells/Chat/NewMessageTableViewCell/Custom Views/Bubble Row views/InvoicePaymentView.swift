//
//  InvoicePaymentView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 23/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class InvoicePaymentView: UIView {

    @IBOutlet private var contentView: UIView!
    @IBOutlet weak var invoiceDetailsLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("InvoicePaymentView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func configureWith(
        payment: BubbleMessageLayoutState.Payment,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        invoiceDetailsLabel.textAlignment = bubble.direction.isIncoming() ? .left : .right
        
        let dateString = payment.date.getStringDate(format: "EEEE, MMM dd")
        let amountString = payment.amount.formattedWithSeparator
        invoiceDetailsLabel.text = String(format: "invoice.amount.paid.on".localized, amountString, dateString)
    }

}
