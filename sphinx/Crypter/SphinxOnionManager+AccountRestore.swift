//
//  SphinxOnionManager+AccountRestore.swift
//  sphinx
//
//  Created by James Carucci on 3/20/24.
//  Copyright © 2024 sphinx. All rights reserved.
//

import Foundation
import CoreData
import ObjectMapper

public enum RestoreMessagePhase{
    case firstScidMessages
    case okKeyMessages
    case allMessages
    case none
}

class MessageFetchParams {
    var restoreInProgress: Bool
    var fetchStartIndex: Int
    var fetchTargetIndex: Int
    var fetchLimit: Int
    var messageCountForPhase:Int
    var blockCompletionHandler: (() -> ())?
    var restoreMessagePhase : RestoreMessagePhase = .none

    init(restoreInProgress: Bool, fetchStartIndex: Int, fetchTargetIndex: Int, fetchLimit: Int, blockCompletionHandler: (() -> ())?) {
        self.restoreInProgress = restoreInProgress
        self.fetchStartIndex = fetchStartIndex
        self.fetchTargetIndex = fetchTargetIndex
        self.fetchLimit = fetchLimit
        self.blockCompletionHandler = blockCompletionHandler
        self.messageCountForPhase = 0
    }
}

class MsgTotalCounts: Mappable {
    var totalMessageAvailableCount: Int?
    var okKeyMessageAvailableCount: Int?
    var firstMessageAvailableCount: Int?

    required init?(map: Map) {
    }

    func mapping(map: Map) {
        totalMessageAvailableCount             <- map["total"]
        okKeyMessageAvailableCount             <- map["ok_key"]
        firstMessageAvailableCount  <- map["first_for_each_scid"]
    }
    
    func hasOneValidCount() -> Bool {
        // Use an array to check for non-nil properties in a condensed form
        let properties = [totalMessageAvailableCount, okKeyMessageAvailableCount, firstMessageAvailableCount]
        return properties.contains(where: { $0 != nil })
    }
    
}


extension SphinxOnionManager{//account restore related
    
    func performAccountRestore(){
        setupRestore()
    }
    
    func setupRestore(){
        guard let seed = getAccountSeed() else{
            return
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(processMessageCountReceived), name: .totalMessageCountReceived, object: nil)
        
        let rr = try! getMsgsCounts(seed: seed, uniqueTime: getTimeWithEntropy(), state: loadOnionStateAsData())
        handleRunReturn(rr: rr)
    }
    
    @objc func processMessageCountReceived(){
        if let msgTotalCounts = self.msgTotalCounts,
           msgTotalCounts.hasOneValidCount(){
            kickOffFullRestore()
        }
    }
    
    func kickOffFullRestore(){
        guard let msgTotalCounts = msgTotalCounts else {return}
        if let firstForEachScidCount = msgTotalCounts.firstMessageAvailableCount{
            restoreTribes()
        }
//        if let okKeyMsgCount = msgTotalCounts.okKeyMessageAvailableCount{
//            restoreContactsAndPayments()
//        }
//        restoreContactsAndPayments()
//        restoreMessages()
    }
    
    
    func restoreTribes(){
        guard let seed = getAccountSeed() else{
            return
        }
        
        let indexStepSize = 100
        let startIndex = 0
        //emulating getAllUnreadMessages()
        
        messageFetchParams = MessageFetchParams(
            restoreInProgress: true,
            fetchStartIndex: startIndex,
            fetchTargetIndex: startIndex + indexStepSize,
            fetchLimit: indexStepSize,
            blockCompletionHandler: nil
        )
        messageFetchParams?.restoreMessagePhase = .firstScidMessages
        NotificationCenter.default.addObserver(self, selector: #selector(handleFetchFirstScidMessages), name: .newOnionMessageWasReceived, object: nil)
        fetchFirstContactPerKey(seed: seed, lastMessageIndex: startIndex, msgCountLimit: indexStepSize)
    }
    
    
    func restoreContactsAndPayments(){
        guard let seed = getAccountSeed() else{
            return
        }
        
        let indexStepSize = 100
        let startIndex = 0
        //emulating getAllUnreadMessages()
        
        messageFetchParams = MessageFetchParams(
            restoreInProgress: true,
            fetchStartIndex: startIndex,
            fetchTargetIndex: startIndex + indexStepSize,
            fetchLimit: indexStepSize,
            blockCompletionHandler: nil
        )
        messageFetchParams?.restoreMessagePhase = .firstScidMessages
        NotificationCenter.default.addObserver(self, selector: #selector(handleFetchFirstScidMessages), name: .newOnionMessageWasReceived, object: nil)
        
        let rr = try! fetchMsgsBatchOkkey(seed: seed, uniqueTime: getTimeWithEntropy(), state: loadOnionStateAsData(), lastMsgIdx: UInt64(startIndex), limit: UInt32(indexStepSize), reverse: false, isRestore: true)
        handleRunReturn(rr: rr)
    }
    
    func fetchFirstContactPerKey(
        seed:String,
        lastMessageIndex:Int,
        msgCountLimit:Int
    ){
        do{
            let rr = try fetchFirstMsgsPerKey(seed: seed, uniqueTime: getTimeWithEntropy(), state: loadOnionStateAsData(), lastMsgIdx: UInt64(lastMessageIndex), limit: UInt32(msgCountLimit), reverse: false, isRestore: true)
            handleRunReturn(rr: rr)
        }
        catch{
            
        }
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
            blockCompletionHandler: nextMessageBlockHandler_fetchMsgs
        )
        
        listenForNewMessageBlock(targetIndex: startIndex + indexStepSize)
        fetchMessageBlock(seed: seed, lastMessageIndex: startIndex, msgCountLimit: indexStepSize)
        
        print("post sync lastIndex:\(UserData.sharedInstance.getLastMessageIndex())")
    }
    
    func nextMessageBlockHandler_fetchMsgs(){
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
                blockCompletionHandler: nextMessageBlockHandler_fetchMsgs
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
    //MARK: Process all first scid messages
    @objc func handleFetchFirstScidMessages(n:Notification){
        guard let message = n.userInfo?["message"] as? TransactionMessage else{
              return
          }
        messageFetchParams?.messageCountForPhase += 1
        print("first scid message count:\(messageFetchParams?.messageCountForPhase)")
        if((messageFetchParams?.messageCountForPhase ?? 0) >= (msgTotalCounts?.firstMessageAvailableCount ?? 0)){ // we got all the messages
            NotificationCenter.default.removeObserver(self, name: .newOnionMessageWasReceived, object: nil)
        }
        else{//go again
            
        }
    }
    
    
    
    //MARK: Process Incoming Message Blocks (All Messages)

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
                if let handler = messageFetchParams?.blockCompletionHandler{
                    handler()
                }
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
            if let handler = messageFetchParams?.blockCompletionHandler{
                handler()
            }
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
                    self.nextMessageBlockHandler_fetchMsgs()
                }
            }
        }
    }
}
