//
//  UserContact+CoreDataClass.swift
//  
//
//  Created by Tomas Timinskas on 12/09/2019.
//
//

import Foundation
import CoreData
import SwiftyJSON

@objc(UserContact)
public class UserContact: NSManagedObject {
    
    enum Status: Int {
        case Pending
        case Confirmed
    }
    
    public var lastMessage : TransactionMessage? = nil
    
    
    func getFakeChat() -> Chat {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        let chat = Chat(context: context)
        chat.name = self.getName()
        chat.id = -1
        chat.photoUrl = self.avatarUrl
        chat.type = Chat.ChatType.conversation.rawValue
        chat.status = Chat.ChatStatus.approved.rawValue
        
        return chat
    }
    
    public var image : UIImage? = nil
    
    public static var kTipAmount : Int {
        get {
            let amount = UserDefaults.Keys.meetingPmtAmount.get(defaultValue: 100)
            return amount
        }
        set {
            UserDefaults.Keys.meetingPmtAmount.set(newValue)
            updateTipAmount(amount: newValue)
        }
    }
    
    public static func getContactInstance(id: Int, managedContext: NSManagedObjectContext) -> UserContact {
        if let c = UserContact.getContactWith(id: id) {
            return c
        } else {
            return UserContact(context: managedContext) as UserContact
        }
    }
    
    public static func insertContact(contact: JSON) -> UserContact? {
        let id: Int? = contact.getJSONId()
        
        if let id = id {
            let publicKey = contact["public_key"].string ?? ""
            let nickname = contact["alias"].string
            let nodeAlias = contact["node_alias"].string
            let avatarUrl = contact["photo_url"].string
            let isOwner = contact["is_owner"].boolValue
            let fromGroup = contact["from_group"].boolValue
            let blocked = contact["blocked"].boolValue
            let status = contact["status"].intValue
            let contactKey = contact["contact_key"].string
            let notificationSound = contact["notification_sound"].string
            let privatePhoto = contact["private_photo"].boolValue
            let tipAmount = contact["tip_amount"].int
            let routeHint = contact["route_hint"].string
            let date = Date.getDateFromString(dateString: contact["created_at"].stringValue) ?? Date()
            
            var inviteString: String?
            var welcomeMessage: String?
            var inviteStatus: Int = 0
            var invitePrice:NSDecimalNumber? = nil
            
            if let invite = contact["invite"].dictionary {
                if let inviteS = invite["invite_string"]?.string {
                    inviteString = inviteS
                }
                
                if let welcomeM = invite["welcome_message"]?.string {
                    welcomeMessage = welcomeM
                }
                
                if let inviteS = invite["status"]?.intValue {
                    inviteStatus = inviteS
                }
                
                if let p = invite["price"]?.double, abs(p) > 0 {
                    invitePrice = NSDecimalNumber(value: p)
                }
            }
            
            let contact = UserContact.createObject(id: id, publicKey: publicKey, nodeAlias: nodeAlias, nickname: nickname, avatarUrl: avatarUrl, isOwner: isOwner, fromGroup: fromGroup, blocked: blocked, status: status, contactKey: contactKey, notificationSound: notificationSound, privatePhoto: privatePhoto, tipAmount: tipAmount, routeHint: routeHint, inviteString: inviteString, welcomeMessage: welcomeMessage, inviteStatus: inviteStatus, invitePrice: invitePrice, date: date)
            
            return contact
        }
        
        return nil
    }
    
