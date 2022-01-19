//
//  Library
//
//  Created by Tomas Timinskas on 18/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON

final class ChatListViewModel: NSObject {
    
    var contactsService: ContactsService!
    
    public static let kMessagesPerPage: Int = 200
    
    init(contactsService: ContactsService) {
        self.contactsService = contactsService
    }
    
    var contactChats: [ChatListCommonObject] {
        contactsService.reload()
        
        return contactsService
            .getChatListObjects()
            .filter { $0.isConversation() }
    }
    
    var tribeChats: [ChatListCommonObject] {
        contactsService.reload()
        
        return contactsService
            .getChatListObjects()
            .filter { $0.isPublicGroup() }
    }
    
    
    func contactChats(
        fromSearchQuery searchQuery: String
    ) -> [ChatListCommonObject] {
        contactsService
            .getChatListObjects()
            .filter {
                $0.isConversation() &&
                $0.getName()
                    .lowercased()
                    .starts(with: searchQuery.lowercased())
            }
    }
    
    
    func tribeChats(
        fromSearchQuery searchQuery: String
    ) -> [ChatListCommonObject] {
        contactsService
            .getChatListObjects()
            .filter {
                $0.isPublicGroup() &&
                $0.getName()
                    .lowercased()
                    .starts(with: searchQuery.lowercased())
            }
    }
    
    
    func loadFriends(
        fromPush: Bool = false,
        completion: @escaping (Bool) -> ()
    ) {
        if let contactsService = contactsService {
            
            if contactsService.chats.count == 0 {
                
                API.sharedInstance.getContacts(
                    callback: {(contacts, chats, subscriptions) -> () in
                    
                    contactsService.insertObjects(
                        contacts: contacts,
                        chats: chats,
                        subscriptions: subscriptions,
                        invites: []
                    )
                    
                    self.forceKeychainSync()
                    
                    completion(self.isRestoring())
                })
            } else {
                API.sharedInstance.getLatestContacts(
                    date: Date(),
                    callback: {(contacts, chats, subscriptions, invites) -> () in
                    
                    contactsService.insertObjects(
                        contacts: contacts,
                        chats: chats,
                        subscriptions: subscriptions,
                        invites: invites
                    )
                    
                    self.forceKeychainSync()
                    
                    completion(false)
                })
            }
            return
        }
        completion(false)
    }
    
    func getChatListObjectsCount() -> Int {
        if let contactsService = contactsService {
            return contactsService.chatListObjects.count
        }
        return 0
    }
    
    func updateContactsAndChats() {
        guard let contactsService = contactsService else {
            return
        }
        contactsService.updateContacts()
        contactsService.updateChats()
    }
    
    func forceKeychainSync() {
        UserData.sharedInstance.forcePINSyncOnKeychain()
        UserData.sharedInstance.saveNewNodeOnKeychain()
        EncryptionManager.sharedInstance.saveKeysOnKeychain()
    }
    
