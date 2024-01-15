//
//  SphinxOnionManager+ChatExtension.swift
//  sphinx
//
//  Created by James Carucci on 12/4/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import CocoaMQTT
import SwiftyJSON

extension SphinxOnionManager{
    
    func formatMsg(
            content:String,
            type:UInt8,
            muid:String?=nil,
            recipPubkey:String?=nil,
            mediaKey:String?=nil,
            mediaType:String?="file",
            threadUUID:String?,
            replyUUID:String?
        )->(String?,String?)?{
        var msg : [String:Any]? = nil
        var mt : String? = nil
        switch(type){
        case UInt8(TransactionMessage.TransactionMessageType.message.rawValue):
            msg = [
                "content":content,
            ]
            break
        case UInt8(TransactionMessage.TransactionMessageType.attachment.rawValue):
            guard let seed = getAccountSeed(),
            let muid = muid,
            let recipPubkey = recipPubkey,
            let expiry = Calendar.current.date(byAdding: .year, value: 1, to: Date()),
            let mediaKey = mediaKey else{
                return nil
            }
            do{
                mt = try makeMediaToken(seed: seed, uniqueTime: getEntropyString(), state: loadOnionStateAsData(), host: "memes.sphinx.chat", muid: muid, to: recipPubkey, expiry: UInt32(expiry.timeIntervalSince1970))
                msg = [
                    "content": content,
                    "mediaToken": mt,
                    "mediaKey": mediaKey,
                    "mediaType": mediaType,
                ]
                
            }
            catch{
                return nil
            }
            break
        case UInt8(TransactionMessage.TransactionMessageType.boost.rawValue):
            msg = [
                "content":content
            ]
            break
        case UInt8(TransactionMessage.TransactionMessageType.directPayment.rawValue):
            msg = [
                "content":content
            ]
            break
        default:
            return nil
            break
        }
            
        replyUUID != nil ? (msg?["replyUuid"] = replyUUID) : ()
        threadUUID != nil ? (msg?["threadUuid"] = threadUUID) : ()
            
        guard let contentData = try? JSONSerialization.data(withJSONObject: msg),
              let contentJSONString = String(data: contentData, encoding: .utf8)
               else{
            return nil
        }
        
        return (contentJSONString,mt)
    }
    
    func sendMessage(
            to recipContact: UserContact,
            content:String,
            chat:Chat,
            amount:Int=0,
            shouldSendAsKeysend:Bool = false,
            msgType:UInt8=0,
            muid: String?=nil,
            recipPubkey: String?=nil,
            mediaKey:String?=nil,
            mediaType:String?=nil,
            threadUUID:String?,
            replyUUID:String?
        )->TransactionMessage?{
        guard let seed = getAccountSeed() else{
            return nil
        }
        
        guard let selfContact = UserContact.getSelfContact(),
              let nickname = selfContact.nickname,
              let recipPubkey = recipContact.publicKey,
              let (contentJSONString,mediaToken) = formatMsg(
                content: content,
                type: msgType,
                muid: muid,
                recipPubkey: recipPubkey,
                mediaKey: mediaKey,
                mediaType: mediaType,
                threadUUID: threadUUID, 
                replyUUID: replyUUID
            ),
            let contentJSONString = contentJSONString else{
            return nil
        }
        
        let myImg = selfContact.avatarUrl ?? ""
        
        do{
            let rr = try! send(seed: seed, uniqueTime: getEntropyString(), to: recipPubkey, msgType: msgType, msgJson: contentJSONString, state: loadOnionStateAsData(), myAlias: nickname, myImg: myImg, amtMsat: UInt64((amount * 1000)))
            let sentMessage = processNewOutgoingMessage(rr: rr, chat: chat, msgType: msgType, content: content, amount: amount,mediaKey:mediaKey,mediaToken: mediaToken, mediaType: mediaType, replyUUID: replyUUID, threadUUID: threadUUID)
            handleRunReturn(rr: rr)
            return sentMessage
        }
        catch{
            print("error")
        }
    }
    
