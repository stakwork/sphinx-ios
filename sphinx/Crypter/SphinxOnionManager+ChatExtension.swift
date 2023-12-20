//
//  SphinxOnionManager+ChatExtension.swift
//  sphinx
//
//  Created by James Carucci on 12/4/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import CocoaMQTT

extension SphinxOnionManager{
    
    func constructMessageJSONString(recipPubkey:String,
                                        recipRouteHint:String,
                                        myOkKey:String,
                                        selfRouteHint:String,
                                        selfContact:UserContact,
                                        recipContact:UserContact,
                                        content:String)->(String,String)?{
        let serverPubkey = recipRouteHint.split(separator: "_")[0]
        let senderInfo = getSenderInfo(for: recipContact,myOkKey:myOkKey,selfRouteHint: selfRouteHint,selfContact:selfContact)
                
        guard let hopsJSONString = getHopsJSON(serverPubkey: String(serverPubkey), recipPubkey: recipPubkey) else{
            return nil
        }
        
        let msg : [String:Any] = [
            "type": SphinxMsgTypes.PlaintextMessage.rawValue,
            "sender": senderInfo,
            "message":["content":content]
        ]
        
        guard let contentData = try? JSONSerialization.data(withJSONObject: msg),
              let contentJSONString = String(data: contentData, encoding: .utf8)
               else{
            return nil
        }
        
        (shouldPostUpdates) ?  NotificationCenter.default.post(Notification(name: .keyExchangeResponseMessageWasConstructed, object: nil, userInfo: ["hopsJSON" : hopsJSONString, "contentStringJSON": senderInfo])) : ()
        
        return (contentJSONString,hopsJSONString)
    }
    
    
    func sendMessage(to recipContact: UserContact, content:String, shouldSendAsKeysend:Bool = false)->SphinxMsgError?{
        guard let seed = getAccountSeed() else{
            return SphinxMsgError.credentialsError
        }
        
        guard let selfContact = UserContact.getSelfContact(),
              let nickname = selfContact.nickname,
              let recipPubkey = recipContact.publicKey else{
            return SphinxMsgError.contactDataError
        }
        
        let msg_type = UInt8(SphinxMsgTypes.PlaintextMessage.rawValue)
        let myImg = selfContact.avatarUrl ?? ""
        
        let msg : [String:Any] = [
            "content":content
        ]
        
        guard let contentData = try? JSONSerialization.data(withJSONObject: msg),
              let contentJSONString = String(data: contentData, encoding: .utf8)
               else{
            return nil
        }
        
        do{
            let rr = try send(seed: seed, uniqueTime: getEntropyString(), to: recipPubkey, msgType: msg_type, msgJson: contentJSONString, state: loadOnionStateAsData(), myAlias: nickname, myImg: myImg, amtMsat: 0)
            handleRunReturn(rr: rr)
        }
        catch{
            
        }

        return nil
    }
}
