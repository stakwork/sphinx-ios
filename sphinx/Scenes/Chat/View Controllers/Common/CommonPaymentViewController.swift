//
//  CommonPaymentViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 13/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import SwiftyJSON

@objc protocol PaymentInvoiceDelegate: class {
    @objc optional func willDismissPresentedView(paymentCreated: Bool)
    @objc optional func didCreateMessage(message: TransactionMessage)
    @objc optional func didFailCreatingInvoice()
    @objc optional func shouldSendOnchain(address: String, amount: Int)
    @objc optional func shouldSendTribePayment(amount: Int, message: String, messageUUID: String, callback: (() -> ())?)
}

class CommonPaymentViewController : UIViewController {
    
    var contact : UserContact?
    var chat: Chat?
    var message: TransactionMessage?
    
    var paymentsViewModel: PaymentsViewModel!
    
    public weak var delegate: PaymentInvoiceDelegate?
    
    func shouldDismissView() {
        DelayPerformedHelper.performAfterDelay(seconds: 0.5) {
            self.dismissView()
        }
    }
    
    func dismissView() {
        delegate?.willDismissPresentedView?(paymentCreated: false)
        dismiss(animated: true, completion: nil)
    }
    
    func createLocalMessages(message: JSON?) {
        let (messageObject, success) = paymentsViewModel.createLocalMessages(message: message)
        
        if let messageObject = messageObject, success {
            self.dismiss(animated: true, completion: {
                self.delegate?.didCreateMessage?(message: messageObject)
            })
        } else {
            delegate?.didFailCreatingInvoice?()
            shouldDismissView()
        }
    }
}
