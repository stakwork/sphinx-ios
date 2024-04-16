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
    
    static func getMessageWith(muid: String) -> TransactionMessage? {
        let predicate = NSPredicate(format: "muid == %@", muid)
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
    
    static func getMessageDeletionRequests() -> [TransactionMessage] {
        let context = CoreDataManager.sharedManager.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<TransactionMessage> = TransactionMessage.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "type == %d", 17) // Replace '17' with the actual type if it differs.
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)] // Sorting by 'id', adjust as needed.

        do {
            let results = try context.fetch(fetchRequest)
            return results
        } catch let error as NSError {
            print("Error fetching messages of type 17: \(error), \(error.userInfo)")
            return []
        }
    }
    
    static func getMessagesWith(ids: [Int]) -> [TransactionMessage] {
        let predicate = NSPredicate(format: "id IN %@", ids)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        
        let messages: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            entityName: "TransactionMessage"
        )
        
        return messages
    }
    
    static func getAllMessagesFor(
        chat: Chat,
        limit: Int? = nil,
        context: NSManagedObjectContext? = nil
    ) -> [TransactionMessage] {
        
        let fetchRequest = getChatMessagesFetchRequest(
            for: chat,
            with: limit
        )
        
        var messages: [TransactionMessage] = []
        let context = context ?? CoreDataManager.sharedManager.persistentContainer.viewContext
        
        context.performAndWait {
            do {
                try messages = context.fetch(fetchRequest)
            } catch let error as NSError {
                print("Error: " + error.localizedDescription)
            }
        }
        
        return messages
    }
    
    static func getMaxIndexMessageFor(chat: Chat) -> TransactionMessage? {
        let context = CoreDataManager.sharedManager.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<TransactionMessage> = TransactionMessage.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "chat == %@", chat)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch let error as NSError {
            print("Error fetching message with max ID: \(error), \(error.userInfo)")
            return nil
        }
    }
    
    static func getPredicate(
        chat: Chat,
        threadUUID: String?,
        typesToExclude: [Int],
        pinnedMessageId: Int? = nil
    ) -> NSPredicate {
        if let tuid = threadUUID {
            return NSPredicate(
                format: "chat == %@ AND (NOT (type IN %@) || (type == %d && replyUUID = nil)) AND threadUUID == %@",
                chat,
                typesToExclude,
                TransactionMessageType.boost.rawValue,
                tuid,
                tuid
            )
        } else { //display general, non-thread results
            if let pinnedMessageId = pinnedMessageId {
                return NSPredicate(
                    format: "chat == %@ AND id >= %d AND (NOT (type IN %@) || (type == %d && replyUUID = nil))",
                    chat,
                    pinnedMessageId - 200,
                    typesToExclude,
                    TransactionMessageType.boost.rawValue
                )
            } else {
                return NSPredicate(
                    format: "chat == %@ AND (NOT (type IN %@) || (type == %d && replyUUID = nil))",
                    chat,
                    typesToExclude,
                    TransactionMessageType.boost.rawValue
                )
            }
        }
    }
    
    static func getChatMessagesFetchRequest(
        for chat: Chat,
        threadUUID: String? = nil,
        with limit: Int? = nil,
        pinnedMessageId: Int? = nil
    ) -> NSFetchRequest<TransactionMessage> {
        
        var typesToExclude = typesToExcludeFromChat
        typesToExclude.append(TransactionMessageType.boost.rawValue)
        
        let predicate = TransactionMessage.getPredicate(
            chat: chat,
            threadUUID: threadUUID,
            typesToExclude: typesToExclude,
            pinnedMessageId: pinnedMessageId
        )
        
        let sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: false),
            NSSortDescriptor(key: "id", ascending: false)
        ]
        
        let fetchRequest = NSFetchRequest<TransactionMessage>(entityName: "TransactionMessage")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        if let limit = limit, pinnedMessageId == nil {
            fetchRequest.fetchLimit = limit
        }
        
        return fetchRequest
    }
    
    static func getBoostsAndPurchaseMessagesFetchRequestOn(
        chat: Chat
    ) -> NSFetchRequest<TransactionMessage> {
        
        let types = [
            TransactionMessageType.boost.rawValue,
            TransactionMessageType.purchase.rawValue,
            TransactionMessageType.purchaseAccept.rawValue,
            TransactionMessageType.purchaseDeny.rawValue
        ]
        
        let predicate = NSPredicate(
            format: "chat == %@ AND type IN %@",
            chat,
            types
        )
        
        let sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: false),
            NSSortDescriptor(key: "id", ascending: false)
        ]
        
        let fetchRequest = NSFetchRequest<TransactionMessage>(entityName: "TransactionMessage")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        return fetchRequest
    }
    
    static func getThreadsFetchRequestOn(
        chat: Chat
    ) -> NSFetchRequest<TransactionMessage> {
        
        let predicate = NSPredicate(
            format: "chat == %@ AND threadUUID != nil",
            chat
        )
        
        let sortDescriptors = [
            NSSortDescriptor(key: "id", ascending: true)
        ]
        
        let fetchRequest = NSFetchRequest<TransactionMessage>(entityName: "TransactionMessage")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        return fetchRequest
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
    
    static func getPaymentOfInvoiceWith(paymentHash: String) -> TransactionMessage? {
        let predicate = NSPredicate(format: "type == %d AND paymentHash == %@", TransactionMessageType.payment.rawValue, paymentHash)
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
        
        let predicate = NSPredicate(
            format: "(senderId == %d) AND (type == %d || type == %d) AND id < 0",
            userId,
            messageType,
            attachmentType
        )
        
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        let messages: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            entityName: "TransactionMessage",
            fetchLimit: 1
        )
        
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
        let predicate = NSPredicate(
            format:
                "chat == %@ && ((type == %d && (messageContent BEGINSWITH[c] %@ OR messageContent BEGINSWITH[c] %@)) || (type == %d && replyUUID == nil)) && (messageContent CONTAINS[c] %@ || messageContent CONTAINS[c] %@)",
            chat,
            TransactionMessageType.message.rawValue,
            PodcastFeed.kClipPrefix,
            PodcastFeed.kBoostPrefix,
            TransactionMessageType.boost.rawValue,
            episodeString,
            episodeString2
        )
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let boostAndClips: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage")
        
        return boostAndClips
    }
    
    static func getBoostMessagesFor(
        _ messages: [String],
        on chat: Chat
    ) -> [TransactionMessage] {
        let boostType = TransactionMessageType.boost.rawValue
        let failedStatus = TransactionMessage.TransactionMessageStatus.failed.rawValue
        
        let predicate = NSPredicate(
            format: "chat == %@ AND type == %d AND replyUUID != nil AND (replyUUID IN %@) AND status != %d",
            chat,
            boostType, 
            messages,
            failedStatus
        )
        
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let reactions: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage")
        
        return reactions
    }
    
    static func getThreadMessagesFor(
        _ messages: [String],
        on chat: Chat
    ) -> [TransactionMessage] {
        let boostType = TransactionMessageType.boost.rawValue
        
        let deletedStatus = TransactionMessage.TransactionMessageStatus.deleted.rawValue

        let predicate = NSPredicate(
            format: "chat == %@ AND type != %d AND (threadUUID != nil AND (threadUUID IN %@)) AND status != %d AND id > -1",
            chat,
            boostType,
            messages,
            deletedStatus
        )
        
        let sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        let threadMessages: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            entityName: "TransactionMessage"
        )
        
        return threadMessages
    }
    
    static func getOriginalMessagesFor(
        _ threadMessages: [String],
        on chat: Chat
    ) -> [TransactionMessage] {
        let deletedStatus = TransactionMessage.TransactionMessageStatus.deleted.rawValue
        let predicate = NSPredicate(format: "chat == %@ AND uuid != nil AND (uuid IN %@) AND status != %d", chat, threadMessages, deletedStatus)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let reactions: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage")
        
        return reactions
    }
    
    static func getPurchaseItemsFor(
        _ muids: [String],
        on chat: Chat
    ) -> [TransactionMessage] {

        let attachmentType = TransactionMessageType.attachment.rawValue
        
        let predicate = NSPredicate(
            format: "chat == %@ AND (muid IN %@ || originalMuid IN %@) AND type != %d",
            chat,
            muids,
            muids,
            attachmentType
        )
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        let messages: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            entityName: "TransactionMessage"
        )
        
        return messages
    }

}
