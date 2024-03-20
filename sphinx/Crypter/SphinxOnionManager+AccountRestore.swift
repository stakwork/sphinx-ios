//
//  SphinxOnionManager+AccountRestore.swift
//  sphinx
//
//  Created by James Carucci on 3/20/24.
//  Copyright © 2024 sphinx. All rights reserved.
//

import Foundation
import CoreData

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
        let indexStepSize = 5
        //emulating getAllUnreadMessages()
        nextMessageBlockWasReceived = false
        var syncComplete = false
        var syncIndex = 0
        
        //set listener and make first fetch
        listenForNewMessageBlock(targetIndex: syncIndex + indexStepSize)
        getAllUnreadMessages()
        fetchMessageBlock(seed: seed, sinceMsgIndex: syncIndex, msgCountLimit: indexStepSize)
        
        while(syncComplete == false){
            if(nextMessageBlockWasReceived){
                syncComplete = syncIndex >= UserData.sharedInstance.getLastMessageIndex() ?? 0
                syncIndex = UserData.sharedInstance.getLastMessageIndex() ?? syncIndex
                nextMessageBlockWasReceived = false
                listenForNewMessageBlock(targetIndex: syncIndex + indexStepSize)
                fetchMessageBlock(seed: seed, sinceMsgIndex: syncIndex, msgCountLimit: indexStepSize)
            }
        }
    }
    
    func fetchMessageBlock(
        seed:String,
        sinceMsgIndex:Int,
        msgCountLimit:Int
    ){
        do{
            let rr = try fetchMsgs(seed: seed, uniqueTime: getTimeWithEntropy(), state: loadOnionStateAsData(), lastMsgIdx: UInt64(sinceMsgIndex), limit: UInt32(msgCountLimit))
            handleRunReturn(rr: rr)
        }
        catch{
            
        }
    }
    
}


extension SphinxOnionManager : NSFetchedResultsControllerDelegate{
    
    func signalNextMessageBlockReady(){
        nextMessageBlockWasReceived = true
    }
    
    private func listenForNewMessageBlock(targetIndex:Int) {
        setupWatchdogTimer()
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext

        let fetchRequest: NSFetchRequest<TransactionMessage> = TransactionMessage.fetchRequest()
        // Update the predicate to check for id greater than lastMessageIndex and adjust according to your entity attributes
        fetchRequest.predicate = NSPredicate(format: "id >= %d", targetIndex)
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
                watchdogTimer?.invalidate()
                signalNextMessageBlockReady()
                self.newMessageSyncedListener = nil
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
                signalNextMessageBlockReady()
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
                    }
                }
            }
        }
}
