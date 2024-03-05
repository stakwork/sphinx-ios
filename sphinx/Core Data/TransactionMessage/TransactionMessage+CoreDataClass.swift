//
//  TransactionMessage+CoreDataClass.swift
//
//
//  Created by Tomas Timinskas on 12/09/2019.
//
//

import Foundation
import CoreData
import SwiftyJSON

@objc(TransactionMessage)
public class TransactionMessage: NSManagedObject {
    
    enum TransactionMessageType: Int {
        case message = 0 //
        case confirmation = 1
        case invoice = 2
        case payment = 3
        case cancellation = 4
        case directPayment = 5
        case attachment = 6 //
        case purchase = 7
        case purchaseAccept = 8
        case purchaseDeny = 9
        case contactKey = 10 //
        case contactKeyConfirmation = 11 //
        case groupCreate = 12 //
        case groupInvite = 13
        case groupJoin = 14 //
        case groupLeave = 15 //
        case groupKick = 16 //
        case delete = 17 //
        case repayment = 18
        case memberRequest = 19 //
        case memberApprove = 20 //
        case memberReject = 21 //
        case groupDelete = 22 //
        case botInstall = 23
        case botCmd = 24
        case botResponse = 25
        case heartbeat = 26
        case heartbeatConfirmation = 27
        case keysend = 28
        case boost = 29 //
        case query = 30
        case query_response = 31
        case call = 32 //
        case unknown = 33
        case imageAttachment = 100 //
        case videoAttachment = 101 //
        case audioAttachment = 102 //
        case textAttachment = 103 //
        case pdfAttachment = 104 //
        case fileAttachment = 105 //
        
        public init(fromRawValue: Int){
            self = TransactionMessageType(rawValue: fromRawValue) ?? .unknown
        }
    }
    
    enum TransactionMessageStatus: Int {
        case pending = 0
        case confirmed = 1
        case cancelled = 2
        case received = 3
        case failed = 4
        case deleted = 5
        case unknown = 6
        
        public init(fromRawValue: Int){
            self = TransactionMessageStatus(rawValue: fromRawValue) ?? .unknown
        }
    }
    
    enum TransactionMessageDirection: Int {
        case incoming = 0
        case outgoing = 1
    }
    
    static let typesToExcludeFromChat = [
        TransactionMessageType.purchase.rawValue,
        TransactionMessageType.purchaseAccept.rawValue,
        TransactionMessageType.purchaseDeny.rawValue,
        TransactionMessageType.repayment.rawValue
    ]
    
    static let kCallRoomName = "/sphinx.call"
    
    func getCMExtensionAssignment() -> String {
        var fileExtension: String = "txt"
        
        if(self.isPicture()){
            fileExtension = "png"
        }
        else if(self.isVideo()){
            fileExtension = "mp4"
        }
        else if(self.isAudio()){
            fileExtension = "wav"
        }
        else if(self.isGif()){
            fileExtension = "gif"
        }
        else if(self.isPDF()){
            fileExtension = "pdf"
        }
        else if(self.isDoc()){
            fileExtension = "doc"
        }
        else if(self.isSpreadsheet()){
            fileExtension = "xls"
        }
        else if(self.isAttachment()){
            fileExtension = self.getFileExtension()
        }
        
        return fileExtension
    }

