//
//  Chat+CoreDataClass.swift
//
//
//  Created by Tomas Timinskas on 06/11/2019.
//
//

import Foundation
import CoreData
import SwiftyJSON

@objc(Chat)
public class Chat: NSManagedObject {
    
    public enum ChatType: Int {
        case conversation = 0
        case privateGroup = 1
        case publicGroup = 2
        
        public init(fromRawValue: Int){
            self = ChatType(rawValue: fromRawValue) ?? .conversation
        }
    }
    
    public enum ChatStatus: Int {
        case approved = 0
        case pending = 1
        case rejected = 2
        
        public init(fromRawValue: Int){
            self = ChatStatus(rawValue: fromRawValue) ?? .approved
        }
    }
    
    public var lastMessage : TransactionMessage? = nil
    public var conversationContact : UserContact? = nil
    
    var ongoingMessage : String? = nil
    var image : UIImage? = nil
    var tribesInfo: GroupsManager.TribeInfo? = nil
    
    var podcastPlayer: PodcastPlayerHelper? = nil
    
    func getPodcastPlayer() -> PodcastPlayerHelper {
        if podcastPlayer == nil {
            podcastPlayer = PodcastPlayerHelper()
        }
        return podcastPlayer!
    }
    
    static func getChatInstance(id: Int, managedContext: NSManagedObjectContext) -> Chat {
        if let ch = Chat.getChatWith(id: id) {
            return ch
        } else {
            return Chat(context: managedContext) as Chat
        }
    }
    
    static func insertChat(chat: JSON) -> Chat? {
        if let id = getChatId(chat: chat) {
            let name = chat["name"].string ?? ""
            let photoUrl = chat["photo_url"].string ?? ""
            let uuid = chat["uuid"].stringValue
            let type = chat["type"].intValue
            let muted = chat["is_muted"].boolValue
            let seen = chat["seen"].boolValue
            let unlisted = chat["unlisted"].boolValue
            let privateTribe = chat["private"].boolValue
            let host = chat["host"].stringValue
            let groupKey = chat["group_key"].stringValue
            let ownerPubkey = chat["owner_pubkey"].stringValue
            let status = chat["status"].intValue
            let pricePerMessage = chat["price_per_message"].intValue
            let escrowAmount = chat["escrow_amount"].intValue
            let myAlias = chat["my_alias"].string
            let myPhotoUrl = chat["my_photo_url"].string
            let metaData = chat["meta"].string
            let date = Date.getDateFromString(dateString: chat["created_at"].stringValue) ?? Date()
            
            let contactIds = chat["contact_ids"].arrayObject as? [NSNumber] ?? []
            let pendingContactIds = chat["pending_contact_ids"].arrayObject as? [NSNumber] ?? []
            
            let chat = Chat.createObject(id: id,
                                         name: name,
                                         photoUrl: photoUrl,
                                         uuid: uuid,
                                         type: type,
                                         status: status,
                                         muted: muted,
                                         seen: seen,
                                         unlisted: unlisted,
                                         privateTribe: privateTribe,
                                         host: host,
                                         groupKey: groupKey,
                                         ownerPubkey:ownerPubkey,
                                         pricePerMessage: pricePerMessage,
                                         escrowAmount: escrowAmount,
                                         myAlias: myAlias,
                                         myPhotoUrl: myPhotoUrl,
                                         contactIds: contactIds,
                                         pendingContactIds: pendingContactIds,
                                         date: date,
                                         metaData: metaData)
            
            return chat
        }
        return nil
    }
    
    static func getChatId(chat: JSON) -> Int? {
        var id : Int?
        if let idInt = chat["id"].int {
            id = idInt
        } else if let idString = chat["id"].string, let idInt = Int(idString) {
            id = idInt
        }
        return id
    }
    
