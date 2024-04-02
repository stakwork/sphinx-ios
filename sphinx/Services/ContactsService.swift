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

    var allContacts = [UserContact]()
    var contacts = [UserContact]()
    var chats = [Chat]()
    var subscriptions = [Subscription]()
    
    var chatListObjects = [ChatListCommonObject]()
    var contactListObjects = [ChatListCommonObject]()
    
    var contactsHasNewMessages = false
    var chatsHasNewMessages = false
    
    var contactsSearchQuery: String = ""
    var chatsSearchQuery: String = ""
    
    var ownerResultsController: NSFetchedResultsController<UserContact>!
    var contactsResultsController: NSFetchedResultsController<UserContact>!
    var chatsResultsController: NSFetchedResultsController<Chat>!
    
    var didCollectContacts = false
    var didCollectChats = false

    override init() {
        super.init()
        
        configureOwnerFetchResultsController()
        configureFetchResultsController()
    }
    
    func isRestoring() -> Bool {
        return UserData.sharedInstance.getLastMessageIndex() == nil
    }
    
    func reset() {
        contacts = []
        allContacts = []
        chats = []
        
        contactsResultsController?.delegate = nil
        contactsResultsController = nil
        
        chatsResultsController?.delegate = nil
        chatsResultsController = nil
    }
    
    func configureOwnerFetchResultsController() {
        if let _ = ownerResultsController {
            return
        }
        
        let ownerFetchRequest = UserContact.FetchRequests.owner()

        ownerResultsController = NSFetchedResultsController(
            fetchRequest: ownerFetchRequest,
            managedObjectContext: CoreDataManager.sharedManager.persistentContainer.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        ownerResultsController.delegate = self
        
        do {
            try ownerResultsController.performFetch()
        } catch {
            print("fetch owner failed")
        }
    }
    
    func configureFetchResultsController() {
        if let _ = chatsResultsController, let _ = contactsResultsController {
            return
        }
        
        updateLastMessages()
        
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
            
            if resultController == ownerResultsController {
                self.owner = firstSection.objects?.first as? UserContact
                return
            }
            
            if resultController == contactsResultsController {
                didCollectContacts = true
            } else if resultController == chatsResultsController {
                didCollectChats = true
            }
            
            if let contacts = firstSection.objects as? [UserContact] {
                self.allContacts = contacts
            }
            
            if let chats = firstSection.objects as? [Chat] {
                self.chats = chats
            }
        
            if didCollectChats && didCollectContacts {
                processContactsAndChats()
            }
        }
    }
    
    func forceUpdate() {
        self.contacts = UserContact.chatList()
        self.chats = Chat.getAll()
        
        processContactsAndChats()
    }
    
    func updateOwner() {
        if owner == nil || owner.isFault{
            owner = UserContact.getOwner()
        }
    }
    
    func processContactsAndChats() {
        updateOwner()
        
        guard let owner = owner else {
            return
        }
        
        for chat in chats {
            if chat.isConversation() {
                if let contactId = chat.contactIds.filter({ $0.intValue != owner.id }).first?.intValue {
                    chat.conversationContact = getContactWith(id: contactId)
                }
            }
        }
        
        if chats.count > 0 || allContacts.count > 0 {
            let blockedContactIds = self.allContacts.filter({ $0.isBlocked() }).map({ $0.id })
            self.chats = self.chats.filter({ !$0.isConversation() || !$0.contactIds.map({ $0.intValue }).contains(where: blockedContactIds.contains) })
            
            let conversations = chats.filter({ $0.isConversation() })
            let contactIds = ((conversations.map { $0.contactIds }).flatMap { $0 }).map { $0.intValue }
            self.contacts = self.allContacts.filter({ !contactIds.contains($0.id) && !$0.isExpiredInvite() && !$0.isBlocked() })
        } else {
            self.contacts = []
        }
        
        processChatListObjects()
    }
    
    public func getChatListObjects() -> [ChatListCommonObject] {
        return chatListObjects
    }
    
    func calculateBadges() {
        let messagesCountMap = Chat.calculateUnseenMessagesCount(mentions: false)
        let mentionsCountMap = Chat.calculateUnseenMessagesCount(mentions: true)
        
        for chat in self.chats {
            chat.calculateBadgeWith(
                messagesCount: messagesCountMap[chat.id] ?? 0,
                mentionsCount: mentionsCountMap[chat.id] ?? 0
            )
        }
    }
    
    func updateLastMessages() {
        for chat in Chat.getAll() {
            chat.updateLastMessage()
        }
    }
    
    public func processChatListObjects() {
        updateOwner()
        calculateBadges()
        
        chatsHasNewMessages = false
        contactsHasNewMessages = false
        
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
            chatListObjects = allObjects.filter { $0.isPublicGroup()}
        }
        
        for chat in allObjects.filter({ $0.isPublicGroup()}) {
            if !chat.isSeen(ownerId: owner.id) {
                chatsHasNewMessages = true
                break
            }
        }
        
        if contactsSearchQuery.isNotEmpty {
            contactListObjects = allObjects.filter {
                $0.isConversation() &&
                $0.getName().lowercased().contains(contactsSearchQuery.lowercased())
            }
        } else {
            contactListObjects = allObjects.filter { $0.isConversation() }
        }
        
        for contact in allObjects.filter({ $0.isConversation() }) {
            if !contact.isSeen(ownerId: owner.id) {
                contactsHasNewMessages = true
                break
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
    
    func getContactWith(id: Int) -> UserContact? {
        return allContacts.filter({$0.id == id}).first
    }
}
