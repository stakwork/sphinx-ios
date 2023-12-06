//
//  UserContactService.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON

class UserContactsHelper {    
    ///Inserts
    public static func insertObjects(contacts: [JSON], chats: [JSON], subscriptions: [JSON], invites: [JSON]) {
        CoreDataManager.sharedManager.persistentContainer.viewContext.performAndWait({
            self.insertContacts(contacts: contacts)
            self.insertChats(chats: chats)
            self.insertSubscriptions(subscriptions: subscriptions)
            self.insertInvites(invites: invites)
        })        
    }
    
    public static func insertInvites(invites: [JSON]) {
        if invites.count > 0 {
            
            for invite: JSON in invites {
                let _ = UserInvite.insertInvite(invite: invite)
            }
        }
    }
    
    public static func insertContacts(contacts: [JSON]) {
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

    public static func insertContact(contact: JSON, pin: String? = nil) -> UserContact? {
        let c = UserContact.insertContact(contact: contact)
        c?.pin = pin
        return c
    }

    public static func removeDeletedContacts(existingContactIds: [Int]) {
        let contactsToDelete = UserContact.getAllExcluding(ids: existingContactIds)
        for contact in contactsToDelete {
            if !contact.isOwner {
                CoreDataManager.sharedManager.deleteContactObjectsFor(contact)
            }
        }
    }
    
    public static func insertChats(chats: [JSON]) {
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

    public static func insertSubscriptions(subscriptions: [JSON]) {
        if subscriptions.count > 0 {
            for subscription: JSON in subscriptions {
                let _ = Subscription.insertSubscription(subscription: subscription)
            }
        }
    }

    ///Updates
    public static func updateContact(
        contact: UserContact?,
        nickname: String? = nil,
        routeHint: String? = nil,
        contactKey: String? = nil,
        callback: @escaping (Bool) -> ()
    ) {
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

    public static func createContact(
        nickname: String,
        pubKey: String,
        routeHint: String? = nil,
        photoUrl: String? = nil,
        pin: String? = nil,
        contactKey: String? = nil,
        callback: @escaping (Bool, UserContact?) -> ()
    ) {

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
    
    func createV2Contact(
        nickname: String,
        pubKey: String,
        routeHint: String,
        photoUrl: String? = nil,
        pin: String? = nil,
        contactKey: String? = nil,
        callback: @escaping (Bool, UserContact?) -> ()
    ){
        //Create new contact with onion mananger
        let contactInfo = pubKey + "_" + routeHint
        SphinxOnionManager.sharedInstance.makeFriendRequest(contactInfo: contactInfo,nickname:nickname)
        
        var maxTicks = 20
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) {timer in
            if let successfulContact = UserContact.getContactWithDisregardStatus(pubkey: pubKey){
                callback(true,successfulContact)
                timer.invalidate()
            }
            else if(maxTicks >= 0){
                maxTicks -= 1
            }
            else{
                callback(false,nil)
                timer.invalidate()
            }
        }
    }

    public static func exchangeKeys(id: Int) {
        API.sharedInstance.exchangeKeys(id: id, callback: { _ in }, errorCallback: {})
    }

    public static func reloadSubscriptions(
        contact: UserContact,
        callback: @escaping (Bool) -> ()
    ) {
        API.sharedInstance.getSubscriptionsFor(contact: contact, callback: { subscriptions in
            self.insertSubscriptions(subscriptions: subscriptions)
            callback(true)
        }, errorCallback: {
            callback(false)
        })
    }
}