    static func createObject(id: Int,
                             name: String,
                             photoUrl: String?,
                             uuid: String?,
                             type: Int,
                             status: Int,
                             muted: Bool,
                             seen: Bool,
                             unlisted: Bool,
                             privateTribe: Bool,
                             host: String?,
                             groupKey: String?,
                             ownerPubkey: String?,
                             pricePerMessage: Int,
                             escrowAmount: Int,
                             myAlias: String?,
                             myPhotoUrl: String?,
                             contactIds: [NSNumber],
                             pendingContactIds: [NSNumber],
                             date: Date,
                             metaData: String?) -> Chat? {
        
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        let chat = getChatInstance(id: id, managedContext: managedContext)
        chat.id = id
        chat.name = name
        chat.photoUrl = photoUrl
        chat.uuid = uuid
        chat.type = type
        chat.status = status
        chat.muted = muted
        chat.seen = seen
        chat.unlisted = unlisted
        chat.privateTribe = privateTribe
        chat.host = host
        chat.groupKey = groupKey
        chat.ownerPubkey = ownerPubkey
        chat.createdAt = date
        chat.myAlias = myAlias
        chat.myPhotoUrl = myPhotoUrl
        chat.contactIds = contactIds
        chat.pendingContactIds = pendingContactIds
        chat.subscription = chat.getContact()?.getCurrentSubscription()
        
        chat.setMetaData(metaData)
        
        if chat.isMyPublicGroup() {
            chat.pricePerMessage = NSDecimalNumber(integerLiteral: pricePerMessage)
            chat.escrowAmount = NSDecimalNumber(integerLiteral: escrowAmount)
        }
        
        managedContext.mergePolicy = NSMergePolicy.overwrite
        
        do {
            try managedContext.save()
            return chat
        } catch let error{
            print(error)
            return nil
        }
    }
    
    func isMuted() -> Bool {
        return self.muted
    }
    
    func isStatusPending() -> Bool {
        return self.status == ChatStatus.pending.rawValue
    }
    
    func isStatusRejected() -> Bool {
        return self.status == ChatStatus.rejected.rawValue
    }
    
    func getContactIdsArray() -> [Int] {
        var ids:[Int] = []
        for contactId in self.contactIds {
            ids.append(contactId.intValue)
        }
        return ids
    }
    
    func getPendingContactIdsArray() -> [Int] {
        var ids:[Int] = []
        for contactId in self.pendingContactIds {
            ids.append(contactId.intValue)
        }
        return ids
    }
    