    func processNewOutgoingMessage(rr:RunReturn,
                               chat:Chat,
                               msgType:UInt8,
                               content:String,
                                amount:Int,
                               mediaKey:String?,
                               mediaToken:String?,
                               mediaType:String?,
                                   replyUUID:String?,
                                   threadUUID:String?
    )->TransactionMessage?{
        if let sentUUID = rr.msgUuid{
            let date = Date()
            var message : TransactionMessage? = nil
            if let existingMessage = TransactionMessage.getMessageWith(uuid: sentUUID){
                message = existingMessage
            }
            else{
                message  = TransactionMessage.createProvisionalMessage(
                    messageContent: content,
                    type: Int(msgType),
                    date: date,
                    chat: chat,
                    replyUUID: nil,
                    threadUUID: nil
                )
            }
            
            if(msgType == TransactionMessage.TransactionMessageType.attachment.rawValue){
                message?.mediaKey = mediaKey
                message?.mediaToken = mediaToken
                message?.mediaType = mediaType
            }
            else if(msgType == TransactionMessage.TransactionMessageType.boost.rawValue) || (msgType == TransactionMessage.TransactionMessageType.directPayment.rawValue){
                message?.amount = NSDecimalNumber(value: amount)
            }
            
            message?.replyUUID = replyUUID
            message?.threadUUID = threadUUID
            message?.createdAt = date
            message?.updatedAt = date
            message?.uuid = sentUUID
            message?.id = sentUUID.hashValue
            message?.chat?.lastMessage = message
            message?.managedObjectContext?.saveContext()
            return message
        }
        
        return nil
    }
    
    func processIncomingPlaintextMessage(message:PlaintextMessageFromServer,amount:Int=0,type:Int?=nil){
        guard let indexString = message.index,
            let index = Int(indexString),
            TransactionMessage.getMessageWith(id: index) == nil,
            let content = message.content,
//              let amount = message.amount,
              let pubkey = message.senderPubkey,
              let contact = UserContact.getContactWithDisregardStatus(pubkey: pubkey),
              let chat = contact.getChat(),
              let uuid = message.uuid else{
            return //error getting values
        }
        
        let newMessage = TransactionMessage(context: managedContext)
        newMessage.id = index
        newMessage.uuid = uuid
        newMessage.createdAt = Date()
        newMessage.updatedAt = Date()
        newMessage.date = Date()
        newMessage.status = TransactionMessage.TransactionMessageStatus.confirmed.rawValue
        newMessage.type = type ?? TransactionMessage.TransactionMessageType.message.rawValue
        newMessage.encrypted = true
        newMessage.senderId = contact.id
        newMessage.receiverId = UserContact.getSelfContact()?.id ?? 0
        newMessage.push = false
        newMessage.seen = false
        newMessage.chat?.seen = false
        newMessage.messageContent = content
        newMessage.chat = chat
        newMessage.replyUUID = message.replyUuid
        newMessage.threadUUID = message.threadUuid
        newMessage.chat?.lastMessage = newMessage
        newMessage.amount = NSDecimalNumber(value: amount)
        managedContext.saveContext()
        
        UserData.sharedInstance.setLastMessageIndex(index: index)
    }
    
    func processIncomingAttachmentMessage(message:AttachmentMessageFromServer){
        guard let indexString = message.index,
            let index = Int(indexString),
            TransactionMessage.getMessageWith(id: index) == nil,
            let content = message.content,
//              let amount = message.amount,
              let pubkey = message.senderPubkey,
              let contact = UserContact.getContactWithDisregardStatus(pubkey: pubkey),
              let chat = contact.getChat(),
              let uuid = message.uuid else{
            return //error getting values
        }
        
        let newMessage = TransactionMessage(context: managedContext)
        newMessage.id = index
        newMessage.uuid = uuid
        newMessage.createdAt = Date()
        newMessage.updatedAt = Date()
        newMessage.date = Date()
        newMessage.status = TransactionMessage.TransactionMessageStatus.confirmed.rawValue
        newMessage.type = TransactionMessage.TransactionMessageType.attachment.rawValue
        newMessage.encrypted = true
        newMessage.senderId = contact.id
        newMessage.receiverId = UserContact.getSelfContact()?.id ?? 0
        newMessage.push = true
        newMessage.seen = false
        newMessage.messageContent = content
        newMessage.chat = chat
        newMessage.mediaKey = message.mediaKey
        newMessage.mediaToken = message.mediaToken
        newMessage.mediaType = message.mediaType
        newMessage.threadUUID = message.threadUuid
        newMessage.replyUUID = message.replyUuid
        
        managedContext.saveContext()
        
        UserData.sharedInstance.setLastMessageIndex(index: index)
    }
    
    

