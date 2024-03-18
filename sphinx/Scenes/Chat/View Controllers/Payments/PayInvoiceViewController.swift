//
//  Library
//
//  Created by Tomas Timinskas on 22/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import SwiftyJSON

class PayInvoiceViewController: UIViewController {
    
    public weak var delegate: PaymentInvoiceDelegate?
    var message: TransactionMessage?
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    @IBOutlet weak var containerViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomViewBottomConstraint: NSLayoutConstraint!
    
    let kContainerViewHeight: CGFloat = 200.0
    let kBottomViewHeight: CGFloat = 170.0
    
    var loading = false {
        didSet {
            closeButton.isEnabled = !loading
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.Sphinx.Text, view: view)
        }
    }
    
    static func instantiate(
        message: TransactionMessage,
        delegate: PaymentInvoiceDelegate
    ) -> PayInvoiceViewController {
        let viewController = StoryboardScene.Chat.payInvoiceViewController.instantiate()
        viewController.delegate = delegate
        viewController.message = message
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.alpha = 0.0
        
        sendButton.layer.cornerRadius = sendButton.frame.size.height/2
        completeData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateView(show: true, completion: {})
    }
    
    func completeData() {
        guard let message = message else {
            return
        }
        
        if let amount = message.amount {
            amountLabel.text = Int(truncating: amount).formattedWithSeparator
        }
    }
    
    private func updateTextFieldContent() {
//        if let amount = viewModel.amount {
//            guard let stringValue = Settings.shared.primaryCurrency.value.stringValue(satoshis: amount) else { return }
//
//            let numberFormatter = InputNumberFormatter(currency: Settings.shared.primaryCurrency.value)
//            amountLabel.text = numberFormatter.validate(stringValue)
//        }
    }
    
    func animateView(show: Bool, completion: @escaping (() -> ())) {
        if show {
            UIView.animate(withDuration: 0.3, animations: {
                self.view.alpha = 1.0
            }, completion: { _ in
                self.containerViewBottomConstraint.constant = 0
                self.bottomViewBottomConstraint.constant = 0
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.layoutIfNeeded()
                })
            })
        } else {
            self.containerViewBottomConstraint.constant = kContainerViewHeight
            self.bottomViewBottomConstraint.constant = kBottomViewHeight
            
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            }, completion: { _ in
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.alpha = 0.0
                }, completion: { _ in
                    completion()
                })
            })
        }
    }
    
    private func send() {
        let prd = PaymentRequestDecoder()
        prd.decodePaymentRequest(paymentRequest: message?.invoice ?? "")
        guard let message = message,
              let invoice = message.invoice,
              let chat = message.chat,
              let amount = prd.getAmount(),
              let expiry = prd.getExpirationDate(),
              let paymentHash = try? paymentHashFromInvoice(bolt11: invoice) else {
            return
        }
        
        loading = true
        
        
        SphinxOnionManager.sharedInstance.payInvoice(invoice: invoice)
        let localPaymentMessage : JSON = [
            "id": CrypterManager.sharedInstance.generateCryptographicallySecureRandomInt(upperBound: 100_000),
            "chat_id": chat.id,
            "sender": 0,
            "type": TransactionMessage.TransactionMessageType.payment.rawValue,
            "amount":amount,
            "amountMsat": amount * 1000,
            "payment_hash":paymentHash,
            "status": TransactionMessage.TransactionMessageStatus.confirmed.rawValue,
            "createdAt": Date(),
            "updatedAt": Date(),
            "payment_request": invoice
        ]
        self.createLocalPayment(payment: localPaymentMessage)
        handleMyInvoicePaymentSettled(paymentHash: paymentHash)

        
        shouldDismiss(paymentCreated: true)
    }
    
    @objc func handleMyInvoicePaymentSettled(paymentHash:String) {
        if let message = TransactionMessage.getPaymentOfInvoiceWith(paymentHash: paymentHash){
            message.setPaymentInvoiceAsPaid()
            SphinxOnionManager.sharedInstance.sendPaymentOfInvoiceMessage(message: message)
        }
    }

    
    func createLocalPayment(payment: JSON?) {
        if let payment = payment {
            if let message = TransactionMessage.insertMessage(
                m: payment,
                existingMessage: TransactionMessage.getMessageWith(id: payment["id"].intValue)
            ).0 {
//                message.setPaymentInvoiceAsPaid()
//                shouldDismiss(paymentCreated: true)
            }
        } else {
            showErrorAlert()
        }
    }
    
    func showErrorAlert(
        errorMessage: String? = nil
    ) {
        loading = false
        
        AlertHelper.showAlert(title: "generic.error.title".localized, message: errorMessage ?? "generic.error.message".localized, completion: {
            self.shouldDismiss(paymentCreated: false)
        })
    }
    
    @IBAction func sendButtonSelected() {
        sendButton.backgroundColor = UIColor.Sphinx.PrimaryBlueBorder
    }
    
    @IBAction func sendButtonDeselected() {
        sendButton.backgroundColor = UIColor.Sphinx.PrimaryBlue
    }
    
    @IBAction func sendButtonTapped() {
        sendButtonDeselected()
        send()
    }
    
    @IBAction func switchUnitButtonTapped() {
//        Settings.shared.swapCurrencies()
        updateTextFieldContent()
    }
    
    @IBAction func closeButtonTapped() {
        shouldDismiss(paymentCreated: false)
    }
    
    func shouldDismiss(paymentCreated: Bool) {
        animateView(show: false, completion: {
            self.dismiss(animated: true, completion: nil)
            self.delegate?.willDismissPresentedView?(paymentCreated: paymentCreated)
        })
    }
}
