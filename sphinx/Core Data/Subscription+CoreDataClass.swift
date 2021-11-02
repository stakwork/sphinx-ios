//
//  Subscription+CoreDataClass.swift
//  
//
//  Created by Tomas Timinskas on 20/11/2019.
//
//

import Foundation
import CoreData
import SwiftyJSON

@objc(Subscription)
public class Subscription: NSManagedObject {
    
    public func isPaused() -> Bool {
        return self.paused
    }
    
    public func hasEnded() -> Bool {
        return self.ended
    }
    
    public func isActive() -> Bool {
        return !self.ended && !self.paused
    }
    
    public static func getAll() -> [Subscription] {
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let subscriptions: [Subscription] = CoreDataManager.sharedManager.getAllOfType(entityName: "Subscription", sortDescriptors: sortDescriptors)
        return subscriptions
    }
    
    public static func getSubscriptionWith(id: Int) -> Subscription? {
        let predicate = NSPredicate(format: "id == %d", id)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let subscription:Subscription? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "Subscription")
        return subscription
    }
    
    public static func getSubscriptionInstance(id: Int, managedContext: NSManagedObjectContext) -> Subscription {
        if let s = Subscription.getSubscriptionWith(id: id) {
            return s
        } else {
            return Subscription(context: managedContext) as Subscription
        }
    }

    public static func insertSubscription(subscription: JSON) -> Subscription? {
        let id = subscription["id"].intValue
        var chat: Chat? = nil
        var contact: UserContact?  = nil
        
        let chatId = subscription["chat_id"].intValue
        let contactId = subscription["contact_id"].intValue
        let cron = subscription["cron"].stringValue
        
        var amount:NSDecimalNumber? = nil
        if let a = subscription["amount"].double, abs(a) > 0 {
            amount = NSDecimalNumber(value: a)
        }
        
        let count = subscription["count"].intValue
        let endNumber = (subscription["end_number"].int ?? subscription["endNumber"].int) ?? -1
        let ended = subscription["ended"].boolValue
        let paused = subscription["paused"].boolValue
        
        let endDateString = (subscription["end_date"].string ?? subscription["endDate"].string) ?? ""
        let createdAtString = (subscription["created_at"].string ?? subscription["createdAt"].string) ?? ""
        let updatedAtString = (subscription["updated_at"].string ?? subscription["updatedAt"].string) ?? ""
        
        let endDate = Date.getDateFromString(dateString: endDateString) ?? nil
        let createdAt = Date.getDateFromString(dateString: createdAtString) ?? nil
        let updatedAt = Date.getDateFromString(dateString: updatedAtString) ?? nil
        
        if let chatObject = Chat.getChatWith(id: chatId) {
            chat = chatObject
        } else if let chatDictionary = subscription["chat"].dictionary {
            if let chatObject = Chat.getOrCreateChat(chat: JSON(chatDictionary)) {
                chat = chatObject
            }
        }

        if let contactObject = UserContact.getContactWith(id: contactId) {
            contact = contactObject
        }
        
        let subscription = Subscription.createObject(id: id, chat: chat, contact: contact, amount: amount, cron: cron, count: count, endNumber: endNumber, endDate: endDate, createdAt: createdAt, updatedAt: updatedAt, ended: ended, paused: paused)
        
        return subscription
    }
    
    public static func createObject(id: Int, chat: Chat?, contact: UserContact?, amount: NSDecimalNumber?, cron: String, count: Int, endNumber: Int?, endDate: Date?, createdAt: Date?, updatedAt: Date?, ended: Bool, paused: Bool) -> Subscription? {
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        let subscription = getSubscriptionInstance(id: id, managedContext: managedContext)
       
        subscription.id = id
        subscription.amount = amount
        subscription.count = count
        subscription.cron = cron
        subscription.endNumber = endNumber ?? -1
        subscription.endDate = endDate
        subscription.ended = ended
        subscription.paused = paused
        subscription.chat = chat
        subscription.contact = contact
        subscription.createdAt = createdAt
        subscription.updatedAt = updatedAt
        
        return subscription
    }
    
    public static func parseCron(cron: String) -> String {
        if cron.hasSuffix("* * *") {
            return "daily"
        } else if cron.hasSuffix("* *") {
            return "monthly"
        } else {
            return "weekly"
        }
    }
}
