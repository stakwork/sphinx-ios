//
//  NewChatViewController+FetchControllerExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import CoreData

extension NewChatViewController: NSFetchedResultsControllerDelegate {
    
    func configureFetchResultsController() {
        if isThread {
            return
        }
        
        if let contact = contact {
            let fetchRequest = UserContact.FetchRequests.matching(id: contact.id)

            contactResultsController = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: CoreDataManager.sharedManager.persistentContainer.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            contactResultsController.delegate = self
            
            CoreDataManager.sharedManager.persistentContainer.viewContext.perform {
                do {
                    try self.contactResultsController.performFetch()
                } catch {}
            }
        }
        
        if let chat = chat {
            let fetchRequest = Chat.FetchRequests.matching(id: chat.id)

            chatResultsController = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: CoreDataManager.sharedManager.persistentContainer.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            chatResultsController.delegate = self
            
            CoreDataManager.sharedManager.persistentContainer.viewContext.perform {
                do {
                    try self.chatResultsController.performFetch()
                } catch {}
            }
        }
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        if
            let resultController = controller as? NSFetchedResultsController<NSManagedObject>,
            let firstSection = resultController.sections?.first {
            
            var shouldReloadView = false
        
            if let contacts = firstSection.objects as? [UserContact], let contact = contacts.first {
                self.contact = contact
                shouldReloadView = true
            }
            
            if let chats = firstSection.objects as? [Chat], let chat = chats.first {
                self.chat = chat
                shouldReloadView = true
            }
        
            if shouldReloadView {
                setupData()
            }
            
        }
    }
}
