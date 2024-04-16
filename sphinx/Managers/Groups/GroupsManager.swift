//
//  GroupsManager.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import SwiftyJSON

class GroupsManager {

    class var sharedInstance : GroupsManager {
        struct Static {
            static let instance = GroupsManager()
        }
        return Static.instance
    }
    
    var contactIds : [Int] = []
    var name : String? = nil
    
    private var chatLastReadLookup : [Int:(Int, CGFloat)] = [:]
    
    func resetData() {
        contactIds = [Int]()
        name = nil
    }
    
    func setName(name: String) {
        self.name = name
    }
    
    func setContactIds(contactIds: [Int]) {
        self.contactIds = contactIds
    }
    
    func getGroupParams() -> (Bool, [String: AnyObject]) {
        var parameters = [String : AnyObject]()
        
        if let name = name {
            parameters["name"] = name as AnyObject
        } else {
            return (false, [:])
        }
        
        if contactIds.count > 0 {
            parameters["contact_ids"] = contactIds as AnyObject
        } else {
            return (false, [:])
        }
        
        return (true, parameters)
    }
    
    func getSelectedContacts(contacts: [UserContact]) -> [UserContact] {
        return contacts.filter { contactIds.contains($0.id) }
    }
    
    func getAddMembersParams() -> (Bool, [String: AnyObject]) {
        var parameters = [String : AnyObject]()
        
        if contactIds.count > 0 {
            parameters["contact_ids"] = contactIds as AnyObject
        } else {
            return (false, [:])
        }
        
        return (true, parameters)
    }
    
