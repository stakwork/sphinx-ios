//
//  Library
//
//  Created by Tomas Timinskas on 12/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON

final class ChatViewModel: NSObject {
    
    struct PaymentModel {
        public var memo: String?
        public var encryptedMemo: String?
        public var remoteEncryptedMemo: String?
        public var amount: Int?
        public var destinationKey: String?
        public var BTCAddress: String?
        public var message: String?
        public var encryptedMessage: String?
        public var remoteEncryptedMessage: String?
        public var muid: String?
        public var messageUUID: String?
        public var dim: String?
    }
    
    var currentPayment = PaymentModel()
    let contactsService = ContactsService()
    
    func resetCurrentPayment() {
        self.currentPayment = PaymentModel()
    }
    
    func validateMemo(contacts: [UserContact]?) -> Bool {
        guard let memo = currentPayment.memo else {
            return true
        }
        
        guard let contacts = contacts, contacts.count == 1 else {
            return memo.count < 50
        }
        
        if memo.count > 50 {
            return false
        }
        
        let contact = contacts[0]
        let encryptionManager = EncryptionManager.sharedInstance
        let encryptedOwnMessage = encryptionManager.encryptMessageForOwner(message: memo)
        let (contactIsEncrypted, encryptedContactMessage) = encryptionManager.encryptMessage(message: memo, for: contact)
        
        if contactIsEncrypted && !encryptedContactMessage.isValidLengthMemo() {
            return memo.isValidLengthMemo()
        }
        
        if contactIsEncrypted {
            currentPayment.encryptedMemo = encryptedOwnMessage
            currentPayment.remoteEncryptedMemo = encryptedContactMessage
        }
        
        return true
    }
    
    func validatePayment(contacts: [UserContact]?) -> Bool {
        guard let _ = currentPayment.message else {
            return true
        }
        
        guard let _ = contacts else {
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
        }, errorCallback: {
            errorCallback()
        })
    }
    
    func createLocalMessages(message: JSON?) -> (TransactionMessage?, Bool) {
        if let message = message {
            if let messageObject = TransactionMessage.insertMessage(m: message).0 {
                messageObject.setPaymentInvoiceAsPaid()
                return (messageObject, true)
            }
        }
        return (nil, false)
    }
    
    func getParams(
        contacts: [UserContact]?,
        chat: Chat?
    ) -> [String: AnyObject] {
        var parameters = [String : AnyObject]()
        
        if let amount = currentPayment.amount {
            parameters["amount"] = amount as AnyObject?
        }
        
        if let encryptedMemo = currentPayment.encryptedMemo, let remoteEncryptedMemo = currentPayment.remoteEncryptedMemo {
            parameters["memo"] = encryptedMemo as AnyObject?
            parameters["remote_memo"] = remoteEncryptedMemo as AnyObject?
        } else if let memo = currentPayment.memo {
            parameters["memo"] = memo as AnyObject?
        }
        
        if let publicKey = currentPayment.destinationKey {
            parameters["destination_key"] = publicKey as AnyObject?
        }
        
        if let muid = currentPayment.muid {
            parameters["muid"] = muid as AnyObject?
            parameters["media_type"] = "image/png" as AnyObject?
        }
        
        if let dim = currentPayment.dim {
            parameters["dimensions"] = dim as AnyObject?
        }
        
        if let contacts = contacts, contacts.count > 0 {
            if let chat = chat {
                parameters["chat_id"] = chat.id as AnyObject?
            } else if contacts.count > 0 {
                let contact = contacts[0]
                parameters["contact_id"] = contact.id as AnyObject?
            }
            
            if chat?.isGroup() ?? false {
                parameters["contact_ids"] = contacts.map { $0.id } as AnyObject?
            }
            
            if let text = currentPayment.message {
                let encryptionManager = EncryptionManager.sharedInstance
                let encryptedOwnMessage = encryptionManager.encryptMessageForOwner(message: text)
                parameters["text"] = encryptedOwnMessage as AnyObject?
                
                if chat?.isGroup() ?? false {
                    var encryptedDictionary = [String : String]()
                    
                    for c in contacts {
                        let (_, encryptedContactMessage) = encryptionManager.encryptMessage(message: text, for: c)
                        encryptedDictionary["\(c.id)"] = encryptedContactMessage
                    }
                    
                    if encryptedDictionary.count > 0 {
                        parameters["remote_text_map"] = encryptedDictionary as AnyObject?
                    }
                } else {
                    let contact = contacts[0]
                    let (_, encryptedContactMessage) = encryptionManager.encryptMessage(message: text, for: contact)
                    parameters["remote_text"] = encryptedContactMessage as AnyObject?
                }
            }
        } else {
            if let message = currentPayment.message {
                parameters["text"] = message as AnyObject?
            }
        }
        
        return parameters
    }
    
    func toggleVolumeOn(
        chat: Chat,
        completion: @escaping (Chat?) -> ()
    ) {
        let currentMode = chat.isMuted()
        
        API.sharedInstance.toggleChatSound(chatId: chat.id, muted: !currentMode, callback: { chatJson in
            if let updatedChat = Chat.insertChat(chat: chatJson) {
                completion(updatedChat)
            }
        }, errorCallback: {
            completion(nil)
        })
    }
    
    func sendFlagMessageFor(_ message: TransactionMessage) {
        DispatchQueue.global().async {
            let supportContact = SignupHelper.getSupportContact()
            
            if let pubkey = supportContact["pubkey"].string {
                
                if let contact = UserContact.getContactWith(pubkey: pubkey) {
                    
                    let messageSender = message.getMessageSender()
                    
                    var flagMessageContent = """
                    Message Flagged
                    - Message: \(message.uuid ?? "Empty Message UUID")
                    - Sender: \(messageSender?.publicKey ?? "Empty Sender")
                    """
                    
                    if let chat = message.chat, chat.isPublicGroup() {
                        flagMessageContent = "\(flagMessageContent)\n- Tribe: \(chat.uuid ?? "Empty Tribe UUID")"
                    }
                    
                    self.sendFlagMessage(
                        contact: contact,
                        text: flagMessageContent
                    )
                    return
                }
            }
        }
    }
    
    func sendFlagMessage(
        contact: UserContact,
        text: String
    ) {
        guard let params = TransactionMessage.getMessageParams(
                contact: contact,
                type: TransactionMessage.TransactionMessageType.message,
                text: text
        ) else {
            return
        }
        
        API.sharedInstance.sendMessage(params: params, callback: { _ in }, errorCallback: {})
    }
}
