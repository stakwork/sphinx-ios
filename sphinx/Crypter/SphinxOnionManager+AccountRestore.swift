//
//  SphinxOnionManager+AccountRestore.swift
//  sphinx
//
//  Created by James Carucci on 3/20/24.
//  Copyright © 2024 sphinx. All rights reserved.
//

import Foundation
import CoreData

struct MessageFetchParams{
    var restoreInProgress : Bool
    var fetchStartIndex : Int
    var fetchTargetIndex : Int
    var fetchLimit : Int
    var blockCompletionHandler : ()->()
}

extension SphinxOnionManager{//account restore related
    
    func performAccountRestore(){
        restoreContactsAndPayments()
        restoreTribes()
        restoreMessages()
    }
    
    
    func restoreContactsAndPayments(){
        
    }
    
    func restoreTribes(){
        
    }
    
    func restoreMessages(){
        guard let seed = getAccountSeed() else{
            return
        }
        
        UserData.sharedInstance.setLastMessageIndex(index: 0)
        let indexStepSize = 100
        let startIndex = 0
        //emulating getAllUnreadMessages()
        
        messageFetchParams = MessageFetchParams(
            restoreInProgress: true,
            fetchStartIndex: startIndex,
            fetchTargetIndex: startIndex + indexStepSize,
            fetchLimit: indexStepSize,
            blockCompletionHandler: nextMessageBlockHandler
        )
        
        listenForNewMessageBlock(targetIndex: startIndex + indexStepSize)
        fetchMessageBlock(seed: seed, lastMessageIndex: startIndex, msgCountLimit: indexStepSize)
        
        print("post sync lastIndex:\(UserData.sharedInstance.getLastMessageIndex())")
    }
    
    func nextMessageBlockHandler(){
        print(messageFetchParams)
        guard var messageFetchParams = messageFetchParams,
              messageFetchParams.restoreInProgress == true,
        let lastRetrievedIndex = UserData.sharedInstance.getLastMessageIndex(),
        let seed = getAccountSeed()
        else{
            return
        }
        if lastRetrievedIndex < messageFetchParams.fetchTargetIndex{
            let nextTargetIndex = messageFetchParams.fetchStartIndex + messageFetchParams.fetchLimit + 1
            messageFetchParams.fetchTargetIndex = nextTargetIndex
            messageFetchParams = MessageFetchParams(
                restoreInProgress: true,
                fetchStartIndex: lastRetrievedIndex + 1,
                fetchTargetIndex: nextTargetIndex,
                fetchLimit: messageFetchParams.fetchLimit,
                blockCompletionHandler: nextMessageBlockHandler
            )
            
            listenForNewMessageBlock(targetIndex: lastRetrievedIndex + messageFetchParams.fetchLimit)
            fetchMessageBlock(seed: seed, lastMessageIndex: lastRetrievedIndex + 1, msgCountLimit: messageFetchParams.fetchLimit)
        }
        else{
            messageFetchParams.restoreInProgress = false
        }

    }
    
    func fetchMessageBlock(
        seed:String,
        lastMessageIndex:Int,
        msgCountLimit:Int
    ){
        do{
            let rr = try fetchMsgs(seed: seed, uniqueTime: getTimeWithEntropy(), state: loadOnionStateAsData(), lastMsgIdx: UInt64(lastMessageIndex), limit: UInt32(msgCountLimit))
            handleRunReturn(rr: rr)
        }
        catch{
            
        }
    }
    
}


extension SphinxOnionManager : NSFetchedResultsControllerDelegate{
    
    private func listenForNewMessageBlock(targetIndex:Int) {
        setupWatchdogTimer()
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext

        let fetchRequest: NSFetchRequest<TransactionMessage> = TransactionMessage.fetchRequest()
        // Update the predicate to check for id greater than lastMessageIndex and adjust according to your entity attributes
        fetchRequest.predicate = NSPredicate(format: "id >= %d", targetIndex - 1)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        newMessageSyncedListener = NSFetchedResultsController(fetchRequest: fetchRequest,
              managedObjectContext: managedContext,
              sectionNameKeyPath: nil,
              cacheName: nil
            )
        newMessageSyncedListener?.delegate = self

        do {
            try newMessageSyncedListener?.performFetch()
            // Check if we already have the desired data
            if let _ = newMessageSyncedListener?.fetchedObjects?.first {
                messageFetchParams?.blockCompletionHandler()
                watchdogTimer?.invalidate()
            }
        }
        catch let error as NSError {
            watchdogTimer?.invalidate()
            self.newMessageSyncedListener = nil
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Called when the content of the fetchedResultsController changes.
        if let _ = controller.fetchedObjects?.first {
            messageFetchParams?.blockCompletionHandler()
            self.newMessageSyncedListener = nil
        }
    }
    
    private func setupWatchdogTimer() {
        watchdogTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            // Check if the fetch result is still nil
            if self.newMessageSyncedListener?.fetchedObjects?.first == nil {
                // Perform the fallback action
                DispatchQueue.main.async {
                    //error out
                    self.nextMessageBlockHandler()
                }
            }
        }
    }
}
