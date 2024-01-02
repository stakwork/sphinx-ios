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
    
    func formatMsg(content:String)->String?{
        let msg : [String:Any] = [
            "content":content
        ]
        
        guard let contentData = try? JSONSerialization.data(withJSONObject: msg),
              let contentJSONString = String(data: contentData, encoding: .utf8)
               else{
            return nil
        }
        
        return contentJSONString
    }
    
    func sendMessage(to recipContact: UserContact, content:String, shouldSendAsKeysend:Bool = false)->SphinxMsgError?{
        guard let seed = getAccountSeed() else{
            return SphinxMsgError.credentialsError
        }
        
        guard let selfContact = UserContact.getSelfContact(),
              let nickname = selfContact.nickname,
              let recipPubkey = recipContact.publicKey,
            let contentJSONString = formatMsg(content: content) else{
            return SphinxMsgError.contactDataError
        }
        
        let msg_type = UInt8(SphinxMsgTypes.PlaintextMessage.rawValue)
        let myImg = selfContact.avatarUrl ?? ""
        
        
        
        do{
            let rr = try send(seed: seed, uniqueTime: getEntropyString(), to: recipPubkey, msgType: msg_type, msgJson: contentJSONString, state: loadOnionStateAsData(), myAlias: nickname, myImg: myImg, amtMsat: 0)
            handleRunReturn(rr: rr)
        }
        catch{
            
        }

        return nil
    }
    
    func processPlaintextMessage(message:PlaintextMessageFromServer){
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
        newMessage.type = TransactionMessage.TransactionMessageType.message.rawValue
        newMessage.encrypted = true
        newMessage.senderId = contact.id
        newMessage.receiverId = UserContact.getSelfContact()?.id ?? 0
        newMessage.push = true
        newMessage.seen = false
        newMessage.messageContent = content
        newMessage.chat = chat
        managedContext.saveContext()
        
        UserData.sharedInstance.setLastMessageIndex(index: index)
    }
    
    
    func signChallenge(challenge: String)->String? {
        guard let seed = self.getAccountSeed() else{
            return nil
        }
        do {
            let msg : [String:Any] = [
                "content":challenge
            ]
            
            guard let contentData = try? JSONSerialization.data(withJSONObject: msg),
                  let contentJSONString = String(data: contentData, encoding: .utf8)
                   else{
                return nil
            }
            
            let result = try signBytes(seed: seed, idx: 0, time: getEntropyString(), network: network, msg: contentData)
            return result
        }
        catch{
            return nil
        }
    }

}
