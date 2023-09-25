//
//  InvoiceView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 23/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol InvoiceViewDelegate: class {
    func didTapInvoicePayButton()
}

class InvoiceView: UIView {
    
    weak var delegate: InvoiceViewDelegate?

    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    
    @IBOutlet weak var memoContainerView: UIView!
    @IBOutlet weak var memoLabel: UILabel!
    
    @IBOutlet weak var payButtonContainer: UIView!
    @IBOutlet weak var payButtonView: UIView!
    
    @IBOutlet weak var borderView: UIView!
    
    let kDashedLayerName = "dashed-layer"
    
    var borderColor: UIColor? = nil
    var shouldDrawBorder: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("InvoiceView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        payButtonView.layer.cornerRadius = 5
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        buildDashesBorder()
    }
    
    func buildDashesBorder() {
        borderView.removeDashedLineBorderWith(name: kDashedLayerName)
        
        if let borderColor = borderColor, shouldDrawBorder {
            borderView.addDashedLineBorder(
                color: borderColor,
                fillColor: UIColor.Sphinx.Body,
                rect: CGRect(
                    x: 0,
                    y: 0,
                    width: borderView.frame.width,
                    height: borderView.frame.height
                ),
                roundedBottom: true,
                roundedTop: true,
                name: kDashedLayerName
            )
        }
    }
    
    func configureWith(
        invoice: BubbleMessageLayoutState.Invoice,
        bubble: BubbleMessageLayoutState.Bubble,
        and delegate: InvoiceViewDelegate?
    ) {
        self.delegate = delegate
        
        self.alpha = (invoice.isExpired && !invoice.isPaid) ? 0.4 : 1.0
        
        borderColor = bubble.direction.isIncoming() ? UIColor.Sphinx.PrimaryGreen : UIColor.Sphinx.SecondaryText
        shouldDrawBorder = !invoice.isPaid && !invoice.isExpired
        
        memoLabel.font = invoice.font
        unitLabel.textColor = bubble.direction.isIncoming() ? UIColor.Sphinx.WashedOutReceivedText : UIColor.Sphinx.WashedOutSentText
        
        if let memo = invoice.memo {
            memoContainerView.isHidden = false
            memoLabel.text = memo
        } else {
            memoContainerView.isHidden = true
        }
        
        amountLabel.text = invoice.amount.formattedWithSeparator
        
        payButtonContainer.isHidden = invoice.isPaid || bubble.direction.isOutgoing()
        
        if invoice.isPaid {
            if bubble.direction.isOutgoing() {
                icon.image = UIImage(named: "invoice-pay-button")
                icon.tintColor = UIColor.Sphinx.Text
            } else {
                icon.image = UIImage(named: "invoice-receive-icon")
                icon.tintColor = UIColor.Sphinx.PrimaryBlue
            }
        } else {
            icon.image = UIImage(named: "qr_code")
            icon.tintColor = UIColor.Sphinx.Text
        }
        
        self.layoutIfNeeded()
    }

    @IBAction func payButtonTouched() {
        delegate?.didTapInvoicePayButton()
    }

}