    public static func createObject(id: Int,
                                    publicKey: String,
                                    nodeAlias: String?,
                                    nickname: String?,
                                    avatarUrl: String?,
                                    isOwner: Bool,
                                    fromGroup: Bool,
                                    blocked: Bool,
                                    status: Int,
                                    contactKey: String?,
                                    notificationSound: String?,
                                    privatePhoto: Bool,
                                    tipAmount: Int?,
                                    routeHint: String?,
                                    inviteString: String?,
                                    welcomeMessage: String?,
                                    inviteStatus: Int,
                                    invitePrice: NSDecimalNumber? = nil, date: Date) -> UserContact? {
        
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        var invite : UserInvite? = nil
        
        if let inviteString = inviteString {
            invite = UserInvite.getInviteInstance(inviteString: inviteString, managedContext: managedContext)
            invite?.inviteString = inviteString
            invite?.welcomeMessage = welcomeMessage
            invite?.status = inviteStatus
            invite?.price = invitePrice
        }

        let contact = getContactInstance(id: id, managedContext: managedContext)
        contact.id = id
        contact.publicKey = publicKey
        contact.nodeAlias = nodeAlias
        contact.nickname = nickname
        contact.avatarUrl = avatarUrl
        contact.isOwner = isOwner
        contact.fromGroup = fromGroup
        contact.blocked = blocked
        contact.privatePhoto = privatePhoto
        contact.status = status
        contact.contactKey = contactKey
        contact.routeHint = routeHint
        contact.notificationSound = notificationSound
        contact.invite = invite
        contact.createdAt = date
        
        if isOwner {
            if let tipAmount = tipAmount {
                contact.tipAmount = tipAmount
                UserDefaults.Keys.meetingPmtAmount.set(tipAmount)
            } else {
                let oldTipAmount = UserDefaults.Keys.meetingPmtAmount.get(defaultValue: 100)
                updateTipAmount(amount: oldTipAmount)
            }
        }
        
        return contact
    }

