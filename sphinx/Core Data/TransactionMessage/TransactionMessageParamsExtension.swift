//
//  TransactionMessageParamsExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import CoreData

extension TransactionMessage {
    static func getMessageParams(
        contact: UserContact? = nil,
        chat: Chat? = nil,
        file: NSDictionary? = nil,
        type: TransactionMessageType = .message,
        text: String? = nil,
        mediaKey: String? = nil,
        price: Int? = nil,
        botAmount: Int = 0,
        priceToMeet: Int? = nil,
        replyingMessage: TransactionMessage? = nil
    ) -> [String: AnyObject]? {
        
        var parameters = [String : AnyObject]()
        var contacts = [UserContact]()
        
        if type == .boost {
            parameters["boost"] = true as AnyObject?
        }
        
        if let chat = chat {
            parameters["chat_id"] = chat.id as AnyObject?
            if !chat.isPublicGroup() {
                contacts.append(contentsOf: chat.getContacts(includeOwner: false))
            }
        } else if let contact = contact {
            parameters["contact_id"] = contact.id as AnyObject?
            contacts.append(contact)
        } else {
            return nil
        }
        
        let pricePerMessage = (chat?.pricePerMessage?.intValue ?? 0)
        let escrowAmount = (chat?.escrowAmount?.intValue ?? 0)
        
        if pricePerMessage + escrowAmount + botAmount > 0 {
            parameters["amount"] = pricePerMessage + escrowAmount + botAmount as AnyObject?
        } else if let priceToMeet = priceToMeet, priceToMeet > 0 {
            parameters["amount"] = priceToMeet as AnyObject?
        }
        
        if let replyingMessage = replyingMessage, let replyUUID = replyingMessage.uuid, !replyUUID.isEmpty {
            parameters["reply_uuid"] = replyUUID as AnyObject?
        }
        
        if !addTextParams(parameters: &parameters, chat: chat, contacts: contacts, text: text) {
            return nil
        }
        
        addMediaParams(parameters: &parameters, chat: chat, contacts: contacts, mediaKey: mediaKey, file: file, price: price)
        
        return parameters
    }
    
    static func addTextParams(parameters: inout [String : AnyObject],
                              chat: Chat? = nil,
                              contacts: [UserContact],
                              text: String? = nil) -> Bool {
        
        let encryptionManager = EncryptionManager.sharedInstance
        
        if let text = text {
            let encryptedOwnMessage = encryptionManager.encryptMessageForOwner(message: text)
            parameters["text"] = encryptedOwnMessage as AnyObject?
            
            var encryptedDictionary = [String : String]()
            
            if let chat = chat, chat.isPublicGroup() {
                encryptedDictionary["chat"] = chat.getGroupEncrypted(text: text)
            } else {
                for c in contacts {
                    let (encrypted, encryptedContactMessage) = encryptionManager.encryptMessage(message: text, for: c)
                    
                    if encrypted {
                        encryptedDictionary["\(c.id)"] = encryptedContactMessage
                    }
                }
            }
            
            if encryptedDictionary.count > 0 {
                parameters["remote_text_map"] = encryptedDictionary as AnyObject?
            } else {
                return false
            }
        }
        return true
    }
    
    static func addMediaParams(parameters: inout [String : AnyObject],
                               chat: Chat? = nil,
                               contacts: [UserContact],
                               mediaKey: String? = nil,
                               file: NSDictionary? = nil,
                               price: Int? = nil) {
        
        let encryptionManager = EncryptionManager.sharedInstance
        
        if let mediaKey = mediaKey {
            var encryptedKeyDictionary = [String : String]()
            
            if let owner = UserContact.getOwner() {
                let encryptedOwnKey = encryptionManager.encryptMessageForOwner(message: mediaKey)
                encryptedKeyDictionary["\(owner.id)"] = encryptedOwnKey
            }
            
            if let chat = chat, chat.isPublicGroup() {
                encryptedKeyDictionary["chat"] = chat.getGroupEncrypted(text: mediaKey)
            } else {
                for c in contacts {
                    let (_, encryptedContactKey) = encryptionManager.encryptMessage(message: mediaKey, for: c)
                    encryptedKeyDictionary["\(c.id)"] = encryptedContactKey
                }
            }
            
            if encryptedKeyDictionary.count > 0 {
                parameters["media_key_map"] = encryptedKeyDictionary as AnyObject?
            }
        }
        
        if let mediaType = file?["mime"] as? String {
            parameters["media_type"] = mediaType as AnyObject?
        }
        
        if let muid = file?["muid"] as? String {
            parameters["muid"] = muid as AnyObject?
        }
        
        if let price = price {
            parameters["price"] = price as AnyObject?
        }
    }
    
    static func getPayAttachmentParams(message: TransactionMessage,
                                       amount: Int,
                                       chat: Chat? = nil) -> [String: AnyObject]? {
        
        var parameters = [String : AnyObject]()
        
        if let chat = chat {
            parameters["chat_id"] = chat.id as AnyObject?
        } else {
            return nil
        }
        
        parameters["contact_id"] = message.senderId as AnyObject?
        parameters["amount"] = amount as AnyObject?
        
        if let mediaToken = message.mediaToken {
            parameters["media_token"] = mediaToken as AnyObject?
        } else {
            return nil
        }
        
        return parameters
    }
    
    static func getBoostMessageParams(contact: UserContact? = nil,
                                      chat: Chat? = nil,
                                      replyingMessage: TransactionMessage? = nil) -> [String: AnyObject]? {
        
        if let replyingMessage = replyingMessage, let replyUUID = replyingMessage.uuid, !replyUUID.isEmpty {
            var parameters = [String : AnyObject]()
            
            parameters["boost"] = true as AnyObject?
            parameters["text"] = "" as AnyObject?
            
            if let chat = chat {
                parameters["chat_id"] = chat.id as AnyObject?
            } else if let contact = contact {
                parameters["contact_id"] = contact.id as AnyObject?
            }
            
            let pricePerMessage = (chat?.pricePerMessage?.intValue ?? 0)
            let escrowAmount = (chat?.escrowAmount?.intValue ?? 0)
            let tipAmount: Int = UserDefaults.Keys.meetingPmtAmount.get(defaultValue: 100)
            parameters["amount"] = pricePerMessage + escrowAmount + tipAmount as AnyObject?
            parameters["message_price"] = pricePerMessage + escrowAmount as AnyObject?
            
            parameters["reply_uuid"] = replyUUID as AnyObject?
            return parameters
        }
        return nil
    }
    
    static func getTribePaymentParams(
        chat: Chat? = nil,
        messageUUID: String,
        amount: Int,
        text: String
    ) -> [String: AnyObject]? {
        
        var parameters = [String : AnyObject]()
        
        parameters["pay"] = true as AnyObject?
        parameters["reply_uuid"] = messageUUID as AnyObject?
        
        if let chat = chat {
            parameters["chat_id"] = chat.id as AnyObject?
        }
        
        let pricePerMessage = (chat?.pricePerMessage?.intValue ?? 0)
        let escrowAmount = (chat?.escrowAmount?.intValue ?? 0)
        
        parameters["amount"] = pricePerMessage + escrowAmount + amount as AnyObject?
        parameters["message_price"] = pricePerMessage + escrowAmount as AnyObject?
        
        
        if !addTextParams(parameters: &parameters, chat: chat, contacts: [], text: text) {
            return nil
        }
        
        return parameters
    }
}
