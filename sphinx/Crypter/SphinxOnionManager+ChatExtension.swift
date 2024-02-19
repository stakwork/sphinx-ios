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
    
    func loadMediaToken(
        recipPubkey:String?,
        muid:String?
    )->String?{
        guard let seed = getAccountSeed(),
        let recipPubkey = recipPubkey,
        let muid = muid,
        let expiry = Calendar.current.date(byAdding: .year, value: 1, to: Date()) else{
            return nil
        }
        do{
            let mt = try makeMediaToken(seed: seed, uniqueTime: getEntropyString(), state: loadOnionStateAsData(), host: "memes.sphinx.chat", muid: muid, to: recipPubkey, expiry: UInt32(expiry.timeIntervalSince1970))
            return mt
        }
        catch{
            return nil
        }
    }
    
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
        var msg: [String: Any] = ["content": content]
        var mt: String? = nil

        switch TransactionMessage.TransactionMessageType(rawValue: Int(type)) {
        case .message, .boost, .delete, .call, .groupLeave, .memberReject, .memberApprove,.groupDelete:
            break
        case .attachment, .directPayment, .purchase:
            mt = loadMediaToken(recipPubkey: recipPubkey, muid: muid)
            msg["mediaToken"] = mt
            msg["mediaKey"] = mediaKey
            msg["mediaType"] = mediaType
            if type == UInt8(TransactionMessage.TransactionMessageType.purchase.rawValue) {
                msg["content"] = ""
            }
        case .groupKick:
            if let member = recipPubkey{
                msg["member"] = content
            }
            else{
                return nil
            }
            break
        default:
            return nil
        }
        
        replyUUID != nil ? (msg["replyUuid"] = replyUUID) : ()
        threadUUID != nil ? (msg["threadUuid"] = threadUUID) : ()
            
        guard let contentData = try? JSONSerialization.data(withJSONObject: msg),
              let contentJSONString = String(data: contentData, encoding: .utf8)
               else{
            return nil
        }
        
        return (contentJSONString,mt)
    }
    
    func sendMessage(
            to recipContact: UserContact?,
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
        )->TransactionMessage?{//
        guard let seed = getAccountSeed() else{
            return nil
        }
        let sendAmount = chat.isConversation() ? amount : max(1, amount)  //send keysends to group
        guard let selfContact = UserContact.getSelfContact(),
              let nickname = selfContact.nickname ?? chat.name,
              let recipPubkey = (recipContact?.publicKey ?? chat.ownerPubkey),
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
            let rr = try! send(seed: seed, uniqueTime: getEntropyString(), to: recipPubkey, msgType: msgType, msgJson: contentJSONString, state: loadOnionStateAsData(), myAlias: nickname, myImg: myImg, amtMsat: UInt64((sendAmount * 1000)),isTribe: recipContact == nil)
            let sentMessage = processNewOutgoingMessage(rr: rr, chat: chat, msgType: msgType, content: content, amount: amount,mediaKey:mediaKey,mediaToken: mediaToken, mediaType: mediaType, replyUUID: replyUUID, threadUUID: threadUUID)
            handleRunReturn(rr: rr)
            return sentMessage
        }
        catch{
            print("error")
        }
    }
    
    func processNewOutgoingMessage(
        rr:RunReturn,
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
        for msg in rr.msgs{
            if let sentUUID = msg.uuid,
               msgType != TransactionMessage.TransactionMessageType.delete.rawValue
            {
                let date = Date()
                let message  = TransactionMessage.createProvisionalMessage(
                    messageContent: content,
                    type: Int(msgType),
                    date: date,
                    chat: chat,
                    replyUUID: nil,
                    threadUUID: nil
                )
                
                if(msgType == TransactionMessage.TransactionMessageType.boost.rawValue) ||
                    (msgType == TransactionMessage.TransactionMessageType.directPayment.rawValue)
                {
                    message?.amount = NSDecimalNumber(value: amount)
                    message?.mediaKey = mediaKey
                    message?.mediaToken = mediaToken
                    message?.mediaType = mediaType
                }
                else if(msgType == TransactionMessage.TransactionMessageType.purchase.rawValue) ||
                        msgType == TransactionMessage.TransactionMessageType.attachment.rawValue{
                    message?.mediaKey = mediaKey
                    message?.mediaToken = mediaToken
                    message?.mediaType = mediaType
                }
                
                message?.replyUUID = replyUUID
                message?.threadUUID = threadUUID
                message?.createdAt = date
                message?.updatedAt = date
                message?.uuid = sentUUID
                message?.id = abs(UUID().hashValue)
                message?.chat?.lastMessage = message
                message?.managedObjectContext?.saveContext()
                return message
            }
            else if let replyUUID = replyUUID,
                    msgType == TransactionMessage.TransactionMessageType.delete.rawValue,
                    let messageToDelete = TransactionMessage.getMessageWith(uuid: replyUUID){
                messageToDelete.status = TransactionMessage.TransactionMessageStatus.deleted.rawValue
                messageToDelete.chat?.lastMessage = messageToDelete
                messageToDelete.managedObjectContext?.saveContext()
                return messageToDelete
            }
        }
        
        return nil
    }
    
    //MARK: processes updates from general purpose messages like plaintext and attachments
    func processGenericMessages(rr:RunReturn){
        for message in rr.msgs{
            var plaintextMessage = PlaintextOrAttachmentMessageFromServer(msg: message)
            if let omuuid = plaintextMessage.originalUuid,//update uuid if it's changing/
               let newUUID = message.uuid,
               var originalMessage = TransactionMessage.getMessageWith(uuid: omuuid){
                originalMessage.uuid = newUUID
                originalMessage.status = (originalMessage.status == (TransactionMessage.TransactionMessageStatus.deleted.rawValue)) ? (TransactionMessage.TransactionMessageStatus.deleted.rawValue) : (TransactionMessage.TransactionMessageStatus.received.rawValue)
                if let timestamp = message.timestamp
                {
                    let date = timestampToDate(timestamp: timestamp) ?? Date()
                    originalMessage.date = date
                    originalMessage.updatedAt = date
                }
                
                if let type = message.type,
                   type == TransactionMessage.TransactionMessageType.memberApprove.rawValue,
                   let ruuid = originalMessage.replyUUID,
                   let messageWeAreReplying = TransactionMessage.getMessageWith(uuid: ruuid){
                    originalMessage.senderAlias = messageWeAreReplying.senderAlias
                }
                else if let owner = UserContact.getOwner(){
                    originalMessage.senderAlias = owner.nickname
                    originalMessage.senderPic = owner.avatarUrl
                }
                
                originalMessage.managedObjectContext?.saveContext()
           }
            else if let uuid = message.uuid,
                    TransactionMessage.getMessageWith(uuid: uuid) == nil{ // guarantee it is a new message
                if let type = message.type,
                   let sender = message.sender,
                   let uuid = message.uuid,
                   let index = message.index,
                   let timestamp = message.timestamp,
                   let date = timestampToDate(timestamp: timestamp),
                   let csr = ContactServerResponse(JSONString: sender){
                    if type == TransactionMessage.TransactionMessageType.message.rawValue
                        || type == TransactionMessage.TransactionMessageType.call.rawValue
                        || type == TransactionMessage.TransactionMessageType.attachment.rawValue{
                        plaintextMessage.senderPubkey = csr.pubkey
                        plaintextMessage.uuid = uuid
                        plaintextMessage.index = index
                        processIncomingPlaintextOrAttachmentMessage(message: plaintextMessage, date: date,csr: csr,type: Int(type))
                    }
                    else if type == TransactionMessage.TransactionMessageType.boost.rawValue ||
                            type == TransactionMessage.TransactionMessageType.directPayment.rawValue,
                            let msats = message.msat,
                            let index = message.index,
                            let uuid = message.uuid
                    {
                        plaintextMessage.senderPubkey = csr.pubkey
                        plaintextMessage.uuid = uuid
                        plaintextMessage.index = index
                        processIncomingPayment(message: plaintextMessage, date: date,csr: csr, amount: Int(msats/1000), type: Int(type))
                    }
                    else if type == TransactionMessage.TransactionMessageType.delete.rawValue{
                        processIncomingDeletion(message: plaintextMessage, date: date)
                    }
                    else if isGroupAction(type: type),
                        let tribePubkey = csr.pubkey,
                        let chat = Chat.getTribeChatWithOwnerPubkey(ownerPubkey: tribePubkey){
                        let groupActionMessage = TransactionMessage(context: self.managedContext)
                        groupActionMessage.uuid = uuid
                        groupActionMessage.id = Int(index) ?? Int(Int32(UUID().hashValue & 0x7FFFFFFF))
                        groupActionMessage.chat = chat
                        groupActionMessage.type = Int(type)
                        groupActionMessage.chat?.lastMessage = groupActionMessage
                        groupActionMessage.senderAlias = csr.alias
                        groupActionMessage.senderPic = csr.photoUrl
                        groupActionMessage.createdAt = date
                        groupActionMessage.date = date
                        groupActionMessage.updatedAt = date
                        groupActionMessage.seen = false
                        chat.seen = false
                        (type == TransactionMessage.TransactionMessageType.memberApprove.rawValue) ? (chat.status = Chat.ChatStatus.approved.rawValue) : ()
                        (type == TransactionMessage.TransactionMessageType.memberReject.rawValue) ? (chat.status = Chat.ChatStatus.rejected.rawValue) : ()
                        self.managedContext.saveContext()
                    }
                    print("handleRunReturn message: \(message)")
                }
            }
            else if isIndexedSentMessageFromMe(msg: message),
                    let uuid = message.uuid,
                    var cachedMessage = TransactionMessage.getMessageWith(uuid: uuid),
                    let indexString = message.index,
                        let index = Int(indexString){
                cachedMessage.id = index //sync self index
                cachedMessage.updatedAt = Date()
                cachedMessage.status = TransactionMessage.TransactionMessageStatus.confirmed.rawValue
                cachedMessage.managedObjectContext?.saveContext()
                print(rr)
            }
        }
    }
    
    func processIncomingPlaintextOrAttachmentMessage(message:PlaintextOrAttachmentMessageFromServer,date:Date, csr:ContactServerResponse?=nil ,amount:Int=0,type:Int?=nil){
        guard let indexString = message.index,
            let index = Int(indexString),
            TransactionMessage.getMessageWith(id: index) == nil,
            let content = message.content,
//              let amount = message.amount,
              let pubkey = message.senderPubkey,
              let uuid = message.uuid else{
            return //error getting values
        }
        
        var chat : Chat? = nil
        var senderId: Int? = nil
        //var senderAlias : String? = nil
        if let contact = UserContact.getContactWithDisregardStatus(pubkey: pubkey),
           let oneOnOneChat = contact.getChat(){
            chat = oneOnOneChat
            senderId = contact.id
        }
        else if let tribeChat = Chat.getTribeChatWithOwnerPubkey(ownerPubkey: pubkey){
            print("found tribeChat:\(tribeChat)")
            chat = tribeChat
            senderId = tribeChat.id
        }
        
        guard let chat = chat,
              let senderId = senderId else{
            return //error extracting proper chat data
        }
        
        let newMessage = TransactionMessage(context: managedContext)
        newMessage.id = index
        newMessage.uuid = uuid
        newMessage.createdAt = date
        newMessage.updatedAt = date
        newMessage.date = date
        newMessage.status = TransactionMessage.TransactionMessageStatus.confirmed.rawValue
        newMessage.type = type ?? TransactionMessage.TransactionMessageType.message.rawValue
        newMessage.encrypted = true
        newMessage.senderId = senderId
        newMessage.receiverId = UserContact.getSelfContact()?.id ?? 0
        newMessage.push = false
        newMessage.seen = false
        newMessage.chat?.seen = false
        newMessage.messageContent = content
        newMessage.chat = chat
        newMessage.replyUUID = message.replyUuid
        newMessage.threadUUID = message.threadUuid
        newMessage.chat?.lastMessage = newMessage
        newMessage.chat?.seen = false
        newMessage.senderAlias = csr?.alias
        newMessage.senderPic = csr?.photoUrl
        newMessage.mediaKey = message.mediaKey
        newMessage.mediaType = message.mediaType
        newMessage.mediaToken = message.mediaToken
        newMessage.amount = NSDecimalNumber(value: amount)
        managedContext.saveContext()
        
        UserData.sharedInstance.setLastMessageIndex(index: index)
        
        
        NotificationCenter.default.post(name: .newOnionMessageWasReceived,object:nil, userInfo: ["message": newMessage])
    }
    
    
    func processIncomingPayment(
        message:PlaintextOrAttachmentMessageFromServer,
        date:Date,
        csr:ContactServerResponse?=nil,
        amount:Int,
        type:Int
    ){
        processIncomingPlaintextOrAttachmentMessage(message: message, date: date,csr: csr,amount: amount,type: type)
    }
    
    func processIncomingDeletion(message:PlaintextOrAttachmentMessageFromServer, date:Date){
        if let messageToDeleteUUID = message.replyUuid,
           let messageToDelete = TransactionMessage.getMessageWith(uuid: messageToDeleteUUID){
            messageToDelete.status = TransactionMessage.TransactionMessageStatus.deleted.rawValue
            if let context = messageToDelete.managedObjectContext{
                context.saveContext()
            }
        }
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
    )->TransactionMessage?{
        
        guard let muid = file["muid"] as? String,
            let chat = chat,
            let mk = attachmentObject.mediaKey,
            let destinationPubkey = getDestinationPubkey(for: chat)
            else{
                return nil
            }
        
        let (_,mediaType) = attachmentObject.getFileAndMime()
        
        //Create JSON object and push through onion network
        var recipContact : UserContact? = nil
        if let recipPubkey = attachmentObject.contactPubkey,
           let contact = UserContact.getContactWithDisregardStatus(pubkey: recipPubkey){
            recipContact = contact
        }
        
        let type = (attachmentObject.paidMessage != nil) ? (TransactionMessage.TransactionMessageType.purchase.rawValue) : (TransactionMessage.TransactionMessageType.attachment.rawValue)
        
        if let sentMessage = self.sendMessage(
            to: recipContact,
            content: attachmentObject.text ?? "",
            chat: chat,
            msgType: UInt8(type),
            muid: muid,
            recipPubkey: destinationPubkey,
            mediaKey: mk,
            mediaType: mediaType,
            threadUUID:threadUUID,
            replyUUID: replyingMessage?.uuid
        ){
            if(type == TransactionMessage.TransactionMessageType.attachment.rawValue){
                AttachmentsManager.sharedInstance.cacheImageAndMediaData(message: sentMessage, attachmentObject: attachmentObject)
            }
            else if (type == TransactionMessage.TransactionMessageType.purchase.rawValue){
                print(sentMessage)
            }
            
            return sentMessage
        }
        
        return nil
    }
    
    //MARK: Payments related
    func sendBoostReply(
        params: [String: AnyObject],
        chat:Chat
    )->TransactionMessage?{
        let contact = chat.getContact()
        
        guard let replyUUID = params["reply_uuid"] as? String,
        let text = params["text"] as? String,
        let amount = params["amount"] as? Int else{
            return nil
        }
        if let sentMessage = self.sendMessage(to: contact, content: text, chat: chat,amount: amount, msgType: UInt8(TransactionMessage.TransactionMessageType.boost.rawValue), threadUUID: nil, replyUUID: replyUUID){
            print(sentMessage)
            return sentMessage
        }
        return nil
    }
    
    func sendDirectPaymentMessage(
        params:[String:Any],
        chat:Chat,
        image:UIImage,
        completion: @escaping (Bool)->()
    ){
        guard let contact = chat.getContact(),
        let amount = params["amount"] as? Int,
        let muid = params["muid"] as? String,
        let data = image.pngData() else{
            completion(false)
            return
        }
        
        if let _ = self.sendMessage(to: contact, content: "",
                               chat: chat,
                               amount: amount,
                               msgType: UInt8(TransactionMessage.TransactionMessageType.directPayment.rawValue),
                               muid: muid,
                               threadUUID: nil,
                               replyUUID: nil
        ){
            completion(true)
        }
        else{
            completion(false)
        }
    }
    
    func sendDeleteRequest(message:TransactionMessage){
        guard let chat = message.chat else{
            return
        }
        let contact = chat.getContact()
        let pubkey = getDestinationPubkey(for: chat)
        if let deletedMessage = sendMessage(to: contact, content: "", chat: chat, msgType: UInt8(TransactionMessage.TransactionMessageType.delete.rawValue),recipPubkey: pubkey, threadUUID: nil, replyUUID: message.uuid){
            
        }
        else{
            
        }
    }
    
    func getDestinationPubkey(for chat:Chat)->String?{
        return chat.getContact()?.publicKey ?? chat.ownerPubkey ?? nil
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
