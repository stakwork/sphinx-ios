//
//  Lightning
//
//  Created by Tomas Timinskas on 14/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreData

public final class ContactsService {

    public var contacts = [UserContact]()
    public var chats = [Chat]()
    public var chatListObjects = [ChatListCommonObject]()
    public var chatsCount = 0
    public var subscriptions = [Subscription]()

    init() {
        reload()
    }

    public func reload() {
        updateContacts()
        updateChats()
        updateSubscriptions()
    }

    public func updateContacts() {
        let contactIds = ((Chat.getAllConversations().map { $0.contactIds }).flatMap { $0 }).map { $0.intValue }
        self.contacts = UserContact.getAllExcluding(ids: contactIds)
    }

    public func updateChats() {
        self.chats = Chat.getAll()
    }

    public func updateSubscriptions() {
        self.subscriptions = Subscription.getAll()
    }

    public func insertObjects(contacts: [JSON], chats: [JSON], subscriptions: [JSON], invites: [JSON]) {
        insertContacts(contacts: contacts)
        insertChats(chats: chats)
        insertSubscriptions(subscriptions: subscriptions)
        insertInvites(invites: invites)
    }
    
    public func insertInvites(invites: [JSON]) {
        if invites.count > 0 {
            
            for invite: JSON in invites {
                let _ = UserInvite.insertInvite(invite: invite)
            }
        }
    }
    
    public func insertContacts(contacts: [JSON]) {
        if contacts.count > 0 {
            for contact: JSON in contacts {
                if let id = contact.getJSONId(), contact["deleted"].boolValue || contact["from_group"].boolValue {
                    if let contact = UserContact.getContactWith(id: id) {
                        CoreDataManager.sharedManager.deleteContactObjectsFor(contact)
                    }
                } else {
                    let _ = UserContact.insertContact(contact: contact)
                }
            }
        }
    }

    public func insertContact(contact: JSON, pin: String? = nil) -> UserContact? {
        let c = UserContact.insertContact(contact: contact)
        c?.pin = pin
        return c
    }

    func removeDeletedContacts(existingContactIds: [Int]) {
        let contactsToDelete = UserContact.getAllExcluding(ids: existingContactIds)
        for contact in contactsToDelete {
            if !contact.isOwner {
                CoreDataManager.sharedManager.deleteContactObjectsFor(contact)
            }
        }
    }
    
    public func insertChats(chats: [JSON]) {
        if chats.count > 0 {
            for chat: JSON in chats {
                if let id = chat.getJSONId(), chat["deleted"].boolValue {
                    if let chat = Chat.getChatWith(id: id) {
                        CoreDataManager.sharedManager.deleteChatObjectsFor(chat)
                    }
                } else {
                    if let chat = Chat.insertChat(chat: chat) {
                        if chat.seen {
                            chat.setChatMessagesAsSeen(shouldSync: false, shouldSave: false)
                        }
                    }
                }
            }
        }
    }

    public func insertSubscriptions(subscriptions: [JSON]) {
        if subscriptions.count > 0 {
            for subscription: JSON in subscriptions {
                let _ = Subscription.insertSubscription(subscription: subscription)
            }
        }
    }

    public func getChatListObjects() -> [ChatListCommonObject] {
        let filteredContacts =  contacts.filter { !$0.isOwner && !$0.shouldBeExcluded() && !$0.isBlocked()}
        
        let filteredChats =  chats.filter {
            let isConversation = $0.isConversation()
            
            if (!isConversation) {
                return true
            }
            
            let chatContact = $0.getContact()

            return (chatContact != nil) && !(chatContact?.isBlocked() ?? false)
        }

        chatsCount = filteredChats.count

        let chatsWithLastMessages = filteredChats.map{ (chat) -> Chat in
            chat.updateLastMessage()
            return chat
        }

        var allObject: [ChatListCommonObject] = []
        allObject.append(contentsOf: filteredContacts)  
        allObject.append(contentsOf: chatsWithLastMessages)

        chatListObjects = orderChatListObjects(objects: allObject)
        return chatListObjects
    }


