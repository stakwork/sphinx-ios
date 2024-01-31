//
//  SphinxOnionManager+HandleStateExtension.swift
//  sphinx
//
//  Created by James Carucci on 12/19/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import MessagePack
import CocoaMQTT
import ObjectMapper
import SwiftyJSON


extension SphinxOnionManager {
    func handleRunReturn(rr: RunReturn){
        if let sm = rr.stateMp{
            //update state map
            let _ = storeOnionState(inc: sm.bytes)
        }
        
        if let topic0 = rr.topic0{
            pushRRTopic(topic: topic0, payloadData: rr.payload0)
        }
        
        if let topic1 = rr.topic1{
            pushRRTopic(topic: topic1, payloadData: rr.payload1)
        }
        
        if let topic2 = rr.topic2{
            pushRRTopic(topic: topic2, payloadData: rr.payload2)
        }
        
        if let mci = rr.myContactInfo{
            let components = mci.split(separator: "_").map({String($0)})
            if let components = parseContactInfoString(routeHint: mci),
               UserContact.getContactWithDisregardStatus(pubkey: components.0) == nil{//only add this if we don't already have a "self" contact
                createSelfContact(scid: components.2, serverPubkey: components.1,myOkKey: components.0)
            }
        }
        
        if let balance = rr.newBalance{
            NotificationCenter.default.post(Notification(name: .onBalanceDidChange, object: nil, userInfo: ["balance" : balance]))
        }
        
        
        processGenericMessages(rr: rr)
                
        processKeyExchangeMessages(rr: rr)
        
        
        if let sentStatus = rr.sentStatus{
            
        }
        
        if let settledStatus = rr.settledStatus{
            
        }
        
        if let error = rr.error {
            
        }
    }

    func pushRRTopic(topic:String,payloadData:Data?){
        let byteArray: [UInt8] = payloadData != nil ? [UInt8](payloadData!) : [UInt8]()
        print("pushRRTopic | topic:\(topic) | payload:\(byteArray)")
        self.mqtt.publish(
            CocoaMQTTMessage(
                topic: topic,
                payload: byteArray
            )
        )
    }
    
    func timestampToDate(timestamp:UInt64)->Date?{
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
        return date
    }
    
