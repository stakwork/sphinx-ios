//
//  TransactionMessageQueriesExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import CoreData

extension TransactionMessage {
    static func getAll() -> [TransactionMessage] {
        let messages:[TransactionMessage] = CoreDataManager.sharedManager.getAllOfType(entityName: "TransactionMessage")
        return messages
    }
    
    static func getAllMesagesCount() -> Int {
        let messagesCount:Int = CoreDataManager.sharedManager.getObjectsCountOfTypeWith(entityName: "TransactionMessage")
        return messagesCount
    }
    
    static func getMessageWith(id: Int) -> TransactionMessage? {
        let message: TransactionMessage? = CoreDataManager.sharedManager.getObjectOfTypeWith(id: id, entityName: "TransactionMessage")
        return message
    }
    
    static func getMessageWith(uuid: String) -> TransactionMessage? {
        let predicate = NSPredicate(format: "uuid == %@", uuid)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        
        let message: TransactionMessage? = CoreDataManager.sharedManager.getObjectOfTypeWith(
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            entityName: "TransactionMessage"
        )
        
        return message
    }
    
    static func getMessagesWith(uuids: [String]) -> [TransactionMessage] {
        let predicate = NSPredicate(format: "uuid IN %@", uuids)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        
        let messages: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            entityName: "TransactionMessage"
        )
        