    func orderChatListObjects(objects: [ChatListCommonObject]) -> [ChatListCommonObject] {
        let orderedObjects = objects.sorted(by: {
            let contact1 = $0 as ChatListCommonObject
            let contact2 = $1 as ChatListCommonObject

            if contact1.isPending() || contact2.isPending() {
                return $0.isPending() && !$1.isPending()
            }

            if let contact1Date = contact1.getOrderDate() {
                if let contact2Date = contact2.getOrderDate() {
                    return contact1Date > contact2Date
                }
                return true
            } else if let _ = contact2.getOrderDate() {
                return false
            }

            return contact1.getName().lowercased() < contact2.getName().lowercased()
        })
        return orderedObjects
    }


    public func updateProfileImage(userId: Int, profilePicture: String){
        if let contact = UserContact.getContactWith(id: userId) {
            contact.avatarUrl = profilePicture
        }
    }


    public func getObjectsWith(
        searchString: String
    ) -> [ChatListCommonObject] {
        var allChatListObject = getChatListObjects()

        if searchString != "" {
            allChatListObject =  allChatListObject.filter {
                $0.getName().lowercased().contains(searchString.lowercased())
            }
        }
        return allChatListObject
    }


    public func getChatsWith(
        searchString: String
    ) -> [Chat] {
        guard searchString != "" else {
            return getChatListObjects().compactMap { $0 as? Chat }
        }

        return getChatListObjects()
            .filter {
                $0.getName().lowercased().contains(searchString.lowercased())
            }
            .compactMap {
                $0 as? Chat
            }
    }


    public func updateContact(contact: UserContact?, nickname: String? = nil, routeHint: String? = nil, contactKey: String? = nil, callback: @escaping (Bool) -> ()) {
        guard let contact = contact else {
            return
        }

        var parameters: [String : AnyObject] = [:]

        if let nickname = nickname {
            parameters["alias"] = nickname as AnyObject
        }

        if let routeHint = routeHint {
            parameters["route_hint"] = routeHint as AnyObject
        }

        if let contactKey = contactKey {
            parameters["contact_key"] = contactKey as AnyObject
        }

        API.sharedInstance.updateUser(id: contact.id, params: parameters, callback: { contact in
            DispatchQueue.main.async {
                let _ = self.insertContact(contact: contact)
                callback(true)
            }
        }, errorCallback: {
            callback(false)
        })
    }

    public func createContact(nickname: String,
                              pubKey: String,
                              routeHint: String? = nil,
                              photoUrl: String? = nil,
                              pin: String? = nil,
                              contactKey: String? = nil,
                              callback: @escaping (Bool, UserContact?) -> ()) {

        var parameters = [String : AnyObject]()
        parameters["alias"] = nickname as AnyObject
        parameters["public_key"] = pubKey as AnyObject
        parameters["status"] = UserContact.Status.Confirmed.rawValue as AnyObject

        if let photoUrl = photoUrl {
            parameters["photo_url"] = photoUrl as AnyObject
        }

        if let routeHint = routeHint {
            parameters["route_hint"] = routeHint as AnyObject
        }

        if let contactKey = contactKey {
            parameters["contact_key"] = contactKey as AnyObject
        }

        API.sharedInstance.createContact(params: parameters, callback: { contact in
            let c = self.insertContact(contact: contact, pin: pin)
            callback(true, c)
        }, errorCallback: {
            callback(false, nil)
        })
    }

    public func exchangeKeys(id: Int) {
        API.sharedInstance.exchangeKeys(id: id, callback: { _ in }, errorCallback: {})
    }

    public func reloadSubscriptions(contact: UserContact, callback: @escaping (Bool) -> ()) {
        API.sharedInstance.getSubscriptionsFor(contact: contact, callback: { subscriptions in
            self.insertSubscriptions(subscriptions: subscriptions)
            callback(true)
        }, errorCallback: {
            callback(false)
        })
    }
}
