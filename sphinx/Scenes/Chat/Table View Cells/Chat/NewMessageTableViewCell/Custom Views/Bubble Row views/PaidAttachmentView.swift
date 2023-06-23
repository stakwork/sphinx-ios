//
//  PaidAttachmentView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol PaidAttachmentViewDelegate: class {
    func didTapPayButton()
}

class PaidAttachmentView: UIView {
    
    weak var delegate: PaidAttachmentViewDelegate?
    @IBOutlet weak var purchaseAmountLabel: UILabel!
    @IBOutlet weak var payAttachmentContainer: UIView!
    @IBOutlet weak var processingPaymentContainer: UIView!
    @IBOutlet weak var purchaseDeniedContainer: UIView!
    @IBOutlet weak var purchaseAcceptContainer: UIView!
    @IBOutlet weak var processingLoadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var paymentsNotSupportedLabel: UILabel!
    
    static let kViewHeight: CGFloat = 50
    
    @IBOutlet private var contentView: UIView!
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: processingLoadingWheel, loadingWheelColor: UIColor.white)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("PaidAttachmentView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func configure(
        paidContent: BubbleMessageLayoutState.PaidContent,
        and delegate: PaidAttachmentViewDelegate?
    ) {
        self.delegate = delegate
        
        let priceString = paidContent.price.formattedWithSeparator
        purchaseAmountLabel.text = "\(priceString) SAT"

        payAttachmentContainer.isHidden = true
        processingPaymentContainer.isHidden = true
        purchaseAcceptContainer.isHidden = true
        purchaseDeniedContainer.isHidden = true
        loading = false

        switch(paidContent.status) {
        case TransactionMessage.TransactionMessageType.purchase:
            processingPaymentContainer.isHidden = false
            loading = true
            break
        case TransactionMessage.TransactionMessageType.purchaseAccept:
            purchaseAcceptContainer.isHidden = false
            break
        case TransactionMessage.TransactionMessageType.purchaseDeny:
            purchaseDeniedContainer.isHidden = false
            break
        default:
            payAttachmentContainer.isHidden = false
            break
        }
    }
    
    @IBAction func payButtonTouched() {
        AlertHelper.showTwoOptionsAlert(title: "confirm.purchase".localized, message: "confirm.purchase.message".localized, confirm: {
            self.delegate?.didTapPayButton()
        })
    }
}
