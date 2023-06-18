//
//  Lightning
//
//  Created by Tomas Timinskas on 14/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreData

class ContactsService: NSObject {
    
    class var sharedInstance : ContactsService {
        struct Static {
            static let instance = ContactsService()
        }
        return Static.instance
    }
    
    var owner: UserContact!

    var contacts = [UserContact]()
    var chats = [Chat]()
    var subscriptions = [Subscription]()
    
    var chatListObjects = [ChatListCommonObject]()
    var contactListObjects = [ChatListCommonObject]()
    
    var contactsHasNewMessages = false
    var chatsHasNewMessages = false
    
    var contactsSearchQuery: String = ""
    var chatsSearchQuery: String = ""
    
    var contactsResultsController: NSFetchedResultsController<UserContact>!
    var chatsResultsController: NSFetchedResultsController<Chat>!

    override init() {
        super.init()
        
        updateOwner()
        configureFetchResultsController()
    }
    
    func isRestoring() -> Bool {
        return API.sharedInstance.lastSeenMessagesDate == nil
    }
    
    func configureFetchResultsController() {
        if let _ = chatsResultsController, let _ = contactsResultsController {
            return
        }
        
        if isRestoring() {
            return
        }
        
        updateLastMessages()
        
        ///Chats results controller
        let chatsFetchRequest = Chat.FetchRequests.all()

        chatsResultsController = NSFetchedResultsController(
            fetchRequest: chatsFetchRequest,
            managedObjectContext: CoreDataManager.sharedManager.persistentContainer.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        chatsResultsController.delegate = self
        
        do {
            try chatsResultsController.performFetch()
        } catch {}
        
        ///Contacts results controller
        let contactsFetchRequest = UserContact.FetchRequests.chatList()

        contactsResultsController = NSFetchedResultsController(
            fetchRequest: contactsFetchRequest,
            managedObjectContext: CoreDataManager.sharedManager.persistentContainer.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        contactsResultsController.delegate = self
        
        do {
            try contactsResultsController.performFetch()
        } catch {}
    }

    func updateSubscriptions() {
        self.subscriptions = Subscription.getAll()
    }
}

extension ContactsService : NSFetchedResultsControllerDelegate {
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        if
            let resultController = controller as? NSFetchedResultsController<NSManagedObject>,
            let firstSection = resultController.sections?.first {
            
            if let contacts = firstSection.objects as? [UserContact] {
                self.contacts = contacts
            }
            
            if let chats = firstSection.objects as? [Chat] {
                self.chats = chats
            }
        
            processContactsAndChats()
        }
    }
    
    func forceUpdate() {
        self.contacts = UserContact.chatList()
        self.chats = Chat.getAll()
        
        processContactsAndChats()
    }
    
    func updateOwner() {
        if owner == nil {
            owner = UserContact.getOwner()
        }
    }
    
    func processContactsAndChats() {
        updateOwner()
        
        if chats.count > 0 || contacts.count > 0 {
            let blockedContactIds = self.contacts.filter({ $0.isBlocked() }).map({ $0.id })
            self.chats = self.chats.filter({ !$0.isConversation() || !$0.contactIds.map({ $0.intValue }).contains(where: blockedContactIds.contains) })
            
            let conversations = chats.filter({ $0.isConversation() })
            let contactIds = ((conversations.map { $0.contactIds }).flatMap { $0 }).map { $0.intValue }
            self.contacts = self.contacts.filter({ !contactIds.contains($0.id) && !$0.isExpiredInvite() && !$0.isBlocked() })
        }
        
        processChatListObjects()
    }
    
    public func getChatListObjects() -> [ChatListCommonObject] {
        return chatListObjects
    }
    
    func calculateBadges() {
        for chat in self.chats {
            chat.calculateBadge()
        }
    }
    
    func updateLastMessages() {
        for chat in Chat.getAll() {
            chat.updateLastMessage()
        }
    }
    
    public func processChatListObjects() {
        calculateBadges()
        
        var allObject: [ChatListCommonObject] = []
        allObject.append(contentsOf: self.contacts)
        allObject.append(contentsOf: self.chats)

        let allObjects = orderChatListObjects(objects: allObject)
        
        if chatsSearchQuery.isNotEmpty {
            chatListObjects = allObjects.filter {
                $0.isPublicGroup() &&
                $0.getName().lowercased().contains(chatsSearchQuery.lowercased())
            }
        } else {
            chatListObjects = allObjects.filter {
                $0.isPublicGroup()
            }
            
            chatsHasNewMessages = false
            
            for chat in chatListObjects {
                if !chat.isSeen(ownerId: owner.id) {
                    chatsHasNewMessages = true
                    break
                }
            }
        }
        
        if contactsSearchQuery.isNotEmpty {
            contactListObjects = allObjects.filter {
                $0.isConversation() &&
                $0.getName().lowercased().contains(contactsSearchQuery.lowercased())
            }
        } else {
            contactListObjects = allObjects.filter { $0.isConversation() }
            
            contactsHasNewMessages = false
            
            for contact in contactListObjects {
                if !contact.isSeen(ownerId: owner.id) {
                    contactsHasNewMessages = true
                    break
                }
            }
        }
        
        NotificationCenter.default.post(name: .onContactsAndChatsChanged, object: nil)
    }

    func orderChatListObjects(
        objects: [ChatListCommonObject]
    ) -> [ChatListCommonObject] {
        
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
    
    func resetSearches() {
        contactsSearchQuery = ""
        chatsSearchQuery = ""
        
        processChatListObjects()
    }
    
    func updateContactsSearchQuery(term: String) {
        contactsSearchQuery = term
        
        processChatListObjects()
    }
    
    func updateChatsSearchQuery(term: String) {
        chatsSearchQuery = term
        
        processChatListObjects()
    }
}