    func askForNotificationPermissions() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.registerForPushNotifications()
    }
    
    func isRestoring(chatId: Int? = nil) -> Bool {
        return API.sharedInstance.lastSeenMessagesDate == nil && TransactionMessage.getAllMesagesCount() == 0
    }
    
    var syncMessagesTask: DispatchWorkItem? = nil
    var syncMessagesDate = Date()
    
    func syncMessages(
        chatId: Int? = nil,
        progressCallback: @escaping (Int) -> (),
        completion: @escaping (Int, Int) -> ()
    ) {
        syncMessagesTask = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            self.syncMessagesDate = Date()
            
            let restoring = self.isRestoring()
            
            if (restoring) {
                self.askForNotificationPermissions()
                progressCallback(0)
            }
            
            
            self.getMessagesPaginated(
                restoring: restoring,
                prevPageNewMessages: 0,
                chatId: chatId,
                date: self.syncMessagesDate,
                progressCallback: progressCallback,
                completion: completion
            )
        }
        syncMessagesTask?.perform()
    }
    
    func finishRestoring() {
        syncMessagesTask?.cancel()
        
        UserDefaults.Keys.messagesFetchPage.removeValue()
        API.sharedInstance.lastSeenMessagesDate = syncMessagesDate
    }
    
    func getMessagesPaginated(
        restoring: Bool,
        prevPageNewMessages: Int,
        chatId: Int? = nil,
        date: Date,
        progressCallback: @escaping (Int) -> (),
        completion: @escaping (Int, Int) -> ()
    ) {
        let page = UserDefaults.Keys.messagesFetchPage.get(defaultValue: 1)
        
        API.sharedInstance.getMessagesPaginated(
            page: page,
            date: date,
            callback: {(newMessagesTotal, newMessages) -> () in
                
                if self.syncMessagesTask?.isCancelled == true {
                    return
                }
                
                progressCallback(
                    self.getRestoreProgress(
                        currentPage: page,
                        newMessagesTotal: newMessagesTotal,
                        itemsPerPage: ChatListViewModel.kMessagesPerPage
                    )
                )
                    
                if newMessages.count > 0 {
                    
                    self.addMessages(
                        messages: newMessages,
                        chatId: chatId,
                        completion: { (newMessagesCount, allMessagesCount) in
                            
                        if newMessages.count < ChatListViewModel.kMessagesPerPage {
                            
                            UserDefaults.Keys.messagesFetchPage.removeValue()
                            
                            if restoring {
                                SphinxSocketManager.sharedInstance.connectWebsocket(forceConnect: true)
                            }
                            completion(newMessagesCount, allMessagesCount)
                            CoreDataManager.sharedManager.saveContext()
                            
                        } else {
                            
                            CoreDataManager.sharedManager.saveContext()
                            UserDefaults.Keys.messagesFetchPage.set(page + 1)
                            
                            self.getMessagesPaginated(
                                restoring: restoring,
                                prevPageNewMessages: newMessagesCount + prevPageNewMessages,
                                chatId: chatId,
                                date: date,
                                progressCallback: progressCallback,
                                completion: completion
                            )
                            
                        }
                    })
                } else {
                    completion(0, 0)
                }
            }, errorCallback: {
                DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                    self.getMessagesPaginated(
                        restoring: restoring,
                        prevPageNewMessages: prevPageNewMessages,
                        chatId: chatId,
                        date: date,
                        progressCallback: progressCallback,
                        completion: completion
                    )
                })
                completion(0,0)
            })
    }
    
    func getRestoreProgress(
        currentPage: Int,
        newMessagesTotal: Int,
        itemsPerPage: Int
    ) -> Int {
        
        let pages = (newMessagesTotal <= itemsPerPage) ? 1 : (newMessagesTotal / itemsPerPage)
        let progress: Int = currentPage * 100 / pages

        return progress
    }
    
    func addMessages(messages: [JSON], chatId: Int? = nil, completion: @escaping (Int, Int) -> ()) {
        var newMessagesCount = 0
        
        for messageDictionary in messages {
            let (message, isNew) = TransactionMessage.insertMessage(m: messageDictionary)
            if let message = message {
                message.setPaymentInvoiceAsPaid()
                
                if isAddedRow(message: message, isNew: isNew, viewChatId: chatId) {
                    newMessagesCount = newMessagesCount + 1
                }
            }

        }
        completion(newMessagesCount, messages.count)
    }
    
    func isAddedRow(message: TransactionMessage, isNew: Bool, viewChatId: Int?) -> Bool {
        if TransactionMessage.typesToExcludeFromChat.contains(message.type) {
            return false
        }
        
        if viewChatId == nil {
            return true
        }
        
        if let messageChatId = message.chat?.id, let viewChatId = viewChatId {
            if (isNew || !message.seen) {
                return messageChatId == viewChatId
            }
        }
        return false
    }
    
    func payInvite(invite: UserInvite, completion: @escaping (UserContact?) -> ()) {
        guard let inviteString = invite.inviteString else {
            completion(nil)
            return
        }
        
        let bubbleHelper = NewMessageBubbleHelper()
        bubbleHelper.showLoadingWheel()
        
        API.sharedInstance.payInvite(inviteString: inviteString, callback: { inviteJson in
            bubbleHelper.hideLoadingWheel()
            
            if let invite = UserInvite.insertInvite(invite: inviteJson) {
                if let contact = invite.contact {
                    invite.setPaymentProcessed()
                    completion(contact)
                    return
                }
            }
            completion(nil)
        }, errorCallback: {
            bubbleHelper.hideLoadingWheel()
            completion(nil)
        })
    }
}
