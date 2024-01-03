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
    
    

    func signChallenge(challenge: String) -> String? {
        guard let seed = self.getAccountSeed() else {
            return nil
        }
        
        do {
            let msg: [String: Any] = [
                "content": challenge
            ]
            
            guard let challengeData = Data(base64Encoded: challenge) else {
                return nil
            }
            
            let resultHex = try signBytes(seed: seed, idx: 0, time: getEntropyString(), network: network, msg: challengeData)
            
            // Convert the hex string to binary data
            if let resultData = Data(hexString: resultHex) {
                let base64URLString = resultData.base64EncodedString(options: .init(rawValue: 0))
                    .replacingOccurrences(of: "/", with: "_")
                    .replacingOccurrences(of: "+", with: "-")
                
                // Now, 'base64URLString' contains the URL-safe Base64 string without padding
                print(base64URLString)
                return base64URLString
            } else {
                // Handle the case where hex to data conversion failed
                return nil
            }
        } catch {
            return nil
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