    //MARK: processes updates from general purpose messages like plaintext and attachments
    func processGenericMessages(rr:RunReturn){
        if let message = rr.msg,
           var plaintextMessage = PlaintextOrAttachmentMessageFromServer(JSONString: message),
           let omuuid = plaintextMessage.originalUuid,//update uuid if it's changing/
           let newUUID = rr.msgUuid,
           var originalMessage = TransactionMessage.getMessageWith(uuid: omuuid){
            originalMessage.uuid = newUUID
            originalMessage.status = (originalMessage.status == (TransactionMessage.TransactionMessageStatus.deleted.rawValue)) ? (TransactionMessage.TransactionMessageStatus.deleted.rawValue) : (TransactionMessage.TransactionMessageStatus.received.rawValue)
            if let timestamp = rr.msgTimestamp
            {
                let date = timestampToDate(timestamp: timestamp) ?? Date()
                originalMessage.date = date
                originalMessage.updatedAt = date
            }
            originalMessage.managedObjectContext?.saveContext()
       }
        else if let uuid = rr.msgUuid,
                TransactionMessage.getMessageWith(uuid: uuid) == nil{ // guarantee it is a new message
            if let message = rr.msg,
               let type = rr.msgType,
               let sender = rr.msgSender,
               let uuid = rr.msgUuid,
               let index = rr.msgIndex,
               let timestamp = rr.msgTimestamp,
               let date = timestampToDate(timestamp: timestamp),
               let csr = ContactServerResponse(JSONString: sender){
                if type == TransactionMessage.TransactionMessageType.message.rawValue
                    || type == TransactionMessage.TransactionMessageType.call.rawValue
                    || type == TransactionMessage.TransactionMessageType.attachment.rawValue,
                   var plaintextMessage = PlaintextOrAttachmentMessageFromServer(JSONString: message){
                    plaintextMessage.senderPubkey = csr.pubkey
                    plaintextMessage.uuid = uuid
                    plaintextMessage.index = index
                    processIncomingPlaintextOrAttachmentMessage(message: plaintextMessage, date: date,csr: csr,type: Int(type))
                }
                else if type == TransactionMessage.TransactionMessageType.boost.rawValue ||
                        type == TransactionMessage.TransactionMessageType.directPayment.rawValue,
                        var boostMessage = PlaintextOrAttachmentMessageFromServer(JSONString: message),
                        let msats = rr.msgMsat,
                        let index = rr.msgIndex,
                        let uuid = rr.msgUuid
                {
                    boostMessage.senderPubkey = csr.pubkey
                    boostMessage.uuid = uuid
                    boostMessage.index = index
                    processIncomingPayment(message: boostMessage, date: date,csr: csr, amount: Int(msats/1000), type: Int(type))
                }
                else if type == TransactionMessage.TransactionMessageType.delete.rawValue,
                        var deletionRequestMessage = PlaintextOrAttachmentMessageFromServer(JSONString: message){
                    processIncomingDeletion(message: deletionRequestMessage, date: date)
                }
                else if type == TransactionMessage.TransactionMessageType.groupJoin.rawValue ||
                        type == TransactionMessage.TransactionMessageType.groupLeave.rawValue,
                    let tribePubkey = csr.pubkey,
                    let chat = Chat.getTribeChatWithOwnerPubkey(ownerPubkey: tribePubkey){
                    let joinOrLeaveMessage = TransactionMessage(context: self.managedContext)
                    joinOrLeaveMessage.uuid = uuid
                    joinOrLeaveMessage.id = Int(index) ?? Int(Int32(UUID().hashValue & 0x7FFFFFFF))
                    joinOrLeaveMessage.chat = chat
                    joinOrLeaveMessage.type = Int(type)
                    joinOrLeaveMessage.chat?.lastMessage = joinOrLeaveMessage
                    joinOrLeaveMessage.senderAlias = csr.alias
                    joinOrLeaveMessage.senderPic = csr.photoUrl
                    joinOrLeaveMessage.createdAt = date
                    joinOrLeaveMessage.date = date
                    joinOrLeaveMessage.updatedAt = date
                    joinOrLeaveMessage.seen = false
                    chat.seen = false
                    self.managedContext.saveContext()
                }
                print("handleRunReturn message: \(message)")
            }
        }
        else if isIndexedSentMessageFromMe(rr: rr), //re index my own message
                var cachedMessage = TransactionMessage.getMessageWith(uuid: rr.msgUuid!),
                let indexString = rr.msgIndex,
                    let index = Int(indexString){
            cachedMessage.id = index //sync self index
            cachedMessage.updatedAt = Date()
            cachedMessage.status = TransactionMessage.TransactionMessageStatus.confirmed.rawValue
            cachedMessage.managedObjectContext?.saveContext()
            print(rr)
        }
    }
    
    //MARK: Processes key exchange messages (friend requests) between contacts
    func processKeyExchangeMessages(rr:RunReturn){
        if let sender = rr.msgSender,
           let csr = ContactServerResponse(JSONString: sender),
           let senderPubkey = csr.pubkey{
            print(sender)
            let type = rr.msgType ?? 255
            if type == TransactionMessage.TransactionMessageType.contactKeyConfirmation.rawValue, // incoming key exchange confirmation
               let existingContact = UserContact.getContactWithDisregardStatus(pubkey: senderPubkey){ // if contact exists it's a key exchange response from them or it exists already
                NotificationCenter.default.post(Notification(name: .newContactWasRegisteredWithServer, object: nil, userInfo: ["contactPubkey" : existingContact.publicKey]))
                existingContact.nickname = csr.alias
                existingContact.avatarUrl = csr.photoUrl
                if existingContact.getChat() == nil{
                    createChat(for: existingContact)
                }
                existingContact.nickname = csr.alias
                existingContact.status = UserContact.Status.Confirmed.rawValue
                CoreDataManager.sharedManager.saveContext()
                
            }
            else if type == TransactionMessage.TransactionMessageType.contactKey.rawValue, // incoming key exchange request
                    UserContact.getContactWithDisregardStatus(pubkey: senderPubkey) == nil,//don't respond to requests if already exists
                let newContactRequest = createNewContact(pubkey: senderPubkey, nickname: csr.alias, photo_url: csr.photoUrl, person: csr.person){//new contact from a key exchange message
                NotificationCenter.default.post(Notification(name: .newContactWasRegisteredWithServer, object: nil, userInfo: ["contactPubkey" : newContactRequest.publicKey]))
                newContactRequest.status = UserContact.Status.Confirmed.rawValue
                createChat(for: newContactRequest)
                managedContext.saveContext()
            }
        }
    }

