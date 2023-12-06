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
        guard let mnemonic = UserData.sharedInstance.getMnemonic(),
              let seed = getAccountSeed(mnemonic: mnemonic),
              let myOkKey = getAccountOnlyKeysendPubkey(seed: seed) else {
            return SphinxMsgError.credentialsError
        }
        guard let recipPubkey = recipContact.publicKey, // OK key
              let recipRouteHint = recipContact.contactRouteHint,
              recipRouteHint.split(separator: "_").count == 2 else {
            return SphinxMsgError.contactDataError
        }

        guard let selfContact = UserContact.getSelfContact(),
              let selfRouteHint = selfContact.routeHint else {
            return SphinxMsgError.credentialsError
        }


        let time = getEntropyString()

        let senderInfo = getSenderInfo(for: recipContact, myOkKey: myOkKey, selfRouteHint: selfRouteHint, selfContact: selfContact)


        guard let (contentJSONString,hopsJSONString) = constructMessageJSONString(recipPubkey: recipPubkey, recipRouteHint: recipRouteHint, myOkKey: myOkKey, selfRouteHint: selfRouteHint, selfContact: selfContact, recipContact: recipContact,content:content) else{
            return SphinxMsgError.contactDataError
        }
        


        do {
            let onion = try! createOnionMsg(seed: seed, idx: UInt32(0), time: time, network: network, hops: hopsJSONString, json: contentJSONString)
            var onionAsArray = [UInt8](repeating: 0, count: onion.count)

            // Use withUnsafeBytes to copy the Data into the UInt8 array
            onion.withUnsafeBytes { bufferPointer in
                guard let baseAddress = bufferPointer.baseAddress else {
                    fatalError("Failed to get the base address")
                }
                memcpy(&onionAsArray, baseAddress, onion.count)
                let topic = shouldSendAsKeysend ? "\(myOkKey)/0/req/send" : "\(recipContact.childPubKey)/\(recipContact.index)/req/send"
                self.mqtt.publish(
                    CocoaMQTTMessage(
                        topic: topic,
                        payload: onionAsArray
                    )
                )
            }

        } catch {
            return SphinxMsgError.encodingError
        }

        return nil
    }
}