    func deleteGroup(
        chat: Chat?,
        completion: @escaping (Bool) -> ()
    ) {
        guard let chat = chat else {
            completion(false)
            return
        }
        
        API.sharedInstance.deleteGroup(id: chat.id, callback: { success in
            if success {
                CoreDataManager.sharedManager.deleteChatObjectsFor(chat)
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    
    func respondToRequest(
        message: TransactionMessage,
        action: String,
        completion: @escaping (Chat, TransactionMessage) -> (),
        errorCompletion: @escaping () -> ()
    ) {
        API.sharedInstance.requestAction(messageId: message.id, contactId: message.senderId, action: action, callback: { json in
            if let chat = Chat.insertChat(chat: json["chat"]),
                let message = TransactionMessage.insertMessage(
                    m: json["message"],
                    existingMessage: TransactionMessage.getMessageWith(id: json["message"]["id"].intValue)
                ).0 {
                
                CoreDataManager.sharedManager.saveContext()
                
                completion(chat, message)
                return
            }
            errorCompletion()
        }, errorCallback: {
            errorCompletion()
        })
    }
    
    //chat scroll retention
    func setChatLastRead(chatID: Int, tablePosition: (Int, CGFloat)){
        chatLastReadLookup[chatID] = tablePosition
    }
    
    func getChatLastRead(chatID: Int?) -> (TransactionMessage?, CGFloat)? {
        if let chatID = chatID, let result = chatLastReadLookup[chatID]{
            return (TransactionMessage.getMessageWith(id: result.0), result.1)
        }
        return nil
    }
    
    //tribes
    func goToGroupDetails(vc: UIViewController) -> Bool {
        if
            let joinTribeQuery = UserDefaults.Keys.tribeQuery.get(defaultValue: ""),
                joinTribeQuery != ""
        {
            UserDefaults.Keys.tribeQuery.removeValue()
            
            let tribeInfo = getGroupInfo(query: joinTribeQuery)
            
            if
                let uuid = tribeInfo?.uuid,
                let chat = Chat.getChatWith(uuid: uuid),
                let dashboardRootVC = vc as? DashboardRootViewController
            {
                dashboardRootVC.presentChatDetailsVC(for: chat, shouldAnimate: true)
                return true
            }
            else if let pubkey = tribeInfo?.ownerPubkey,
                    let chat = Chat.getTribeChatWithOwnerPubkey(ownerPubkey: pubkey),
                    let dashboardRootVC = vc as? DashboardRootViewController{
                dashboardRootVC.presentChatDetailsVC(for: chat, shouldAnimate: true)
                return true
            }
            
            if let delegate = vc as? NewContactVCDelegate {
                let groupDetailsVC = JoinGroupDetailsViewController
                    .instantiate(
                        qrString: joinTribeQuery,
                        delegate: delegate
                    )
                
                vc.navigationController?.present(
                    groupDetailsVC,
                    animated: true,
                    completion: nil
                )
                
                return true
            }
        }
        return false
    }
    
    var newGroupInfo = TribeInfo()
    
    func resetNewGroupInfo() {
        newGroupInfo = TribeInfo()
        newGroupInfo.tags = getGroupTags()
    }
    
    func isGroupInfoValid() -> Bool {
        let name = newGroupInfo.name ?? ""
        let description = newGroupInfo.description ?? ""
        let feedUrl = newGroupInfo.feedUrl ?? ""
        let contentType = newGroupInfo.feedContentType
        
        let contentTypeValid = feedUrl.isEmpty || (!feedUrl.isEmpty && contentType != nil)
        
        return !name.isEmpty && !description.isEmpty && contentTypeValid
    }
    
    func getGroupTags() -> [Tag] {
        let bitcoingTag = Tag(image: "bitcoinTagIcon", description: "Bitcoin")
        let lightningTag = Tag(image: "lightningTagIcon", description: "Lightning")
        let sphinxTag = Tag(image: "sphinxTagIcon", description: "Sphinx")
        let cryptoTag = Tag(image: "cryptoTagIcon", description: "Crypto")
        let techTag = Tag(image: "techTagIcon", description: "Tech")
        let altcoinsTag = Tag(image: "altcoinsTagIcon", description: "Altcoins")
        let musicTag = Tag(image: "musicTagIcon", description: "Music")
        let podcastTag = Tag(image: "podcastTagIcon", description: "Podcast")
        
        return [bitcoingTag, lightningTag, sphinxTag, cryptoTag, techTag, altcoinsTag, musicTag, podcastTag]
    }
    
    func getGroupInfo(query: String) -> TribeInfo? {
        var tribeInfo = TribeInfo()
        
        let components = query.components(separatedBy: "&")
        if components.count > 0 {
            for component in components {
                let elements = component.components(separatedBy: "=")
                if elements.count > 1 {
                    let key = elements[0]
                    let value = component.replacingOccurrences(of: "\(key)=", with: "")
                    
                    switch(key) {
                    case "uuid":
                        tribeInfo.uuid = value
                        break
                    case "host":
                        tribeInfo.host = value
                        break
                    case "pubkey":
                        tribeInfo.ownerPubkey = value
                        break
                    default:
                        break
                    }
                }
            }
        }
        
        if let _ = tribeInfo.uuid, 
            let _ = tribeInfo.host {//v1
            return tribeInfo
        }
        else if let _ = tribeInfo.ownerPubkey, 
            let _ = tribeInfo.host
        {//v2
            return tribeInfo
        }
        return nil
    }
    
    func getNewGroupParams() -> [String: AnyObject] {
        var parameters = [String : AnyObject]()
        
        parameters["owner_alias"] = (UserContact.getOwner()?.nickname ?? "anon") as AnyObject 
        parameters["name"] = (newGroupInfo.name ?? "") as AnyObject
        parameters["price_per_message"] = (newGroupInfo.pricePerMessage ?? 0) as AnyObject
        parameters["price_to_join"] = (newGroupInfo.priceToJoin ?? 0) as AnyObject
        parameters["escrow_amount"] = (newGroupInfo.amountToStake ?? 0) as AnyObject
        
        let escrowMillis = (newGroupInfo.timeToStake ?? 0).millisFromHours
        parameters["escrow_millis"] = escrowMillis as AnyObject
        
        if let img = newGroupInfo.img {
            parameters["img"] = img as AnyObject
        }
        
        if let description = newGroupInfo.description {
            parameters["description"] = description as AnyObject
        }
        
        let selectedTags = newGroupInfo.tags.filter { $0.selected }
        let tagsParams:[String] = selectedTags.map {  $0.description }
        
        parameters["tags"] = tagsParams as AnyObject
        parameters["is_tribe"] = true as AnyObject
        parameters["unlisted"] = newGroupInfo.unlisted as AnyObject
        parameters["private"] = newGroupInfo.privateTribe as AnyObject
        parameters["app_url"] = newGroupInfo.appUrl as AnyObject
        parameters["second_brain_url"] = newGroupInfo.secondBrainUrl as AnyObject
        parameters["feed_url"] = newGroupInfo.feedUrl as AnyObject
        
        if let feedContentType = newGroupInfo.feedContentType {
            parameters["feed_type"] = feedContentType.id as AnyObject
        }
        
        return parameters
    }
    
    func getParamsFrom(tribe: TribeInfo) -> [String: AnyObject] {
        var parameters = [String : AnyObject]()
        
        if let uuid = tribe.uuid, !uuid.isEmpty {
            parameters["uuid"] = uuid as AnyObject
        }
        
        if let img = tribe.img, !img.isEmpty {
            parameters["img"] = img as AnyObject
        }
        
        if let host = tribe.host, !host.isEmpty {
            parameters["host"] = host as AnyObject
        }
        
        if let groupKey = tribe.groupKey, !groupKey.isEmpty {
            parameters["group_key"] = groupKey as AnyObject
        }
        
        if let name = tribe.name, !name.isEmpty {
            parameters["name"] = name as AnyObject
        }
        
        if let ownerPubkey = tribe.ownerPubkey, !ownerPubkey.isEmpty {
            parameters["owner_pubkey"] = ownerPubkey as AnyObject
        }
        
        if let ownerAlias = tribe.ownerAlias, !ownerAlias.isEmpty {
            parameters["owner_alias"] = ownerAlias as AnyObject
        }
        
        if let ownerRouteHint = tribe.ownerRouteHint, !ownerRouteHint.isEmpty {
            parameters["owner_route_hint"] = ownerRouteHint as AnyObject
        }
        
        parameters["amount"] = (tribe.priceToJoin ?? 0) as AnyObject
        parameters["private"] = tribe.privateTribe as AnyObject
        
        return parameters
    }
    
    func update(tribeInfo: inout TribeInfo, from json: JSON) {
        tribeInfo.host = json["host"].string ?? tribeInfo.host
        tribeInfo.uuid = json["uuid"].string ?? tribeInfo.uuid
        tribeInfo.name = json["name"].string ?? tribeInfo.name
        tribeInfo.description = json["description"].string ?? tribeInfo.description
        tribeInfo.img = json["img"].string ?? tribeInfo.img
        tribeInfo.pin = json["pin"].string ?? tribeInfo.pin
        tribeInfo.groupKey = json["group_key"].string ?? tribeInfo.groupKey
        tribeInfo.ownerPubkey = json["owner_pubkey"].string ?? tribeInfo.ownerPubkey
        tribeInfo.ownerAlias = json["owner_alias"].string ?? tribeInfo.ownerAlias
        tribeInfo.priceToJoin = json["price_to_join"].int ?? tribeInfo.priceToJoin
        tribeInfo.pricePerMessage = json["price_per_message"].int ?? tribeInfo.pricePerMessage
        tribeInfo.amountToStake = json["escrow_amount"].int ?? tribeInfo.amountToStake
        tribeInfo.timeToStake = (json["escrow_millis"].int?.hoursFromMillis ?? tribeInfo.timeToStake)
        tribeInfo.unlisted = json["unlisted"].boolValue
        tribeInfo.privateTribe = json["private"].boolValue
        tribeInfo.deleted = json["deleted"].boolValue
        tribeInfo.appUrl = json["app_url"].string ?? tribeInfo.appUrl
        tribeInfo.secondBrainUrl = json["second_brain_url"].string ?? tribeInfo.secondBrainUrl
        tribeInfo.feedUrl = json["feed_url"].string ?? tribeInfo.feedUrl
        tribeInfo.feedContentType = json["feed_type"].int?.toFeedContentType ?? tribeInfo.feedContentType
        tribeInfo.ownerRouteHint = json["owner_route_hint"].string ?? json["route_hint"].string ?? tribeInfo.ownerRouteHint
        
        if let rawBadgeInput : [String] = json["badges"].rawValue as? [String] {
            tribeInfo.badgeIds = rawBadgeInput.compactMap({
                if let text = $0.split(separator: "/").last{
                    let string = String(text)
                    let value = Int(string)
                    return value
                }
                return nil
            })
        }
        
        var tags = getGroupTags()
        if let jsonTags = json["tags"].arrayObject as? [String] {
            for x in 0..<tags.count {
                var tag = tags[x]
                
                if jsonTags.contains(tag.description) {
                    tag.selected = true
                    tags[x] = tag
                }
            }
        }
        tribeInfo.tags = tags
        
        var botObjects : [Bot] = []
        if let data = json["bots"].stringValue.data(using: .utf8) {
            if let jsonObject = try? JSON(data: data) {
                if let bots = jsonObject.array {
                    for bot in bots {
                        let botObject = Bot(json: bot)
                        botObjects.append(botObject)
                    }
                }
            }
        }
        tribeInfo.bots = botObjects
    }
    
    
    func getTribesInfoFrom(json: JSON) -> TribeInfo {
        var tribeInfo = TribeInfo()
        update(tribeInfo: &tribeInfo, from: json)
        return tribeInfo
    }
    
    
    func calculateBotPrice(chat: Chat?, text: String) -> (Int, String?) {
        guard let tribeInfo = chat?.tribeInfo, text.starts(with: "/") else {
            return (0, nil)
        }
        
        var price = 0
        var failureMessage: String? = nil
    
        for b in tribeInfo.bots {
            if !text.starts(with: b.prefix) { continue }
            if b.price > 0 {
                price = b.price
            }
            
            if b.commands.count > 0 {
                let arr = text.components(separatedBy: " ")
                if arr.count < 2 { continue }
                
                for cmd in b.commands {
                    let theCommand = arr[1]
                    if cmd.command != "*" && theCommand != cmd.command { continue }
                    
                    if let cmdPrice = cmd.price, cmdPrice > 0 {
                        price = cmdPrice
                    } else if let cmdPriceIndex = cmd.priceIndex, cmdPriceIndex > 0 {
                        if arr.count - 1 < cmdPriceIndex { continue }
                        
                        if let amount = Int(arr[cmdPriceIndex]) {
                            if let cmdMinPrice = cmd.minPrice, cmdMinPrice > 0 && amount < cmdMinPrice {
                                failureMessage = "amount.too.low".localized
                                break
                            }
                            if let cmdMaxPrice = cmd.maxPrice, cmdMaxPrice > 0 && amount > cmdMaxPrice {
                                failureMessage = "amount.too.high".localized
                                break
                            }
                            price = amount
                        }
                    }
                }
            }
        }
        return (price, failureMessage)
    }
    
    func getAndJoinDefaultTribe(completion: @escaping () -> ()) {
        getDefatulTribeInfo(completion: completion)
    }
    
    func getDefatulTribeInfo(completion: @escaping () -> ()) {
        let planetTribeQuery = "sphinx.chat://?action=tribe&uuid=X3IWAiAW5vNrtOX5TLEJzqNWWr3rrUaXUwaqsfUXRMGNF7IWOHroTGbD4Gn2_rFuRZcsER0tZkrLw3sMnzj4RFAk_sx0&host=tribes.sphinx.chat"
        var tribeInfo = getGroupInfo(query: planetTribeQuery)
        
        if tribeInfo != nil {
            API.sharedInstance.getTribeInfo(host: tribeInfo?.host ?? "", uuid: tribeInfo?.uuid ?? "", callback: { groupInfo in
                self.update(tribeInfo: &tribeInfo!, from: groupInfo)
                self.joinDefaultTribe(tribeInfo: tribeInfo!, completion: completion)
            }, errorCallback: {
                completion()
            })
        } else {
            completion()
        }
    }
    
    func joinDefaultTribe(tribeInfo: TribeInfo, completion: @escaping () -> ()) {
        let params = getParamsFrom(tribe: tribeInfo)
        
        API.sharedInstance.joinTribe(params: params, callback: { chatJson in
            if let chat = Chat.insertChat(chat: chatJson) {
                chat.pricePerMessage = NSDecimalNumber(floatLiteral: Double(tribeInfo.pricePerMessage ?? 0))
                
                completion()
            } else {
                completion()
            }
        }, errorCallback: {
            completion()
        })
    }
}

extension Int {
    var toFeedContentType: FeedContentType? {
        return FeedContentType.allCases.filter { $0.id == self }.first
    }
}
