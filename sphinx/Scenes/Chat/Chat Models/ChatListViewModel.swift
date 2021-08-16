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
    
    
    var allChats: [Chat] { contactsService.chats }
    
    var contactChats: [Chat] {
        allChats.filter { $0.isConversation() }
    }
    
    var tribeChats: [Chat] {
        allChats.filter { $0.isPublicGroup() }
    }
    
    
    func loadFriends(fromPush: Bool = false, completion: @escaping () -> ()) {
        if let contactsService = contactsService {
            API.sharedInstance.getContacts(fromPush: fromPush, callback: {(contacts, chats, subscriptions) -> () in
                contactsService.insertObjects(contacts: contacts, chats: chats, subscriptions: subscriptions)
                self.forceKeychainSync()
                completion()
            })
            return
        }
        completion()
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
    
    func isRestoring(chatId: Int? = nil) -> Bool {
        let lastSeenDate = API.sharedInstance.lastSeenMessagesDate
        let didJustRestore = UserDefaults.Keys.didJustRestore.get(defaultValue: false)
        return (lastSeenDate == nil) || (chatId == nil && TransactionMessage.getAllMesagesCount() == 0 && didJustRestore)
    }
    
    func syncMessages(
        chatId: Int? = nil,
        fromPush: Bool = false,
        progressCallback: @escaping (String) -> (),
        completion: @escaping (Int, Int, Bool) -> ()
    ) {
        if isRestoring(chatId: chatId) {
            askForNotificationPermissions()
            progressCallback("fetching.old.messages".localized)
            getAllMessages(page: 1, date: Date(), completion: completion)
        } else {
            getMessagesPaginated(
                fromPush: fromPush,
                page: 1,
                prevPageNewMessages: 0,
                chatId: chatId,
                date: Date(),
                progressCallback: progressCallback,
                completion: completion
            )
        }
        UserDefaults.Keys.didJustRestore.set(false)
    }
    
    func getAllMessages(page: Int, date: Date, completion: @escaping (Int, Int, Bool) -> ()) {
        API.sharedInstance.getAllMessages(page: page, date: date, callback: { messages in
            self.addMessages(messages: messages, completion: { (_, _) in
                if messages.count < ChatListViewModel.kMessagesPerPage {
                    completion(0,0, true)
                    
                    SphinxSocketManager.sharedInstance.connectWebsocket(forceConnect: true)
                } else {
                    self.getAllMessages(page: page + 1, date: date, completion: completion)
                }
            })
        }, errorCallback: {
            completion(0,0, true)
        })
    }
    
    func askForNotificationPermissions() {
        if UserDefaults.Keys.didJustRestore.get(defaultValue: false) {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.registerForPushNotifications()
        }
    }
    
    func getMessagesPaginated(
        fromPush: Bool = false,
        page: Int,
        prevPageNewMessages: Int,
        chatId: Int? = nil,
        date: Date,
        progressCallback: @escaping (String) -> (),
        completion: @escaping (Int, Int, Bool) -> ()
    ) {
        API.sharedInstance.getMessagesPaginated(fromPush: fromPush, page: page, date: date, callback: {(newMessages) -> () in
            if newMessages.count > 0 {
                if newMessages.count > 100 {
                    progressCallback("fetching.new.messages".localized)
                }
                
                self.addMessages(messages: newMessages, chatId: chatId, completion: { (newMessagesCount, allMessagesCount) in
                    if newMessages.count < ChatListViewModel.kMessagesPerPage {
                        completion(newMessagesCount, allMessagesCount, false)
                    } else {
                        self.getMessagesPaginated(fromPush: fromPush, page: page + 1, prevPageNewMessages: newMessagesCount + prevPageNewMessages, chatId: chatId, date: date, progressCallback: progressCallback, completion: completion)
                    }
                })
            } else {
                completion(0, 0, false)
            }
        }, errorCallback: {
            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                self.getMessagesPaginated(page: page, prevPageNewMessages: prevPageNewMessages, chatId: chatId, date: date, progressCallback: progressCallback, completion: completion)
            })
            completion(0,0, false)
        })
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
