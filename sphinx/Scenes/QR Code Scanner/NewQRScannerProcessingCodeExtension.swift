//
//  NewQRScannerPayingPRExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

extension NewQRScannerViewController {
    
    @IBAction func payButtonTouched() {
        if let invoice = prDecoder.paymentRequestString {
            payInvoice(invoice: invoice)
        }
    }
    
    @IBAction func closePayingButtonTouched() {
        self.animatePayingContainer(show: false)
    }
    
    func resetLabels() {
        payButton.layer.cornerRadius = confirmButton.frame.height/2
        
        amountLabel.text = "-"
        expirationLabel.text = "-"
        memoLabel.text = "-"
    }
    
    func validateQRString(string: String) {        
        resetLabels()
        
        if validateSubscriptionQR(string: string) {
            return
        } else if validateInvoice(string: string) {
            return
        } else if validatePublicKey(string: string) {
            return
        } else if validateDeepLinks(string: string) {
            return
        }
        
        AlertHelper.showAlert(title: "sorry".localized, message: "code.not.recognized".localized)
    }
    
    func validateInvoice(string: String) -> Bool {
        prDecoder.decodePaymentRequest(paymentRequest: string)
        
        if prDecoder.isPaymentRequest() {
            DispatchQueue.main.async {
                self.completeAndShowPRDetails()
            }
            return true
        }
        return false
    }
    
    func validatePublicKey(string: String) -> Bool {
        if string.isPubKey || string.isVirtualPubKey {
            dismiss(animated: true, completion: {
                self.delegate?.didScanPublicKey?(string: string)
            })
            return true
        }
        return false
    }
    
    func validateSubscriptionQR(string: String) -> Bool {
        let subscriptionManager = SubscriptionManager.sharedInstance
        subscriptionManager.resetValues()
        
        let (valid, subscription) = subscriptionManager.setValueFrom(subscriptionString: string)
        if valid {
            goToSubscriptionDetailsView(subscription: subscription)
        }
        return valid
    }
    
    func goToSubscriptionDetailsView(subscription: SubscriptionManager.SubscriptionQR) {
        let subscriptionDetailsVC = SubscriptionDetailsViewController.instantiate(rootViewController: rootViewController, subscriptionQR: subscription, delegate: delegate)
        self.navigationController?.pushViewController(subscriptionDetailsVC, animated: true)
    }
    
    func validateDeepLinks(string: String) -> Bool {
        if let url = URL(string: string), DeepLinksHandlerHelper.storeLinkQueryFrom(url: url) {
            dismiss(animated: true, completion: { 
                self.delegate?.didScanDeepLink?()
            })
            return true
        }
        return false
    }
    
    func completeAndShowPRDetails() {
        payButton.isHidden = false
        
        if let amount = prDecoder.getAmount() {
            amountLabel.text = "\(amount) sat"
        }
        
        if let expirationDate = prDecoder.getExpirationDate() {
            if Date().timeIntervalSince1970 > expirationDate.timeIntervalSince1970 {
                expirationDateLabel.text = "expired".localized
                payButton.isHidden = true
            }
            
            let expirationDateString = expirationDate.getStringFromDate(format:"EEE dd MMM HH:mm:ss", timeZone: TimeZone.current)
            expirationLabel.text = expirationDateString
        }
        
        if let memo = prDecoder.getMemo() {
            memoLabel.text = memo
        }
        
        animatePayingContainer(show: true)
    }
    
    func animatePayingContainer(show: Bool) {
        payingContainerBottomConstraint.constant = show ? 0.0 : -250.0
        
        UIView.animate(withDuration: 0.3, animations: {
            self.payingContainer.superview?.layoutIfNeeded()
        })
    }
    
    func isProcessingPR() -> Bool {
        return payingContainerBottomConstraint.constant == 0
    }
    
    private func payInvoice(invoice: String) {
        invoiceLoading = true
        
        var parameters = [String : AnyObject]()
        parameters["payment_request"] = invoice as AnyObject?

        API.sharedInstance.payInvoice(parameters: parameters, callback: { payment in
            AlertHelper.showAlert(title: "generic.success.title".localized, message: "invoice.paid".localized)
        }, errorCallback: {
            self.invoiceLoading = false
            
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized, completion: {
                self.animatePayingContainer(show: false)
            })
        })
        self.dismiss(animated: true, completion: nil)
    }
}