    func isIndexedSentMessageFromMe(rr:RunReturn)->Bool{
        if let _ = rr.msgUuid,
           let _ = rr.msgIndex{
            return true
        }
        return false
    }

    var mutationKeys: [String] {
        get {
            if let onionState: String = UserDefaults.Keys.onionState.get() {
                return onionState.components(separatedBy: ",")
            }
            return []
        }
        set {
            UserDefaults.Keys.onionState.set(
                newValue.joined(separator: ",")
            )
        }
    }
    
    func loadOnionStateAsData() -> Data {
        let state = loadOnionState()
        
        var mpDic = [MessagePackValue:MessagePackValue]()

        for (key, value) in state {
            mpDic[MessagePackValue(key)] = MessagePackValue(Data(value))
        }
        
        let stateBytes = pack(
            MessagePackValue(mpDic)
        ).bytes
        
        return Data(stateBytes)
    }

    private func loadOnionState() -> [String: [UInt8]] {
        var state:[String: [UInt8]] = [:]
        
        for key in mutationKeys {
            if let value = UserDefaults.standard.object(forKey: key) as? [UInt8] {
                state[key] = value
            }
        }
        return state
    }
    

    func storeOnionState(inc: [UInt8]) -> [NSNumber] {
        let muts = try? unpack(Data(inc))
        
        guard let mutsDictionary = (muts?.value as? MessagePackValue)?.dictionaryValue else {
            return []
        }
        
        persist_muts(muts: mutsDictionary)

        return []
    }

    private func persist_muts(muts: [MessagePackValue: MessagePackValue]) {
        var keys: [String] = []
        
        for  mut in muts {
            if let key = mut.key.stringValue, let value = mut.value.dataValue?.bytes {
                keys.append(key)
              
                UserDefaults.standard.set(value, forKey: key)
                UserDefaults.standard.synchronize()
            }
        }
        
        keys.append(contentsOf: mutationKeys)
        mutationKeys = keys
    }

}


struct ContactServerResponse: Mappable {
    var pubkey: String?
    var alias: String?
    var photoUrl: String?
    var person: String?

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        pubkey    <- map["pubkey"]
        alias     <- map["alias"]
        photoUrl  <- map["photo_url"]
        person    <- map["person"]
    }
    
}


struct PlaintextOrAttachmentMessageFromServer: Mappable {
    var content:String?
    var amount:Int?
    var senderPubkey:String?=nil
    var uuid:String?=nil
    var originalUuid:String?=nil
    var index:String?=nil
    var replyUuid:String?=nil
    var threadUuid:String?=nil
    var mediaKey:String?=nil
    var mediaToken:String?=nil
    var mediaType:String?=nil
    var muid:String?=nil
    var date:Int?=nil

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        content    <- map["content"]
        amount     <- map["amount"]
        replyUuid <- map["replyUuid"]
        threadUuid <- map["threadUuid"]
        mediaToken <- map["mediaToken"]
        mediaType <- map["mediaType"]
        mediaKey <- map["mediaKey"]
        muid <- map["muid"]
        date <- map["date"]
        originalUuid <- map["originalUuid"]
    }
    
}