    static func getAll() -> [Chat] {
        var predicate: NSPredicate! = nil
        
        if GroupsPinManager.sharedInstance.isStandardPIN {
            predicate = NSPredicate(format: "pin == null")
        } else {
            let currentPin = GroupsPinManager.sharedInstance.currentPin
            predicate = NSPredicate(format: "pin = %@", currentPin)
        }
        
        let chats:[Chat] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "Chat")
        return chats
    }
    
    public static func getAllExcluding(ids: [Int]) -> [Chat] {
        var predicate: NSPredicate! = nil
        
        if GroupsPinManager.sharedInstance.isStandardPIN {
            predicate = NSPredicate(format: "NOT (id IN %@) AND pin == null", ids)
        } else {
            let currentPin = GroupsPinManager.sharedInstance.currentPin
            predicate = NSPredicate(format: "NOT (id IN %@) AND pin = %@", ids, currentPin)
        }
        
        let chats: [Chat] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "Chat")
        return chats
    }
    
    static func getAllGroups() -> [Chat] {
        var predicate: NSPredicate! = nil
        
        if GroupsPinManager.sharedInstance.isStandardPIN {
            predicate = NSPredicate(format: "type IN %@ AND pin == null", [Chat.ChatType.privateGroup.rawValue, Chat.ChatType.publicGroup.rawValue])
        } else {
            let currentPin = GroupsPinManager.sharedInstance.currentPin
            predicate = NSPredicate(format: "type IN %@ AND pin = %@", [Chat.ChatType.privateGroup.rawValue, Chat.ChatType.publicGroup.rawValue], currentPin)
        }
        
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let chats:[Chat] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "Chat")
        return chats
    }
    
    public static func getAllConversations() -> [Chat] {
        let predicate = NSPredicate(format: "type = %d", Chat.ChatType.conversation.rawValue)
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let chats:[Chat] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "Chat")
        return chats
    }
    
    public static func getPrivateChats() -> [Chat] {
        let predicate = NSPredicate(format: "pin != null")
        let chats: [Chat] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "Chat")
        return chats
    }
    
    static func getOrCreateChat(chat: JSON) -> Chat? {
        let chatId = chat["id"].intValue
        if let chat = Chat.getChatWith(id: chatId) {
            return chat
        }
        return Chat.insertChat(chat: chat)
    }
    
    static func getChatWith(id: Int) -> Chat? {
        let predicate = NSPredicate(format: "id == %d", id)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let chat:Chat? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "Chat")
        return chat
    }
    
    static func getChatWith(uuid: String) -> Chat? {
        let predicate = NSPredicate(format: "uuid == %@", uuid)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let chat: Chat? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "Chat")
        
        return chat
    }
    
    func getAllMessages(limit: Int? = 100, messagesIdsToExclude: [Int] = [], lastMessage: TransactionMessage? = nil) -> [TransactionMessage] {
        return TransactionMessage.getAllMessagesFor(chat: self, limit: limit, messagesIdsToExclude: messagesIdsToExclude, lastMessage: lastMessage)
    }
    
    func getAllMessagesCount() -> Int {
        return TransactionMessage.getAllMessagesCountFor(chat: self)
    }
    
    func getNewMessagesCount(lastMessageId: Int? = nil) -> Int {
        guard let lastMessageId = lastMessageId else {
            return 0
        }
        return TransactionMessage.getNewMessagesCountFor(chat: self, lastMessageId: lastMessageId)
    }
    
    func setChatMessagesAsSeen(shouldSync: Bool = true, shouldSave: Bool = true) {
        self.seen = true
        
        let receivedUnseenMessages = self.getReceivedUnseenMessages()
        if receivedUnseenMessages.count > 0 {
            for m in receivedUnseenMessages {
                m.seen = true
            }
        }
        
        if shouldSave {
            CoreDataManager.sharedManager.saveContext()
        }
        
        if shouldSync {
            API.sharedInstance.setChatMessagesAsSeen(chatId: self.id, callback: { _ in })
        }
    }
    
    func getGroupEncrypted(text: String) -> String {
        if let groupKey = groupKey {
            let encryptedM = EncryptionManager.sharedInstance.encryptMessage(message: text, groupKey: groupKey)
            return encryptedM.1
        }
        return text
    }
    
    func getReceivedUnseenMessages() -> [TransactionMessage] {
        let userId = UserData.sharedInstance.getUserId()
        let predicate = NSPredicate(format: "senderId != %d AND chat == %@ AND seen == %@", userId, self, NSNumber(booleanLiteral: false))
        let messages: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "TransactionMessage")
        return messages
    }
    
    func getReceivedUnseenMessagesCount() -> Int {
        let userId = UserData.sharedInstance.getUserId()
        let predicate = NSPredicate(format: "senderId != %d AND chat == %@ AND seen == %@ && chat.seen == %@", userId, self, NSNumber(booleanLiteral: false), NSNumber(booleanLiteral: false))
        let messagesCount = CoreDataManager.sharedManager.getObjectsCountOfTypeWith(predicate: predicate, entityName: "TransactionMessage")
        return messagesCount
    }
    
    func getLastMessageToShow() -> TransactionMessage? {
        let sortDescriptors = [NSSortDescriptor(key: "date", ascending: false), NSSortDescriptor(key: "id", ascending: false)]
        let predicate = NSPredicate(format: "chat == %@ AND type != %d", self, TransactionMessage.TransactionMessageType.repayment.rawValue)
        let messages: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage", fetchLimit: 1)
        return messages.first
    }
    
    public func updateLastMessage() {
        self.lastMessage = self.getLastMessageToShow()
    }
    
    func getContact() -> UserContact? {
        if self.type == Chat.ChatType.conversation.rawValue {
            let contacts = getContacts(includeOwner: false)
            return contacts.first
        }
        return nil
    }
    
    func getAdmin() -> UserContact? {
        let contacts = getContacts(includeOwner: false)
        if self.type == Chat.ChatType.publicGroup.rawValue && contacts.count > 0 {
            return contacts.first
        }
        return nil
    }
    
    func getContactForRouteCheck() -> UserContact? {
        if let contact = getContact() {
            return contact
        }
        if let admin = getAdmin() {
            return admin
        }
        return nil
    }
    
    func getContacts(includeOwner: Bool = true, ownerAtEnd: Bool = false) -> [UserContact] {
        let ids:[Int] = self.getContactIdsArray()
        let contacts: [UserContact] = UserContact.getContactsWith(ids: ids, includeOwner: includeOwner, ownerAtEnd: ownerAtEnd)
        return contacts
    }
    
    func getPendingContacts() -> [UserContact] {
        let ids:[Int] = self.getPendingContactIdsArray()
        let contacts: [UserContact] = UserContact.getContactsWith(ids: ids, includeOwner: false, ownerAtEnd: false)
        return contacts
    }
    
    func removedFromGroup() -> Bool {
        let predicate = NSPredicate(format: "chat == %@ AND type == %d", self, TransactionMessage.TransactionMessageType.groupKick.rawValue)
        let messagesCount = CoreDataManager.sharedManager.getObjectsCountOfTypeWith(predicate: predicate, entityName: "TransactionMessage")
        return messagesCount > 0
    }
    
    func isPendingMember(id: Int) -> Bool {
        return getPendingContactIdsArray().contains(id)
    }
    
    func isActiveMember(id: Int) -> Bool {
        return getContactIdsArray().contains(id)
    }
    
    func updateTribeInfo(completion: @escaping () -> ()) {
        if let host = host, let uuid = uuid, !host.isEmpty && self.isPublicGroup() {
            API.sharedInstance.getTribeInfo(host: host, uuid: uuid, callback: { chatJson in
                self.tribesInfo = GroupsManager.sharedInstance.getTribesInfoFrom(json: chatJson)
                self.updateChatFromTribesInfo()
                completion()
            }, errorCallback: {
                completion()
            })
        }
    }
    
    func getAppUrl() -> String? {
        if let tribeInfo = self.tribesInfo, let appUrl = tribeInfo.appUrl, !appUrl.isEmpty {
            return appUrl
        }
        return nil
    }
    
    func getFeedUrl() -> String? {
        if let tribeInfo = self.tribesInfo, let feedUrl = tribeInfo.feedUrl, !feedUrl.isEmpty {
            return feedUrl
        }
        return nil
    }
    
    func updateWebAppLastDate() {
        self.webAppLastDate = Date()
    }
    
    func getTribePrices() -> (Int, Int) {
        return (self.pricePerMessage?.intValue ?? 0, self.escrowAmount?.intValue ?? 0)
    }
    
    func updateChatFromTribesInfo() {
        if self.isMyPublicGroup() {
            return
        }
        
        self.escrowAmount = NSDecimalNumber(integerLiteral: self.tribesInfo?.amountToStake ?? (self.escrowAmount?.intValue ?? 0))
        self.pricePerMessage = NSDecimalNumber(integerLiteral: self.tribesInfo?.pricePerMessage ?? (self.pricePerMessage?.intValue ?? 0))
        self.name = (self.tribesInfo?.name?.isEmpty ?? true) ? self.name : self.tribesInfo!.name
        
        let tribeImage = self.tribesInfo?.img ?? self.photoUrl
        
        if self.photoUrl != tribeImage {
            self.photoUrl = tribeImage
            self.image = nil
        }
        
        self.saveChat()
        self.syncTribeWithServer()
        self.checkForDeletedTribe()
    }
    
    func checkForDeletedTribe() {
        if let tribesInfo = self.tribesInfo, tribesInfo.deleted {
            if let lastMessage = self.getAllMessages(limit: 1).last, lastMessage.type != TransactionMessage.TransactionMessageType.groupDelete.rawValue {
                AlertHelper.showAlert(title: "deleted.tribe.title".localized, message: "deleted.tribe.description".localized)
            }
        }
    }
    
    func setOngoingMessage(text: String?) {
        self.ongoingMessage = text
    }
    
    func resetOngoingMessage() {
        self.ongoingMessage = nil
    }
    
    func shouldShowPrice() -> Bool {
        return (pricePerMessage?.intValue ?? 0) > 0
    }
    
    func setMetaData(_ meta: String?) {
        if let meta = meta, !meta.isEmpty {
            if (self.podcastPlayer?.isPlaying() ?? false) {
                return
            }
            
            if let data = meta.data(using: .utf8) {
                if let jsonObject = try? JSON(data: data) {
                    if let currentTime = jsonObject["ts"].int {
                        UserDefaults.standard.set(currentTime, forKey: "current-time-\(self.id)")
                    }
                    
                    if let episode = jsonObject["itemID"].int {
                        UserDefaults.standard.set(episode, forKey: "current-episode-id-\(self.id)")
                    }
                    
                    if let satsPerMinute = jsonObject["sats_per_minute"].int {
                        UserDefaults.standard.set(satsPerMinute, forKey: "podcast-sats-\(self.id)")
                    }
                    
                    if let speed = jsonObject["speed"].float {
                        UserDefaults.standard.set(speed, forKey: "player-speed-\(self.id)")
                    }
                    
                    UserDefaults.standard.synchronize()
                }
            }
        }
    }
    
    func updateMetaData() {
        let stasPerMinute = (UserDefaults.standard.value(forKey: "podcast-sats-\(self.id)") as? Int) ?? 0
        let currentTime = (UserDefaults.standard.value(forKey: "current-time-\(self.id)") as? Int) ?? 0
        let currentEpisode = ((UserDefaults.standard.value(forKey: "current-episode-id-\(self.id)") as? Int) ?? self.podcastPlayer?.currentEpisodeId) ?? -1
        let speed = ((UserDefaults.standard.value(forKey: "player-speed-\(self.id)") as? Float) ?? 0).speedDescription
        
        let params: [String: AnyObject] = ["meta" :"{\"itemID\":\(currentEpisode),\"sats_per_minute\":\(stasPerMinute),\"ts\":\(currentTime), \"speed\":\(speed)}" as AnyObject]
        API.sharedInstance.updateChat(chatId: id, params: params, callback: {}, errorCallback: {})
    }
    
    func isGroup() -> Bool {
        return type == Chat.ChatType.privateGroup.rawValue || type == Chat.ChatType.publicGroup.rawValue
    }
    
    func isPrivateGroup() -> Bool {
        return type == Chat.ChatType.privateGroup.rawValue
    }
    
    func isPublicGroup() -> Bool {
        return type == Chat.ChatType.publicGroup.rawValue
    }
    
    func isConversation() -> Bool {
        return type == Chat.ChatType.conversation.rawValue
    }
    
    func isEncrypted() -> Bool {
        if isPrivateGroup() {
            return true
        } else if isPublicGroup() {
            if let _ = groupKey {
                return true
            }
            return false
        } else if let contact = getContact() {
            return contact.hasEncryptionKey()
        }
        return false
    }
    
    func isMyPublicGroup() -> Bool {
        return isPublicGroup() && ownerPubkey == UserData.sharedInstance.getUserPubKey()
    }
    
    func savePodcastFeed(json: JSON) {
        if let strJson = json.rawString() {
            self.podcastFeed = strJson
        }
        saveChat()
    }
    
    func getPodcastFeed() -> JSON? {
        if let data = self.podcastFeed?.data(using: .utf8) {
            if let jsonObject = try? JSON(data: data) {
                return jsonObject
            }
        }
        return nil
    }
    
    func syncTribeWithServer() {
        DispatchQueue.global().async {
            let params: [String: AnyObject] = ["name" : self.name as AnyObject, "img": self.photoUrl as AnyObject]
            API.sharedInstance.editGroup(id: self.id, params: params, callback: { _ in }, errorCallback: {})
        }
    }
    
    func getJoinChatLink() -> String {
        return "sphinx.chat://?action=tribe&uuid=\(self.uuid ?? "")&host=\(self.host ?? "")"
    }
    
    func saveChat() {
        CoreDataManager.sharedManager.saveContext()
    }
}