    static func insertMessage(
        m: JSON,
        existingMessage: TransactionMessage? = nil
    ) -> (TransactionMessage?, Bool) {
        
        let encryptionManager = EncryptionManager.sharedInstance
        
        let id = m["id"].intValue
        
        if id <= 0 {
            return (nil, false)
        }
        
        let type = m["type"].int ?? -1
        let sender = m["sender"].intValue
        let senderAlias = m["sender_alias"].string
        let senderPic = m["sender_pic"].string
        let recipientAlias = m["recipient_alias"].string
        let recipientPic = m["recipient_pic"].string
        let receiver = m["contact_id"].intValue
        let uuid:String? = m["uuid"].string
        let replyUUID:String? = m["reply_uuid"].string
        let threadUUID:String? = m["thread_uuid"].string
        
        var amount:NSDecimalNumber? = nil
        if let a = m["amount"].double, abs(a) > 0 {
            amount = NSDecimalNumber(value: a)
        }
        
        let paymentHash:String? = m["payment_hash"].string
        let invoice:String? = m["payment_request"].string
        let mediaToken:String? = m["media_token"].string
        let mediaType:String? = m["media_type"].string
        let originalMuid:String? = m["original_muid"].string
        let person:String? = m["person"].string
        let errorMessage:String? = m["error_message"].string
        
        var mediaKey:String? = nil
        if let mk = m["media_key"].string, mk != "" {
            mediaKey = encryptionManager.decryptMessage(message: mk).1
        }
        
        let seen:Bool = m["seen"].boolValue
        let push:Bool = m["push"].boolValue
        
        if let contact = m["contact"].dictionary {
            let _ = UserContact.getOrCreateContact(contact: JSON(contact))
        }
        
        guard let messageChat = TransactionMessage.getChat(m: m) else  {
            return (nil, false)
        }
        
        messageChat.seen = (m["chat"].dictionary)?["seen"]?.boolValue ?? messageChat.seen

        
        let (messageEncrypted, messageContent) = encryptionManager.decryptMessage(message: m["message_content"].stringValue)
        let status = TransactionMessage.TransactionMessageStatus(fromRawValue: (m["status"].intValue))
        let date = Date.getDateFromString(dateString: m["date"].stringValue) ?? Date()
        let expirationDate = Date.getDateFromString(dateString: m["expiration_date"].stringValue) ?? nil
        
        let userId = UserData.sharedInstance.getUserId()
        let incoming = userId != sender
        let messageSeen = (seen ? seen : (existingMessage?.seen ?? !incoming))
        
        var message : TransactionMessage!
        
        if let existingMessage = existingMessage {
            message = existingMessage
        } else {
            message = TransactionMessage(context: CoreDataManager.sharedManager.persistentContainer.viewContext) as TransactionMessage
        }
        
        let updatedMessage = TransactionMessage.createObject(
            id: id,
            uuid: uuid,
            replyUUID: replyUUID,
            threadUUID: threadUUID,
            type: type,
            sender: sender,
            senderAlias: senderAlias,
            senderPic: senderPic,
            recipientAlias: recipientAlias,
            recipientPic: recipientPic,
            receiver: receiver,
            amount: amount,
            paymentHash: paymentHash,
            invoice: invoice,
            messageContent: messageContent,
            status: status.rawValue,
            date: date,
            expirationDate: expirationDate,
            mediaToken: mediaToken,
            mediaKey: mediaKey,
            mediaType: mediaType,
            originalMuid: originalMuid,
            person: person,
            errorMessage: errorMessage,
            seen: messageSeen,
            push: push,
            messageEncrypted: messageEncrypted,
            chat: messageChat,
            message: message
        )
        
        return (updatedMessage, existingMessage == nil)
    }
    
    static func getChat(
        m: JSON
    ) -> Chat? {
        
        if let chatId = m["chat_id"].int, let chatObject = Chat.getChatWith(id: chatId) {
            return chatObject
        } else if let ch = m["chat"].dictionary, let chatObject = Chat.getOrCreateChat(chat: JSON(ch)) {
            return chatObject
        }
        
        return nil
    }
    
    static func createObject(
        id: Int,
        uuid: String? = nil,
        replyUUID: String? = nil,
        threadUUID:String? = nil,
        type: Int,
        sender: Int,
        senderAlias: String?,
        senderPic: String?,
        recipientAlias: String?,
        recipientPic: String?,
        receiver: Int,
        amount: NSDecimalNumber? = nil,
        paymentHash: String? = nil,
        invoice: String? = nil,
        messageContent: String,
        status: Int,
        date: Date,
        expirationDate: Date? = nil,
        mediaTerms: String? = nil,
        receipt: String? = nil,
        mediaToken: String? = nil,
        mediaKey: String? = nil,
        mediaType: String? = nil,
        originalMuid: String? = nil,
        person: String? = nil,
        errorMessage: String? = nil,
        seen: Bool,
        push: Bool,
        messageEncrypted: Bool,
        chat: Chat?,
        message: TransactionMessage
    ) -> TransactionMessage? {
        
        message.id = id
        message.uuid = uuid
        message.replyUUID = replyUUID
        message.threadUUID = threadUUID
        message.type = type
        message.senderId = sender
        message.senderAlias = senderAlias
        message.senderPic = senderPic
        message.recipientAlias = recipientAlias
        message.recipientPic = recipientPic
        message.receiverId = receiver
        message.amount = amount
        message.paymentHash = paymentHash
        message.invoice = invoice
        message.status = status
        message.date = date
        message.expirationDate = expirationDate
        message.mediaToken = mediaToken
        message.muid = TransactionMessage.getMUIDFrom(mediaToken: mediaToken)
        message.originalMuid = originalMuid
        message.person = person
        message.errorMessage = errorMessage
        message.mediaKey = mediaKey
        message.mediaType = mediaType
        message.seen = seen
        message.push = push
        message.encrypted = isContentEncrypted(messageEncrypted: messageEncrypted, type: type, mediaKey: mediaKey)
        
        if messageContent != "" {
            message.messageContent = messageContent
        }
        
        if let chat = chat {
            message.chat = chat
            chat.setLastMessage(message)
        }
        
        return message
    }
    
