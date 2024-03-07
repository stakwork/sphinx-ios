//
//  SphinxOnionManager+TribesExtension.swift
//  sphinx
//
//  Created by James Carucci on 1/22/24.
//  Copyright © 2024 sphinx. All rights reserved.
//

import Foundation
import Foundation
import CocoaMQTT
import ObjectMapper
import SwiftyJSON

extension SphinxOnionManager{//tribes related
    
    func createTribe(params:[String:Any]){
        guard let seed = getAccountSeed() else{
            return
        }
        
        guard let tribeData = try? JSONSerialization.data(withJSONObject: params),
              let tribeJSONString = String(data: tribeData, encoding: .utf8)
               else{
            return
        }
        do{
            let rr = try! sphinx.createTribe(seed: seed, uniqueTime: getTimeWithEntropy(), state: loadOnionStateAsData(), tribeServerPubkey: tribeServerPubkey, tribeJson: tribeJSONString)
            handleRunReturn(rr: rr)
        }
        catch{
            
        }
    }
    
    func joinTribe(
        tribePubkey:String,
        routeHint:String,
        alias:String?=nil,
        isPrivate:Bool=false
    ){
        guard let seed = getAccountSeed() else{
            return
        }
        do{
            
            let rr = try! sphinx.joinTribe(seed: seed, uniqueTime: getTimeWithEntropy(), state: loadOnionStateAsData(), tribePubkey: tribePubkey, tribeRouteHint: routeHint, alias: alias ?? "test", amtMsat: 10000, isPrivate: isPrivate)
            DelayPerformedHelper.performAfterDelay(seconds: 1.0, completion: {
                self.handleRunReturn(rr: rr)
            })
            
        }
        catch{
            
        }
    }
    
    func joinInitialTribe(){
        guard let tribeURL = self.stashedInitialTribe else{
            return
        }
        API.sharedInstance.getInitialTribeInfo(
            url: tribeURL,
            useSSL: false,
            callback: {json in
                let result = json.dictionaryValue
                print(result)
                
                

                // Using SwiftyJSON's built-in methods for a safer extraction
                guard let pubkey = result["pubkey"]?.stringValue,
                      let routeHint = result["route_hint"]?.stringValue,
                      let alias = result["name"]?.stringValue,
                      let unlisted = result["unlisted"]?.stringValue,
                      let isPrivate = result["private"]?.boolValue else {
                    return
                }
                
                var chatDict : [String:Any] = [
                    "id":CrypterManager.sharedInstance.generateCryptographicallySecureRandomInt(upperBound: Int(1e5)),
                    "owner_pubkey": pubkey,
                    "name" : alias,
                    "private": isPrivate,
                    "photo_url": result["img"]?.stringValue ?? "",
                    "unlisted": unlisted
                ]
                let chatJSON = JSON(chatDict)
                
                guard let chat = Chat.insertChat(chat: chatJSON) else{
                    return
                }

                self.joinTribe(tribePubkey: pubkey, routeHint: routeHint, alias: alias, isPrivate: isPrivate)
            },
            errorCallback: {
                
            })
    }
    
    func exitTribe(tribeChat:Chat){
        self.sendMessage(
            to: nil,
            content: "",
            chat: tribeChat,
            msgType: UInt8(TransactionMessage.TransactionMessageType.groupLeave.rawValue),
            threadUUID: nil,
            replyUUID: nil
        )
    }
    
    func getTribeMembers(
        tribeChat:Chat,
        completion: (([String:AnyObject]) ->())?
    ){
        guard let seed = getAccountSeed() else{
            return
        }
        do{
            let rr = try! listTribeMembers(seed: seed, uniqueTime: getTimeWithEntropy(), state: loadOnionStateAsData(), tribeServerPubkey: tribeServerPubkey, tribePubkey: tribeChat.ownerPubkey ?? "")
            stashedCallback = completion
            handleRunReturn(rr: rr)
        }
        catch{
            
        }
    }
    
    func kickTribeMember(pubkey:String, chat:Chat){
        do{
            sendMessage(to: nil, content: pubkey, chat: chat, msgType: UInt8(TransactionMessage.TransactionMessageType.groupKick.rawValue), recipPubkey: tribeServerPubkey, threadUUID: nil, replyUUID: nil)
        }
        catch{
            
        }
    }
    
    func approveOrRejectTribeJoinRequest(
        requestUuid:String,
        chat: Chat,
        type: TransactionMessage.TransactionMessageType
    ){
        if (type.rawValue == TransactionMessage.TransactionMessageType.memberApprove.rawValue ||
            type.rawValue == TransactionMessage.TransactionMessageType.memberReject.rawValue) == false{
            return
        }
        sendMessage(to: nil, content: "", chat: chat, msgType: UInt8(type.rawValue), recipPubkey: tribeServerPubkey, threadUUID: nil, replyUUID: requestUuid)
    }
    
    
    
    func deleteTribe(tribeChat:Chat){
        do{
            sendMessage(to: nil, content: "", chat: tribeChat, msgType: UInt8(TransactionMessage.TransactionMessageType.groupDelete.rawValue), recipPubkey: tribeServerPubkey, threadUUID: nil, replyUUID: nil)
        }
        catch{
            
        }
    }
    
    
}