        return messages
    }
    
    //Added firstMessage param to the query method. If stored then chat will load all messages starting from that one and won't consider the limit param
    static func getAllMessagesFor(
        chat: Chat,
        limit: Int? = nil,
        lastMessage: TransactionMessage? = nil,
        firstMessage: TransactionMessage? = nil
    ) -> [TransactionMessage] {
        
        let fetchRequest = getChatMessagesFetchRequest(for: chat, with: limit, lastMessage: lastMessage, firstMessage: firstMessage)
        var messages: [TransactionMessage] = []
        let context = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        do {
            try messages = context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Error: " + error.localizedDescription)
        }
        
        return messages
    }
    
    static func getChatMessagesFetchRequest(
        for chat: Chat,
        with limit: Int? = nil,
        lastMessage: TransactionMessage? = nil,
        firstMessage: TransactionMessage? = nil
    ) -> NSFetchRequest<TransactionMessage> {
        
        var predicate : NSPredicate!
        
        var typesToExclude = typesToExcludeFromChat
        typesToExclude.append(TransactionMessageType.boost.rawValue)
        
        if let f = firstMessage {
            predicate = NSPredicate(
                format: "chat == %@ AND (date >= %@) AND (NOT (type IN %@) || (type == %d && replyUUID = nil))",
                chat,
                f.messageDate as NSDate,
                typesToExclude,
                TransactionMessageType.boost.rawValue
            )
        } else if let m = lastMessage {
            predicate = NSPredicate(
                format: "chat == %@ AND (date <= %@) AND (NOT (type IN %@) || (type == %d && replyUUID = nil))",
                chat,
                m.messageDate as NSDate,
                typesToExclude,
                TransactionMessageType.boost.rawValue
            )
        } else {
            predicate = NSPredicate(
                format: "chat == %@ AND (NOT (type IN %@) || (type == %d && replyUUID = nil))",
                chat,
                typesToExclude,
                TransactionMessageType.boost.rawValue
            )
        }
        
        let sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: false),
            NSSortDescriptor(key: "id", ascending: false)
        ]
        
        let fetchLimit = (firstMessage == nil) ? limit : nil
        
        let fetchRequest = NSFetchRequest<TransactionMessage>(entityName: "TransactionMessage")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        if let fetchLimit = fetchLimit {
            fetchRequest.fetchLimit = fetchLimit
        }
        
        return fetchRequest
    }
    
    static func getAllMessagesCountFor(chat: Chat, lastMessageId: Int? = nil) -> Int {
        return CoreDataManager.sharedManager.getObjectsCountOfTypeWith(predicate: NSPredicate(format: "chat == %@ AND NOT (type IN %@)", chat, typesToExcludeFromChat), entityName: "TransactionMessage")
    }
    
    static func getNewMessagesCountFor(chat: Chat, lastMessageId: Int) -> Int {
        return CoreDataManager.sharedManager.getObjectsCountOfTypeWith(predicate: NSPredicate(format: "chat == %@ AND id > %d", chat, lastMessageId), entityName: "TransactionMessage")
    }
    
    static func getInvoiceWith(paymentHash: String) -> TransactionMessage? {
        let predicate = NSPredicate(format: "type == %d AND paymentHash == %@", TransactionMessageType.invoice.rawValue, paymentHash)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let invoice: TransactionMessage? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage")
        
        return invoice
    }
    
    static func getInvoiceWith(paymentRequestString: String) -> TransactionMessage? {
        let predicate = NSPredicate(format: "type == %d AND invoice == %@", TransactionMessageType.invoice.rawValue, paymentRequestString)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let invoice: TransactionMessage? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage")
        
        return invoice
    }
    
    static func getMessagesFor(userId: Int, contactId: Int) -> [TransactionMessage] {
        let predicate = NSPredicate(format: "((senderId == %d AND receiverId == %d) OR (senderId == %d AND receiverId == %d)) AND id >= 0 AND NOT (type IN %@)", contactId, userId, userId, contactId, typesToExcludeFromChat)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let messages: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage")
        
        return messages
    }
    
    static func getLastGroupRequestFor(contactId: Int, in chat: Chat) -> TransactionMessage? {
        let predicate = NSPredicate(format: "senderId == %d AND chat == %@ AND type == %d", contactId, chat, TransactionMessageType.memberRequest.rawValue)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let messages: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage", fetchLimit: 1)
        
        return messages.first
    }
    
    static func getReceivedUnseenMessagesCount() -> Int {
        let userId = UserData.sharedInstance.getUserId()

        let predicate = NSPredicate(
            format:
                "senderId != %d AND seen == %@ AND chat != null AND id >= 0 AND chat.seen == %@ AND (chat.notify == %d OR (chat.notify == %d AND push == %@))",
            userId,
            NSNumber(booleanLiteral: false),
            NSNumber(booleanLiteral: false),
            Chat.NotificationLevel.SeeAll.rawValue,
            Chat.NotificationLevel.OnlyMentions.rawValue,
            NSNumber(booleanLiteral: true)
        )

        let messagesCount = CoreDataManager.sharedManager.getObjectsCountOfTypeWith(
            predicate: predicate,
            entityName: "TransactionMessage"
        )

        return messagesCount
    }
    
    static func getProvisionalMessageId() -> Int {
        let userId = UserData.sharedInstance.getUserId()
        let messageType = TransactionMessageType.message.rawValue
        let attachmentType = TransactionMessageType.attachment.rawValue
        let predicate = NSPredicate(format: "(senderId == %d) AND (type == %d || type == %d) AND id < 0", userId, messageType, attachmentType)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let messages: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage", fetchLimit: 1)
        
        if messages.count > 0 {
            return messages[0].id - 1
        }
        
        return -1
    }
    
    static func getPaymentsFor(feedId: String) -> [TransactionMessage] {
        let feedIDString1 = "{\"feedID\":\"\(feedId)"
        let feedIDString2 = "{\"feedID\":\(Int(feedId) ?? -1)"
        let predicate = NSPredicate(format: "chat == nil && (messageContent BEGINSWITH[c] %@ OR messageContent BEGINSWITH[c] %@)", feedIDString1, feedIDString2)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let payments: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage")
        
        return payments
    }
    
    static func getLiveMessagesFor(chat: Chat, episodeId: String) -> [TransactionMessage] {
        let episodeString = "\"itemID\":\"\(episodeId)\""
        let episodeString2 = "\"itemID\":\(episodeId)"
        let predicate = NSPredicate(format: "chat == %@ && ((type == %d && (messageContent BEGINSWITH[c] %@ OR messageContent BEGINSWITH[c] %@)) || (type == %d && replyUUID == nil)) && (messageContent CONTAINS[c] %@ || messageContent CONTAINS[c] %@)", chat, TransactionMessageType.message.rawValue, PodcastFeed.kClipPrefix, PodcastFeed.kBoostPrefix, TransactionMessageType.boost.rawValue, episodeString, episodeString2)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let boostAndClips: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage")
        
        return boostAndClips
    }
    
    static func getBoostMessagesFor(
        _ messages: [String],
        on chat: Chat
    ) -> [TransactionMessage] {
        let boostType = TransactionMessageType.boost.rawValue
        let predicate = NSPredicate(format: "chat == %@ AND type == %d AND replyUUID != nil AND (replyUUID IN %@)", chat, boostType, messages)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let reactions: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage")
        
        return reactions
    }

}
