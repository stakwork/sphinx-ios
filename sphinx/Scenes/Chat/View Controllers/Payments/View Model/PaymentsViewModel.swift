//
//  PaymentsViewModel.swift
//  sphinx
//
//  Created by Tomas Timinskas on 18/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON

class PaymentsViewModel : NSObject {
    
    enum PaymentMode: Int {
        case receive
        case send
        case sendOnchain
    }
    
    struct Payment {
        public var memo: String?
        public var encryptedMemo: String?
        public var remoteEncryptedMemo: String?
        public var amount: Int?
        public var destinationKey: String?
        public var routeHint: String?
        public var BTCAddress: String?
        public var message: String?
        public var encryptedMessage: String?
        public var remoteEncryptedMessage: String?
        public var muid: String?
        public var messageUUID: String?
        public var dim: String?
    }
    
    var payment = Payment()
    
    func resetPayment() {
        self.payment = Payment()
    }
    
    func setPreloadedPubKey(
        preloadedPubkey: String? = nil
    ) {
        guard let preloadedPubkey = preloadedPubkey else {
            return
        }
        
        if preloadedPubkey.isVirtualPubKey {
            let (pk, rh) = preloadedPubkey.pubkeyComponents
            payment.destinationKey = pk
            payment.routeHint = rh
        } else {
            payment.destinationKey = preloadedPubkey
        }
    }
    
    func validateMemo(
        contact: UserContact?
    ) -> Bool {
        
        guard let memo = payment.memo else {
            return true
        }
        
        guard let contact = contact else {
            return memo.count < 50
        }
        
        if memo.count > 50 {
            return false
        }
        
        let encryptionManager = EncryptionManager.sharedInstance
        let encryptedOwnMessage = encryptionManager.encryptMessageForOwner(message: memo)
        let (contactIsEncrypted, encryptedContactMessage) = encryptionManager.encryptMessage(message: memo, for: contact)
        
        if contactIsEncrypted && !encryptedContactMessage.isValidLengthMemo() {
            return memo.isValidLengthMemo()
        }
        
        if contactIsEncrypted {
            payment.encryptedMemo = encryptedOwnMessage
            payment.remoteEncryptedMemo = encryptedContactMessage
        }
        
        return true
    }
    
    func validatePayment(
        contact: UserContact?
    ) -> Bool {
        guard let _ = payment.message else {
            return true
        }
        
        guard let _ = contact else {
            return false
        }
        
        return true
    }
    
    func shouldSendDirectPayment(
        parameters: [String: AnyObject],
        callback: @escaping (TransactionMessage?) -> (),
        errorCallback: @escaping () -> ()
    ) {
        API.sharedInstance.sendDirectPayment(params: parameters, callback: { payment in
            if let payment = payment {
                let (messageObject, success) = self.createLocalMessages(message: payment)
                if let messageObject = messageObject, success {
                    callback(messageObject)
                    return
                }
            }
            callback(nil)
        }, errorCallback: { _ in
            errorCallback()
        })
    }
    
    func createLocalMessages(message: JSON?) -> (TransactionMessage?, Bool) {
        if let message = message {
            if let messageObject = TransactionMessage.insertMessage(
                m: message,
                existingMessage: TransactionMessage.getMessageWith(id: message["id"].intValue)
            ).0 {
                messageObject.setPaymentInvoiceAsPaid()
                return (messageObject, true)
            }
        }
        return (nil, false)
    }
}
