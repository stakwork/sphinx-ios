//
//  SentPaidDetails.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class SentPaidDetails: UIView {
    
    @IBOutlet private var contentView: UIView!

    @IBOutlet weak var priceView: UIView!
    @IBOutlet weak var statusView: UIView!
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var leftMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightMarginConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("SentPaidDetails", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        priceView.layer.cornerRadius = 3
        statusView.layer.cornerRadius = 3
    }
    
    func configureWith(
        paidContent: BubbleMessageLayoutState.PaidContent
    ) {
        priceLabel.text = "\(paidContent.price.formattedWithSeparator) SAT"
        statusLabel.text = paidContent.statusTitle
    }
}
