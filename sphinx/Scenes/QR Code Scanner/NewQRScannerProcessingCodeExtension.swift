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
        } else if validatePublicKey(string: string) {
            return
        }else if validateInvoice(string: string) || validateZeroAmountInvoice(string: string){
            return
        } else if validateDeepLinks(string: string) {
            return
        }
        
        AlertHelper.showAlert(title: "sorry".localized, message: "code.not.recognized".localized)
    }
    
    func validateZeroAmountInvoice(string:String) -> Bool{
        print("isZeroAmountInvoice:\(prDecoder.isZeroAmountInvoice(invoice: string))")
        if(prDecoder.isZeroAmountInvoice(invoice: string)){
            DispatchQueue.main.async {
                self.completeAndShowPRDetails()
            }
            return true
        }
        
        return false
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
        if string.isPubKey || string.isVirtualPubKey || string.isV2Pubkey {
            self.handleContactOrSend(string: string)
            return true
        }
        return false
    }
    
    func handleContactOrSend(string:String){
        if string.isExistingContactPubkey().0 {
            self.dismiss(animated: true, completion: {
                self.presentPubkeySendVC(pubkey: string)
            })
        }
        else{
            let alert = CustomAlertController(title: "pub.key.options".localized, message: "select.option".localized, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "pub.key.options-add.contact".localized, style: .default, handler:{ (UIAlertAction) in
                self.showAddContact(pubkey: string)
            }))

            alert.addAction(UIAlertAction(title: "pub.key.options-send.payment".localized, style: .default, handler:{ (UIAlertAction) in
                self.dismiss(animated: true, completion: {
                    self.presentPubkeySendVC(pubkey: string)
                })
            }))
            
            alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel ))
            alert.popoverPresentationController?.sourceView = self.view
            alert.popoverPresentationController?.sourceRect = self.view.bounds

            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func showAddContact(pubkey:String){
        if let vc = self.delegate as? DashboardRootViewController{
            self.dismiss(animated: true,completion: {
                vc.presentNewContactVC(pubkey: pubkey)
            })
        }
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
    
    func presentPubkeySendVC(pubkey:String?=nil){
        if let delegate = self.delegate as? DashboardRootViewController{
            delegate.sendSatsButtonTouched(pubkey: pubkey)
        }
    }
    
    func goToSubscriptionDetailsView(subscription: SubscriptionManager.SubscriptionQR) {
        let subscriptionDetailsVC = SubscriptionDetailsViewController.instantiate(
            subscriptionQR: subscription,
            delegate: delegate
        )
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
        
        UIView.animate(withDuration: 0.2, animations: {
            self.payingContainer.superview?.layoutSubviews()
        })
    }
    
    func isProcessingPR() -> Bool {
        return payingContainerBottomConstraint.constant == 0
    }
    
    private func payInvoice(invoice: String) {
        invoiceLoading = true
        
        var parameters = [String : AnyObject]()
        parameters["payment_request"] = invoice as AnyObject?

        SphinxOnionManager.sharedInstance.payInvoice(invoice: invoice)
        self.dismiss(animated: true, completion: nil)
    }
}