    static func createProvisionalMessage(
        messageContent: String,
        type: Int,
        date: Date,
        chat: Chat?,
        replyUUID: String? = nil,
        threadUUID: String? = nil
    ) -> TransactionMessage? {
        
        let messageType = TransactionMessageType(fromRawValue: type)
        
        return createProvisional(
            messageContent: messageContent,
            date: date,
            chat: chat,
            replyUUID: replyUUID,
            threadUUID: threadUUID,
            type: messageType
        )
    }
    
    static func createProvisionalAttachmentMessage(
        attachmentObject: AttachmentObject,
        date: Date,
        chat: Chat?,
        replyUUID: String? = nil,
        threadUUID: String? = nil
    ) -> TransactionMessage? {
        
        return createProvisional(
            messageContent: attachmentObject.text,
            date: date,
            chat: chat,
            replyUUID: replyUUID,
            threadUUID: threadUUID,
            type: TransactionMessageType.attachment,
            attachmentObject: attachmentObject
        )
    }
    
    static func createProvisional(
        messageContent: String?,
        date: Date,
        chat: Chat?,
        replyUUID: String? = nil,
        threadUUID: String? = nil,
        type: TransactionMessageType,
        attachmentObject: AttachmentObject? = nil
    ) -> TransactionMessage? {
        
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        let message = TransactionMessage(context: managedContext) as TransactionMessage
        message.id = getProvisionalMessageId()
        message.type = type.rawValue
        message.senderId = UserData.sharedInstance.getUserId()
        message.receiverId = 0
        message.messageContent = messageContent ?? attachmentObject?.paidMessage
        message.status = TransactionMessageStatus.pending.rawValue
        message.date = date
        message.replyUUID = replyUUID
        message.threadUUID = threadUUID
        
        if let attachmentObject = attachmentObject {
            message.mediaType = attachmentObject.getMimeType()
            message.mediaFileName = attachmentObject.getFileName()
            message.mediaFileSize = attachmentObject.getDecryptedData()?.count ?? 0
            
            if attachmentObject.price > 0 {
                let mediaTokenPrice = "amt=\(attachmentObject.price)&ttl=undefined".base64Encoded ?? ""
                message.mediaToken = "x.x.x.x.\(mediaTokenPrice)"
            }
        }
        
        if let chat = chat {
            message.chat = Chat.getChatWith(id: chat.id, managedContext: managedContext)
        }
        
        return message
    }
    
    static func deleteMessageWith(
        id: Int
    ) {
        if let message = TransactionMessage.getMessageWith(id: id) {
            CoreDataManager.sharedManager.deleteObject(object: message)
        }
    }
    
    func setPaymentInvoiceAsPaid() {
        if !self.isPayment() {
            return
        }
        
        if let paymentHash = self.paymentHash, self.type == TransactionMessage.TransactionMessageType.payment.rawValue {
            if let message = TransactionMessage.getInvoiceWith(paymentHash: paymentHash) {
                message.status = TransactionMessage.TransactionMessageStatus.confirmed.rawValue
            }
        }
    }
    
    func flag() -> Bool {
        if let uuid = uuid {
            UserDefaults.standard.set(true, forKey: "\(uuid)-message-flag")
            
            return true
        }
        return false
    }
    
    func unflag() -> Bool {
        if let uuid = uuid {
            UserDefaults.standard.set(false, forKey: "\(uuid)-message-flag")
            
            return true
        }
        return false
    }
    
    func setAsSeen() {
        seen = true
    }
}
