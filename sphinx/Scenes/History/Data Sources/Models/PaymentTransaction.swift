//
//  PaymentTransaction.swift
//  sphinx
//
//  Created by Tomas Timinskas on 30/01/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import Foundation
import SwiftyJSON

class PaymentTransaction {
    
    var type : Int?
    var amount : Int?
    var date : Date?
    var senderId : Int?
    var receiverId : Int?
    var chatId : Int?
    var originalMessageUUID : String?
    var paymentRequest : String?
    var paymentHash : String?
    
    public enum TransactionDirection: Int {
        case Incoming
        case Outgoing
    }
    
    init(json: JSON) {
        let type = json["type"].int ?? nil
        let amount = json["amount"].int ?? nil
        let senderId = json["sender"].int ?? nil
        let receiverId = json["receiver"].int ?? nil
        let chatId = json["chat_id"].int ?? nil
        let date = Date.getDateFromString(dateString: json["date"].stringValue) ?? Date()
        let paymentHash = json["payment_hash"].string ?? nil
        let paymentRequest = json["payment_request"].string ?? nil
        let originalMUUID = json["reply_uuid"].string ?? nil
        
        self.type = type
        self.amount = amount
        self.senderId = senderId
        self.receiverId = receiverId
        self.chatId = chatId
        self.date = date
        self.paymentRequest = paymentRequest
        self.paymentHash = paymentHash
        self.originalMessageUUID = originalMUUID
    }
    
    func getDirection() -> TransactionDirection {
        let userId = UserData.sharedInstance.getUserId()
        if let senderId = senderId {
            if senderId == userId {
                return TransactionDirection.Outgoing
            }
        }
        return TransactionDirection.Incoming
    }
    
    func isIncoming() -> Bool {
        return getDirection() == TransactionDirection.Incoming
    }
    
    func getDate() -> Date {
        return date ?? Date()
    }
    
    func getUsers() -> String? {
        var users = ""
        
        if let senderId = senderId, let sender = UserContact.getContactWith(id: senderId), isIncoming() {
            if let nickname = sender.nickname, !nickname.isEmpty {
                return nickname
            }
        } else if let receivedId = receiverId, let receiver = UserContact.getContactWith(id: receivedId), !isIncoming() {
            if let nickname = receiver.nickname, !nickname.isEmpty {
                return nickname
            }
        } else if let chatId = chatId, let chat = Chat.getChatWith(id: chatId) {
            if let originalMUUI = originalMessageUUID, !originalMUUI.isEmpty, !isIncoming() && chat.isGroup() {
                if let originalM = TransactionMessage.getMessageWith(uuid: originalMUUI) {
                    return originalM.getMessageSenderNickname()
                }
            } else if !chat.isMyPublicGroup() {
                for contact in chat.getContacts(includeOwner: false) {
                    if let nickname = contact.nickname, !nickname.isEmpty {
                        users = "\(users)\(nickname), "
                    }
                }
                
                if users.length > 2 {
                    return String(users.dropLast(2))
                }
            }
        }
        return nil
    }
}
