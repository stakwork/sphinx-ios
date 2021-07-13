//
//  AttachmentPriceView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class AttachmentPriceView: UIView {
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet weak var priceLabelContainer: UIView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var statusLabelContainer: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("AttachmentPriceView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        priceLabelContainer.layer.cornerRadius = 5
        statusLabelContainer.layer.cornerRadius = 5
    }
    
    func configure(price: Int = 0, status: (String, UIColor), forceShow: Bool = false) {
        self.isHidden = price <= 0 && !forceShow
        let priceString = price.formattedWithSeparator
        priceLabel.text = "\(priceString) SAT"
        statusLabelContainer.backgroundColor = status.1
        statusLabel.text = status.0
    }
}