    public static func getAll() -> [UserContact] {
        let predicate: NSPredicate? = nil
        
//        var predicate: NSPredicate! = nil
//        
//        if GroupsPinManager.sharedInstance.isStandardPIN {
//            predicate = NSPredicate(format: "pin = nil")
//        } else {
//            let currentPin = GroupsPinManager.sharedInstance.currentPin
//            predicate = NSPredicate(format: "pin = %@", currentPin)
//        }
        
        let sortDescriptors = [NSSortDescriptor(key: "status", ascending: true), NSSortDescriptor(key: "nickname", ascending: true)]
        let contacts: [UserContact] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "UserContact")
        return contacts
    }
    
    public static func chatList() -> [UserContact] {
        let predicate: NSPredicate = UserContact.Predicates.chatList()
        let sortDescriptors = [NSSortDescriptor(key: "status", ascending: true), NSSortDescriptor(key: "nickname", ascending: true)]
        let contacts: [UserContact] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "UserContact")
        return contacts
    }
    
    public static func getAllExcluding(ids: [Int]) -> [UserContact] {
        let predicate = NSPredicate(format: "NOT (id IN %@)", ids)
        
//        var predicate: NSPredicate! = nil
//        
//        if GroupsPinManager.sharedInstance.isStandardPIN {
//            predicate = NSPredicate(format: "NOT (id IN %@) AND pin = nil", ids)
//        } else {
//            let currentPin = GroupsPinManager.sharedInstance.currentPin
//            predicate = NSPredicate(format: "NOT (id IN %@) AND pin = %@", ids, currentPin)
//        }
        
        let sortDescriptors = [NSSortDescriptor(key: "status", ascending: true), NSSortDescriptor(key: "nickname", ascending: true)]
        let contacts: [UserContact] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "UserContact")
        return contacts
    }
    
    public static func getPrivateContacts() -> [UserContact] {
        let predicate = NSPredicate(format: "pin != null")
        let contacts: [UserContact] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "UserContact")
        return contacts
    }
    
    public static func getPendingContacts() -> [UserContact] {
        let predicate = NSPredicate(format: "status == %d", UserContact.Status.Pending.rawValue)
        let contacts: [UserContact] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "UserContact")
        return contacts
    }
    
    public static func getContactsWithPin(_ pin: String) -> [UserContact] {
        let predicate = NSPredicate(format: "pin == %@", pin)
        let contacts: [UserContact] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "UserContact")
        return contacts
    }
    
    public static func deleteAll() {
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        let contacts = UserContact.getAll()
        for contact in contacts {
            managedContext.delete(contact)
        }
        CoreDataManager.sharedManager.saveContext()
    }
    
    public static func getOrCreateContact(contact: JSON) -> (UserContact?, Bool) {
        let contactId = contact["id"].intValue
        if contact["deleted"].boolValue { return (nil, false) }
        
        if let c = getContactWith(id: contactId) {
            let updated = c.updateFromGroup(contact: contact)
            return (c, updated)
        }
        return (UserContact.insertContact(contact: contact), false)
    }
    
    func updateFromGroup(contact: JSON) -> Bool {
        if self.fromGroup != contact["from_group"].boolValue {
            self.fromGroup = contact["from_group"].boolValue
            return true
        }
        return false
    }
    
    public static func getContactsWith(ids: [Int], includeOwner: Bool, ownerAtEnd: Bool) -> [UserContact] {
        var predicate: NSPredicate! = nil
        if includeOwner {
            predicate = NSPredicate(format: "id IN %@", ids)
        } else {
            predicate = NSPredicate(format: "id IN %@ AND isOwner == %@", ids, NSNumber(value: false))
        }
        let sortDescriptors = ownerAtEnd ? [NSSortDescriptor(key: "isOwner", ascending: false), NSSortDescriptor(key: "id", ascending: false)] : [NSSortDescriptor(key: "id", ascending: false)]
        let contacts: [UserContact] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "UserContact")
        return contacts
    }
    
    public static func getSelfContact()->UserContact?{
        return self.getContactWith(indices: [0]).first
    }
    
    
    public static func getContactWith(indices: [Int],
                                      managedContext: NSManagedObjectContext? = nil) -> [UserContact] {
        var predicate: NSPredicate! = nil
        predicate = NSPredicate(format: "index IN %@", indices)
        let sortDescriptors = [NSSortDescriptor(key: "index", ascending: false)]
        let contacts: [UserContact] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "UserContact",context:managedContext)
        return contacts
    }
    
    public static func getNextAvailableContactIndex() -> Int? {
        let fetchRequest: NSFetchRequest<UserContact> = UserContact.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let contacts = try CoreDataManager.sharedManager.persistentContainer.viewContext.fetch(fetchRequest)
            if let highestIndexAvailable = contacts.first as? UserContact {
                return Int(highestIndexAvailable.index) + 1
            } else {
                return 1
            }
        } catch {
            print("Error fetching contacts: \(error)")
            return nil
        }
    }
    
    public static func getContactWith(id: Int) -> UserContact? {
        let predicate = NSPredicate(format: "id == %d", id)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let contact:UserContact? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "UserContact")
        return contact
    }
    
    public static func getContactWithInvitCode(inviteCode: String,
                                      managedContext: NSManagedObjectContext? = nil) -> UserContact? {
        let predicate = NSPredicate(format: "sentInviteCode == %@", inviteCode)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let contact:UserContact? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "UserContact",managedContext: managedContext)
        return contact
    }
    
    public static func getContactWithDisregardStatus(pubkey: String,
                                      managedContext: NSManagedObjectContext? = nil) -> UserContact? {
        let predicate = NSPredicate(format: "publicKey == %@", pubkey)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let contact:UserContact? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "UserContact",managedContext: managedContext)
        return contact
    }
    
    public static func getContactWith(pubkey: String,
                                      managedContext: NSManagedObjectContext? = nil) -> UserContact? {
        let predicate = NSPredicate(format: "publicKey == %@ AND status == %d", pubkey, UserContact.Status.Confirmed.rawValue)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let contact:UserContact? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "UserContact",managedContext: managedContext)
        return contact
    }
    
    public static func getContactsWith(pubkeys: [String]) -> [UserContact] {
        var predicate = NSPredicate(format: "publicKey IN %@ AND isOwner == %@", pubkeys, NSNumber(value: false))
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        
        let contacts: [UserContact] = CoreDataManager.sharedManager.getObjectsOfTypeWith(
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            entityName: "UserContact"
        )
        
        return contacts
    }
    
    public static func getOwner() -> UserContact? {
        let predicate = NSPredicate(format: "isOwner == %@", NSNumber(value: true))
        let contact:UserContact? = CoreDataManager.sharedManager.getObjectOfTypeWith(
            predicate: predicate,
            sortDescriptors: [],
            entityName: "UserContact"
        )
        return contact
    }
    
    public static func updateOwnerAlias(newNickname:String){
        if var owner = getOwner(){
            owner.nickname = newNickname
            owner.managedObjectContext?.saveContext()
        }
    }
    
    func getAddress() -> String? {
        if let address = self.publicKey, !address.isEmpty {
            let delimiter = self.routeHint?.isV2RouteHint == false ? ":" : "_"
            let routeHint = (self.routeHint ?? "").isEmpty ? "" : "\(delimiter)\((self.routeHint ?? ""))"
            return "\(address)\(routeHint)"
        }
        return nil
    }
    
    var conversation: Chat? = nil
    
    public func getChat() -> Chat? {
        if conversation == nil {
            setContactConversation()
        }
        return conversation
    }
    
    public func setContactConversation() {
        let userId = UserData.sharedInstance.getUserId()
        let predicate = NSPredicate(format: "(contactIds == %@ OR contactIds == %@) AND type = %d", [userId, self.id], [self.id, userId], Chat.ChatType.conversation.rawValue)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        conversation = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "Chat")
    }
    
    public func getChat(chats: [Chat]) -> Chat? {
        for chat in chats {
            if chat.getContactIdsArray().contains(self.id) {
                return chat
            }
        }
        return nil
    }
    
    public func getCurrentSubscription() -> Subscription? {
        if let subsciptionsSet = self.subscriptions, let subscriptions = Array<Any>(subsciptionsSet) as? [Subscription] {
            return subscriptions.filter { !$0.ended }.first
        }
        return nil
    }
    
    public func subscribedToContact() -> Bool {
        return getCurrentSubscription() != nil
    }
    
    public func hasEncryptionKey() -> Bool {
        if let contactK = self.contactKey, let _ = EncryptionManager.sharedInstance.getPublicKeyFromBase64String(base64String: contactK) {
            return true
        }
        else if let _ = self.contactKey{
            return true
        }
        return false
    }
    
    public func isConfirmed() -> Bool {
        return self.status == UserContact.Status.Confirmed.rawValue
    }
    
    public func isPending() -> Bool {
        return self.status == UserContact.Status.Pending.rawValue
    }
    
    public func isBlocked() -> Bool {
        return self.blocked
    }
    
    public func shouldBeExcluded() -> Bool {
        if fromGroup { return true }
        
        if let invite = self.invite {
            return self.status != UserContact.Status.Confirmed.rawValue && invite.status == UserInvite.Status.Expired.rawValue
        }
        
        return false
    }
    
    func isExpiredInvite() -> Bool {
        return
            self.status != UserContact.Status.Confirmed.rawValue &&
            self.invite?.status == UserInvite.Status.Expired.rawValue
    }

    func isVirtualNode() -> Bool {
        return !(self.routeHint ?? "").isEmpty
    }
    
    public static func updateDeviceId(deviceId: String) {
        if let currentDeviceId = UserDefaults.Keys.deviceId.get(defaultValue: ""), currentDeviceId == deviceId {
            return
        }
        
        syncDeviceId(newDeviceId: deviceId)
    }
    
    public static func updateVoipDeviceId(deviceId: String) {
        if let currentVoipDeviceId = UserDefaults.Keys.voipDeviceId.get(defaultValue: ""), currentVoipDeviceId == deviceId {
            return
        }
        
        syncVoipDeviceId(pushKitToken: deviceId)
    }
    
    public static func syncDeviceId(
        newDeviceId: String? = nil
    ) {
        if let currentDeviceId = newDeviceId ?? UserDefaults.Keys.deviceId.get(), !currentDeviceId.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                SphinxOnionManager.sharedInstance.registerDeviceID(id: currentDeviceId)
            })
        }
    }
    
    public static func syncVoipDeviceId(
        pushKitToken: String? = nil
    ) {
        if let currentVoipDeviceId = pushKitToken ?? UserDefaults.Keys.voipDeviceId.get(), !currentVoipDeviceId.isEmpty {
            
            let parameters : [String: AnyObject] = ["push_kit_token" : currentVoipDeviceId as AnyObject]
            let id = UserData.sharedInstance.getUserId()

            API.sharedInstance.updateUser(id: id, params: parameters, callback: { contact in
                UserDefaults.Keys.voipDeviceId.set(contact["push_kit_token"].string)
            }, errorCallback: {
                print("Error updating device id")
            })
        }
    }
    
    public static func updateTipAmount(amount: Int) {
        let parameters : [String: AnyObject] = ["tip_amount" : amount as AnyObject]
        let id = UserData.sharedInstance.getUserId()

        if let owner = UserContact.getOwner() {
            API.sharedInstance.updateUser(id: id, params: parameters, callback: { success in
                owner.tipAmount = amount
            }, errorCallback: { })
        }
    }
}


extension NSManagedObject {
    func printAllAttributes() {
        let entity = self.entity
        let attributes = entity.attributesByName
        
        for (key, value) in attributes {
            if let attributeValue = self.value(forKey: key) {
                print("\(key): \(attributeValue) (Type: \(type(of: attributeValue)), Attribute Type: \(value.attributeType.rawValue))")
            } else {
                print("\(key): nil (Attribute Type: \(value.attributeType.rawValue))")
            }
        }
    }
}