    func signChallenge(challenge: String) -> String? {
        guard let seed = self.getAccountSeed() else {
            return nil
        }
        do {
            guard let challengeData = Data(base64Encoded: challenge) else {
                return nil
            }
            
            let resultHex = try signBytes(seed: seed, idx: 0, time: getEntropyString(), network: network, msg: challengeData)
            
            // Convert the hex string to binary data
            if let resultData = Data(hexString: resultHex) {
                let base64URLString = resultData.base64EncodedString(options: .init(rawValue: 0))
                    .replacingOccurrences(of: "/", with: "_")
                    .replacingOccurrences(of: "+", with: "-")
                
                return base64URLString
            } else {
                // Handle the case where hex to data conversion failed
                return nil
            }
        } catch {
            return nil
        }
    }
    

    func sendAttachment(
        file: NSDictionary,
        attachmentObject: AttachmentObject,
        chat:Chat?,
        replyingMessage: TransactionMessage? = nil,
        threadUUID: String? = nil
    ){
        
        guard let muid = file["muid"] as? String,
            let chat = chat,
            let mk = attachmentObject.mediaKey
            else{
                return
            }
        
        let (_,mediaType) = attachmentObject.getFileAndMime()
        
        //Create JSON object and push through onion network
        print("muid:\(muid)")
       let message = TransactionMessage.getMessageWith(muid: muid)
        
        guard let recipPubkey = attachmentObject.contactPubkey,
              let recipContact = UserContact.getContactWithDisregardStatus(pubkey: recipPubkey)
        else{ //TODO: upgrade this
            return
        }
        
        if let sentMessage = self.sendMessage(
            to: recipContact,
            content: attachmentObject.text ?? "",
            chat: chat,
            msgType: UInt8(TransactionMessage.TransactionMessageType.attachment.rawValue),
            muid: muid,
            recipPubkey: recipContact.publicKey,
            mediaKey: mk,
            mediaType: mediaType,
            threadUUID:threadUUID,
            replyUUID: replyingMessage?.uuid
        ){
            AttachmentsManager.sharedInstance.cacheImageAndMediaData(message: sentMessage, attachmentObject: attachmentObject)
        }
    }
    
    //MARK: Payments related
    func sendBoostReply(
        params: [String: AnyObject],
        chat:Chat
    ){
        guard let contact = chat.getContact(),
        let replyUUID = params["reply_uuid"] as? String,
        let text = params["text"] as? String,
        let amount = params["amount"] as? Int else{
            return
        }
        if let sentMessage = self.sendMessage(to: contact, content: text, chat: chat,amount: amount, msgType: UInt8(TransactionMessage.TransactionMessageType.boost.rawValue), threadUUID: nil, replyUUID: replyUUID){
            print(sentMessage)
        }
    }
    
    func sendDirectPaymentMessage(
        params:[String:Any],
        chat:Chat
    )->Bool{
        guard let contact = chat.getContact(),
        let amount = params["amount"] as? Int,
        let muid = params["muid"] as? String else{
            return false
        }
        
        if let _ = sendMessage(to: contact, content: "", chat: chat,amount: amount, msgType: UInt8(TransactionMessage.TransactionMessageType.directPayment.rawValue),muid: muid, threadUUID: nil, replyUUID: nil){
            return true
        }
        else{
            return false
        }
    }

}


extension Data {
    init?(hexString: String) {
        let cleanHex = hexString.replacingOccurrences(of: " ", with: "")
        var data = Data(capacity: cleanHex.count / 2)

        var index = cleanHex.startIndex
        while index < cleanHex.endIndex {
            let byteString = cleanHex[index ..< cleanHex.index(index, offsetBy: 2)]
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            } else {
                return nil
            }
            index = cleanHex.index(index, offsetBy: 2)
        }

        self = data
    }
}
