//
//  GroupsManager+TribesInfo.swift
//  sphinx
//
//  Created by Tomas Timinskas on 25/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON

extension GroupsManager {
    
    struct TribeInfo: Equatable {
        var name : String? = nil
        var description : String? = nil
        var img : String? = nil
        var groupKey : String? = nil
        var ownerPubkey : String? = nil
        var ownerAlias : String? = nil
        var pin : String? = nil
        var host : String! = nil
        var uuid : String! = nil
        var tags : [Tag] = []
        var priceToJoin : Int? = nil
        var pricePerMessage : Int? = nil
        var amountToStake : Int? = nil
        var timeToStake : Int? = nil
        var unlisted : Bool = false
        var privateTribe : Bool = false
        var deleted : Bool = false
        var appUrl : String? = nil
        var secondBrainUrl : String? = nil
        var feedUrl : String? = nil
        var feedContentType : FeedContentType? = nil
        var ownerRouteHint : String? = nil
        var bots : [Bot] = []
        var badgeIds: [Int] = []
        
        static func == (lhs: TribeInfo, rhs: TribeInfo) -> Bool {
            return lhs.name           == rhs.name &&
                   lhs.description    == rhs.description &&
                   lhs.uuid           == rhs.uuid &&
                   lhs.host           == rhs.host &&
                   lhs.groupKey       == rhs.groupKey
        }
        
        var hasLoopoutBot : Bool {
            get {
                for bot in bots {
                    if bot.prefix == "/loopout" {
                        return true
                    }
                }
                return false
            }
        }
        
        var isValid: Bool {
            get {
                return name != nil && description != nil && groupKey != nil
            }
        }
    }
    
    func getChatJSON(tribeInfo:TribeInfo)->JSON?{
        var chatDict : [String:Any] = [
            "id":CrypterManager.sharedInstance.generateCryptographicallySecureRandomInt(upperBound: Int(1e5)),
            "owner_pubkey": tribeInfo.ownerPubkey,
            "name" : tribeInfo.name ?? "Unknown Name",
            "private": tribeInfo.privateTribe ?? false,
            "photo_url": tribeInfo.img ?? "",
            "unlisted": tribeInfo.unlisted,
            "price_per_message": tribeInfo.pricePerMessage ?? 0,
            "escrow_amount": max(tribeInfo.amountToStake ?? 3, 3)
        ]
        let chatJSON = JSON(chatDict)
        return chatJSON
    }
    
    func getV2Pubkey(qrString:String)->String?{
        if let url = URL(string: "\(API.kHUBServerUrl)?\(qrString)"),
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems,
           let pubkey = queryItems.first(where: { $0.name == "pubkey" })?.value{
            return cleanPubKey(pubkey)
        }
        return nil
    }
    
    func getV2Host(qrString:String)->String?{
        if let url = URL(string: "\(API.kHUBServerUrl)?\(qrString)"),
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems,
           let host = queryItems.first(where: { $0.name == "host" })?.value{
            return cleanPubKey(host)
        }
        return nil
    }
    
    func cleanPubKey(_ key: String) -> String {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasSuffix("\")") {
            return String(trimmed.dropLast(2))
        } else {
            return trimmed
        }
    }
    
    func fetchTribeInfo(
        host:String,
        uuid:String,
        useSSL:Bool,
        completion: @escaping CreateGroupCallback,
        errorCallback: @escaping EmptyCallback
    ){
        API.sharedInstance.getTribeInfo(host: host, uuid: uuid, useSSL: useSSL, callback: { groupInfo in
            completion(groupInfo)
        }, errorCallback: {
            errorCallback()
        })
    }
    
    func finalizeTribeJoin(tribeInfo:TribeInfo,qrString:String){
        if let pubkey = getV2Pubkey(qrString: qrString),
           let chatJSON = getChatJSON(tribeInfo:tribeInfo),
           let routeHint = tribeInfo.ownerRouteHint,
           let chat = Chat.insertChat(chat: chatJSON){
            let isPrivate = tribeInfo.privateTribe
            SphinxOnionManager.sharedInstance.joinTribe(tribePubkey: pubkey, routeHint: routeHint, alias: UserContact.getOwner()?.nickname,isPrivate: isPrivate)
            chat.status = (isPrivate) ? Chat.ChatStatus.pending.rawValue : Chat.ChatStatus.approved.rawValue
            chat.type = Chat.ChatType.publicGroup.rawValue
            chat.managedObjectContext?.saveContext()
        }
    }
    
    func lookupAndRestoreTribe(pubkey:String, host:String,completion: @escaping (Chat?)->()){
        var tribeInfo = GroupsManager.TribeInfo(ownerPubkey:pubkey, host: host,uuid: pubkey)
        
        GroupsManager.sharedInstance.fetchTribeInfo(
            host: tribeInfo.host,
            uuid: tribeInfo.uuid,
            useSSL: false,
            completion: { groupInfo in
                //1. parse tribe info
                print(groupInfo)
                
                var chatDict : [String:Any] = [
                    "id":CrypterManager.sharedInstance.generateCryptographicallySecureRandomInt(upperBound: Int(1e5)),
                    "owner_pubkey": groupInfo["pubkey"],
                    "name" : groupInfo["name"],
                    "private": groupInfo["private"],
                    "photo_url": groupInfo["img"],
                    "unlisted": groupInfo["unlisted"],
                    "price_per_message": groupInfo["price_per_message"],
                    "escrow_amount": max(groupInfo["escrow_amount"] ?? 3, 3)
                ]
                let chatJSON = JSON(chatDict)
                //2. take the relevant information and create a chat accordingly
                let resultantChat = Chat.insertChat(chat: chatJSON)
                resultantChat?.status = (chatDict["private"] as? Bool ?? false) ? Chat.ChatStatus.pending.rawValue : Chat.ChatStatus.approved.rawValue
                resultantChat?.type = (chatDict["private"] as? Bool ?? false) ? Chat.ChatType.privateGroup.rawValue : Chat.ChatType.publicGroup.rawValue
                resultantChat?.managedObjectContext?.saveContext()
                completion(resultantChat)
                return
            },
            errorCallback: {
                AlertHelper.showAlert(title: "Error Restoring tribe", message: "")
        })
        
        completion(nil)
    }
}
