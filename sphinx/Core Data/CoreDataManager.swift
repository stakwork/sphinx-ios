//
//  CoreDataManager.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class CoreDataManager {
    
    static let sharedManager = CoreDataManager()
    
    private init() {}
    
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "sphinx")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.shouldDeleteInaccessibleFaults = true
        
        // 🔑 Ensures that the `mainContext` is aware of any changes that were made
        // to the persistent container.
        //
        // For example, when we save a background context,
        // the persistent container is automatically informed of the changes that
        // were made. And since the `mainContext` is considered to be a child of
        // the persistent container, it will receive those updates -- merging
        // any changes, as the name suggests, automatically.
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    
    func saveContext() {
        CoreDataManager.sharedManager.persistentContainer.viewContext.saveContext()
    }
    
    func save(context: NSManagedObjectContext) {
        context.saveContext()
    }
    
    func getBackgroundContext() -> NSManagedObjectContext {
        let backgroundContext = CoreDataManager.sharedManager.persistentContainer.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        backgroundContext.shouldDeleteInaccessibleFaults = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        return backgroundContext
    }
    
    func clearCoreDataStore() {
        let context = CoreDataManager.sharedManager.persistentContainer.viewContext
        context.performAndWait {
            context.deleteAllObjects()
            do {
                try context.save()
            } catch {
                print("Error on deleting CoreData entities")
            }
        }
    }
    
    func deleteExpiredInvites() {
        for contact in UserContact.getPendingContacts() {
            if let invite = contact.invite, !contact.isOwner, !contact.isConfirmed() && invite.isExpired() {
                invite.removeFromPaymentProcessed()
                API.sharedInstance.deleteContact(id: contact.id, callback: { _ in })
                deleteContactObjectsFor(contact)
            }
        }
        saveContext()
    }
    
    func deleteContactObjectsFor(_ contact: UserContact) {
        if let chat = contact.getChat() {
            for message in chat.getAllMessages(limit: nil) {
                MediaLoader.clearMessageMediaCache(message: message)
                deleteObject(object: message)
            }
            chat.deleteColor()
            deleteObject(object: chat)
        }
        
        if let subscription = contact.getCurrentSubscription() {
            deleteObject(object: subscription)
        }
        
        if let invite = contact.invite {
            invite.removeFromPaymentProcessed()
        }
        
        contact.deleteColor()
        deleteObject(object: contact)
        saveContext()
    }
    
    func deleteChatObjectsFor(_ chat: Chat) {
        if let messagesSet = chat.messages, let groupMessages = Array<Any>(messagesSet) as? [TransactionMessage] {
            for m in groupMessages {
                MediaLoader.clearMessageMediaCache(message: m)
                deleteObject(object: m)
            }
        }
        deleteObject(object: chat)
        saveContext()
    }
    
    func getObjectWith<T>(objectId: NSManagedObjectID) -> T? {
        let managedContext = persistentContainer.viewContext
        return managedContext.object(with:objectId) as? T
    }
    
    func getAllOfType<T>(
        entityName: String,
        sortDescriptors: [NSSortDescriptor]? = nil,
        context: NSManagedObjectContext? = nil
    ) -> [T] {
        let managedContext = context ?? persistentContainer.viewContext
        var objects:[T] = [T]()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"\(entityName)")
        fetchRequest.sortDescriptors = sortDescriptors ?? [NSSortDescriptor(key: "id", ascending: false)]
        
        managedContext.performAndWait {
            do {
                try objects = managedContext.fetch(fetchRequest) as! [T]
            } catch let error as NSError {
                print("Error: " + error.localizedDescription)
            }
        }
        
        return objects
    }
    
    func getObjectOfTypeWith<T>(id: Int, entityName: String) -> T? {
        let managedContext = persistentContainer.viewContext
        var objects:[T] = [T]()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"\(entityName)")
        let predicate = NSPredicate(format: "id == %ld", id)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        managedContext.performAndWait {
            do {
                try objects = managedContext.fetch(fetchRequest) as! [T]
            } catch let error as NSError {
                print("Error: " + error.localizedDescription)
            }
        }
        
        if objects.count > 0 {
            return objects[0]
        }
        return nil
    }
    
    func getObjectsOfTypeWith<T>(
        predicate: NSPredicate?,
        sortDescriptors: [NSSortDescriptor],
        entityName: String,
        fetchLimit: Int? = nil,
        context: NSManagedObjectContext? = nil
    ) -> [T] {
        let managedContext = context ?? persistentContainer.viewContext
        var objects:[T] = [T]()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"\(entityName)")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        if let fetchLimit = fetchLimit {
            fetchRequest.fetchLimit = fetchLimit
        }
        
        managedContext.performAndWait {
            do {
                try objects = managedContext.fetch(fetchRequest) as! [T]
            } catch let error as NSError {
                print("Error: " + error.localizedDescription)
            }
        }
        
        return objects
    }
    
    func getObjectsCountOfTypeWith(predicate: NSPredicate? = nil, entityName: String) -> Int {
        let managedContext = persistentContainer.viewContext
        var count:Int = 0
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"\(entityName)")
        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }
        
        managedContext.performAndWait {
            do {
                try count = managedContext.count(for: fetchRequest)
            } catch let error as NSError {
                print("Error: " + error.localizedDescription)
            }
        }
        
        return count
    }
    
    func getObjectOfTypeWith<T>(
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor],
        entityName: String,
        managedContext: NSManagedObjectContext? = nil
    ) -> T? {
        let managedContext = managedContext ?? persistentContainer.viewContext
        var objects:[T] = [T]()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"\(entityName)")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchLimit = 1
        
        managedContext.performAndWait {
            do {
                try objects = managedContext.fetch(fetchRequest) as! [T]
            } catch let error as NSError {
                print("Error: " + error.localizedDescription)
            }
        }
        
        if objects.count > 0 {
            return objects[0]
        }
        return nil
    }
    
    func deleteObject(object: NSManagedObject) {
        let managedContext = persistentContainer.viewContext
        managedContext.performAndWait {
            managedContext.delete(object)
        }
    }
}

extension NSManagedObjectContext {
    func saveContext() {
        if self.hasChanges {
            do {
                try self.save()
            } catch {
                let nserror = error as NSError
                print("Unresolved error \(nserror)")
            }
        }
    }
}
