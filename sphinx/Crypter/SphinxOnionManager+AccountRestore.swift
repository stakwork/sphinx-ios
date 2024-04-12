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
    var restoreMessagePhase : RestoreMessagePhase = .none
    var fetchDirection: FetchDirection
    var stopIndex: Int?{
        didSet{
            print(oldValue)
        }
    }

    enum FetchDirection {
        case forward, backward
    }

    init(restoreInProgress: Bool, fetchStartIndex: Int, fetchTargetIndex: Int, fetchLimit: Int, blockCompletionHandler: (() -> ())?, initialCount:Int, fetchDirection: FetchDirection = .backward, arbitraryStartIndex: Int? = nil, stopIndex: Int? = nil) {
        self.restoreInProgress = restoreInProgress
        self.fetchStartIndex = fetchStartIndex
        self.fetchTargetIndex = fetchTargetIndex
        self.fetchLimit = fetchLimit
        self.messageCountForPhase = initialCount
        self.fetchDirection = fetchDirection
        self.stopIndex = stopIndex
    }
    
    var debugDescription: String {
        return """
        restoreInProgress: \(restoreInProgress)
        fetchStartIndex: \(fetchStartIndex)
        fetchTargetIndex: \(fetchTargetIndex)
        fetchLimit: \(fetchLimit)
        messageCountForPhase: \(messageCountForPhase)
        restoreMessagePhase: \(restoreMessagePhase)
        fetchDirection: \(fetchDirection)
        stopIndex: \(String(describing: stopIndex))
        """
    }
}

class MsgTotalCounts: Mappable {
    var totalMessageAvailableCount: Int?
    var okKeyMessageAvailableCount: Int?
    var firstMessageAvailableCount: Int?
    var totalMessageMaxIndex: Int?
    var okKeyMessageMaxIndex: Int?
    var firstMessageMaxIndex: Int?

    required init?(map: Map) {
    }

    func mapping(map: Map) {
        totalMessageAvailableCount             <- map["total"]
        okKeyMessageAvailableCount             <- map["ok_key"]
        firstMessageAvailableCount  <- map["first_for_each_scid"]
        totalMessageMaxIndex             <- map["total_highest_index"]
        okKeyMessageMaxIndex             <- map["ok_key_highest_index"]
        firstMessageMaxIndex  <- map["first_for_each_scid_highest_index"]
    }

    func hasOneValidCount() -> Bool {
        // Use an array to check for non-nil properties in a condensed form
        let properties = [totalMessageAvailableCount, okKeyMessageAvailableCount, firstMessageAvailableCount]
        return properties.contains(where: { $0 != nil })
    }

}


extension SphinxOnionManager{//account restore related
    
    func performAccountRestore(contactRestoreCallback: @escaping RestoreProgressCallback, messageRestoreCallback: @escaping RestoreProgressCallback,hideRestoreViewCallback: @escaping ()->()){
        self.messageRestoreCallback = messageRestoreCallback
        self.contactRestoreCallback = contactRestoreCallback
        self.hideRestoreCallback = hideRestoreViewCallback
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
        
        messageFetchParams?.restoreMessagePhase = .firstScidMessages
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            if let firstForEachScidCount = msgTotalCounts.firstMessageAvailableCount{
                self.restoreFirstScidMessages()
            }
        })
        
    }
    
    func doNextRestorePhase(){
        guard let messageFetchParams = messageFetchParams else{
            return
        }
        
        switch(messageFetchParams.restoreMessagePhase){
        case .firstScidMessages:
            messageFetchParams.restoreMessagePhase = .allMessages
            messageFetchParams.restoreInProgress = false //temporarily reset this
            if let callback = hideRestoreCallback{ callback()}
            restoreAllMessages()
            break
        case .allMessages:
            messageFetchParams.restoreInProgress = false
            if let callback = hideRestoreCallback{ callback()}
            messageFetchParams.restoreMessagePhase = .none
            break
        default:
            break
        }
    }
    
    
    func restoreFirstScidMessages(){
        guard let seed = getAccountSeed() else{
            return
        }
        
        let indexStepSize = SphinxOnionManager.kMessageBatchSize
        let startIndex = 0
        //emulating getAllUnreadMessages()
        
        messageFetchParams = MessageFetchParams(
            restoreInProgress: true,
            fetchStartIndex: startIndex,
            fetchTargetIndex: startIndex + indexStepSize,
            fetchLimit: indexStepSize,
            blockCompletionHandler: nil,
            initialCount: startIndex
        )
        messageFetchParams?.restoreMessagePhase = .firstScidMessages
        NotificationCenter.default.addObserver(self, selector: #selector(handleFetchFirstScidMessages), name: .newOnionMessageWasReceived, object: nil)
        fetchFirstContactPerKey(seed: seed, lastMessageIndex: startIndex, msgCountLimit: indexStepSize)
    }
    
    func fetchFirstContactPerKey(
        seed:String,
        lastMessageIndex:Int,
        msgCountLimit:Int
    ){
        let safeIndex = max(lastMessageIndex,0)
        do{
            let rr = try fetchFirstMsgsPerKey(seed: seed, uniqueTime: getTimeWithEntropy(), state: loadOnionStateAsData(), lastMsgIdx: UInt64(safeIndex), limit: UInt32(msgCountLimit), reverse: false)
            handleRunReturn(rr: rr)
        }
        catch{
            
        }
    }
    
    func restoreAllMessages(fetchDirection: MessageFetchParams.FetchDirection = .backward, arbitraryStartIndex: Int? = nil) {
        UserData.sharedInstance.setLastMessageIndex(index: 0)
        messageFetchParams?.stopIndex = 0
        
        processSyncCountsReceived()
    }

    func syncMessagesSinceLastKnownIndexHeight(){
        guard let lastKnownMax = UserData.sharedInstance.getLastMessageIndex() else{
            return
        }
        messageFetchParams?.stopIndex = lastKnownMax
        setupSync()
    }
    
    func setupSync(){
        guard let seed = getAccountSeed() else{
            return
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(processSyncCountsReceived), name: .totalMessageCountReceived, object: nil)
        
        let rr = try! getMsgsCounts(seed: seed, uniqueTime: getTimeWithEntropy(), state: loadOnionStateAsData())
        
        handleRunReturn(rr: rr)
    }
    
    @objc func processSyncCountsReceived(){
        if let msgTotalCounts = self.msgTotalCounts,
           msgTotalCounts.hasOneValidCount(),
           messageFetchParams?.restoreInProgress != true{
            messageFetchParams?.restoreInProgress = true
            let startIndex = (msgTotalCounts.totalMessageMaxIndex ?? 0)
            guard let lastKnownHeight = UserData.sharedInstance.getLastMessageIndex() else{
                return
            }
            let safeSpread = max(0, startIndex - lastKnownHeight)
            if(safeSpread <= 0){finishRestoration(); return}
            let firstBatchSize = min(SphinxOnionManager.kMessageBatchSize, safeSpread)//either do max batch size or less if less is needed
            // Begin the fetching process
            startAllMsgBlockFetch(startIndex: startIndex, indexStepSize: firstBatchSize, fetchDirection: .backward, stopIndex: lastKnownHeight)
        }
    }

    
    func startAllMsgBlockFetch(startIndex: Int, indexStepSize: Int, fetchDirection: MessageFetchParams.FetchDirection,stopIndex:Int=0) {
        guard let seed = getAccountSeed() else { return }

        messageFetchParams = MessageFetchParams(
            restoreInProgress: true,
            fetchStartIndex: startIndex,
            fetchTargetIndex: startIndex - indexStepSize, // Adjust for backward fetching
            fetchLimit: indexStepSize,
            blockCompletionHandler: nil,
            initialCount: startIndex,
            fetchDirection: fetchDirection,
            arbitraryStartIndex: startIndex,
            stopIndex: stopIndex
        )
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleFetchAllMessages), name: .newOnionMessageWasReceived, object: nil)
        fetchMessageBlock(
            seed: seed,
            lastMessageIndex: startIndex,
            msgCountLimit: indexStepSize,
            fetchDirection: fetchDirection
        )
    }


    
    func fetchMessageBlock(seed: String, lastMessageIndex: Int, msgCountLimit: Int, fetchDirection: MessageFetchParams.FetchDirection) {
        let reverse = fetchDirection == .backward
        let safeLastMsgIndex = max(lastMessageIndex, 0)
        do {
            let rr = try! fetchMsgsBatch(
                seed: seed,
                uniqueTime: getTimeWithEntropy(),
                state: loadOnionStateAsData(),
                lastMsgIdx: UInt64(safeLastMsgIndex),
                limit: UInt32(msgCountLimit),
                reverse: reverse
            )
            handleRunReturn(rr: rr)
        } catch {
            // Handle error
        }
    }


    
}


extension SphinxOnionManager : NSFetchedResultsControllerDelegate{
    //MARK: Process all first scid messages
    @objc func handleFetchFirstScidMessages(n: Notification) {
        print("Got first scid message notification: \(n)")
        guard let message = n.userInfo?["message"] as? TransactionMessage else {
            return
        }

        // Increment the count for messages processed in this phase
        messageFetchParams?.messageCountForPhase += 1
        print("First scid message count: \(messageFetchParams?.messageCountForPhase)")

        if let messageCount = messageFetchParams?.messageCountForPhase,
           let totalMsgCount = msgTotalCounts?.firstMessageAvailableCount,
           let contactRestoreCallback = contactRestoreCallback,
            totalMsgCount > 0{
            let percentage = (Double(messageCount + 1) / Double(totalMsgCount)) * 100
            let pctInt = Int(percentage.rounded())
            contactRestoreCallback(pctInt)
        }
        
        if let params = messageFetchParams,
           let firstForEachScidCount = msgTotalCounts?.firstMessageAvailableCount,
           params.messageCountForPhase >= firstForEachScidCount {
            // If all messages for this phase have been processed, move to the next phase
            resetWatchdogTimer()
            NotificationCenter.default.removeObserver(self, name: .newOnionMessageWasReceived, object: nil)
            doNextRestorePhase()
        } else if let params = messageFetchParams,
                  params.messageCountForPhase % params.fetchLimit == 0 {
            // If there are more messages to fetch in this phase, reset the watchdog timer and fetch the next block
            resetWatchdogTimer()
            
            // Calculate new start index for the next block of messages to fetch
            let newStartIndex = params.fetchStartIndex + params.messageCountForPhase
            params.fetchStartIndex = newStartIndex
            params.fetchTargetIndex = newStartIndex + params.fetchLimit
            
            // Fetch the next block of first scid messages
            guard let seed = getAccountSeed() else {
                return
            }
            fetchFirstContactPerKey(seed: seed, lastMessageIndex: newStartIndex, msgCountLimit: params.fetchLimit)
        }
    }

    
    @objc func handleFetchAllMessages(notification: Notification) {
        guard let params = messageFetchParams,
              let totalHighestIndex = self.msgTotalCounts?.totalMessageMaxIndex else {
            finishRestoration()
            return
        }

        // Assuming each notification represents one message processed, adjust fetchStartIndex accordingly
        params.messageCountForPhase += params.fetchDirection == .backward ? -1 : 1

        // Determine the lower boundary to trigger the next fetch block
        let nextFetchTriggerIndex = params.fetchDirection == .backward ? params.fetchStartIndex - params.fetchLimit + 1 : params.fetchStartIndex + params.fetchLimit - 1

        // Determine if the next block should be fetched based on direction and boundaries
        let shouldFetchNextBlock = params.fetchDirection == .backward ? params.messageCountForPhase <= nextFetchTriggerIndex && params.messageCountForPhase >= ((params.stopIndex ?? 0)) : params.messageCountForPhase >= nextFetchTriggerIndex && params.messageCountForPhase <= totalHighestIndex

        if let messageCount = messageFetchParams?.messageCountForPhase,
           let totalMsgCount = msgTotalCounts?.totalMessageAvailableCount,
           let messageRestoreCallback = messageRestoreCallback,
            totalMsgCount > 0 {
            let messagesCounted : Int = (params.fetchDirection) == .backward ? (totalMsgCount - messageCount) : (messageCount)
            let percentage = (Double(messagesCounted + 1) / Double(totalMsgCount)) * 100
            let pctInt = Int(percentage.rounded())
            messageRestoreCallback(pctInt)
        }
        
        if shouldFetchNextBlock {
            if params.messageCountForPhase <= (params.stopIndex ?? -1) + 1 ?? 0{
                finishRestoration()
                return
            }
            // Adjust the start index for the next block
            let newFetchStartIndex = params.fetchDirection == .backward ? max(params.fetchStartIndex - params.fetchLimit, params.stopIndex ?? 0) : min(params.fetchStartIndex + params.fetchLimit, totalHighestIndex)
            params.fetchStartIndex = newFetchStartIndex

            // Fetch the next block
            fetchMessageBlock(
                seed: getAccountSeed() ?? "",
                lastMessageIndex: newFetchStartIndex,
                msgCountLimit: params.fetchLimit,
                fetchDirection: params.fetchDirection
            )
        } else if params.fetchDirection == .backward && params.messageCountForPhase <= ((params.stopIndex ?? 0) + 1) {
            // Conclude the restoration if we have reached or exceeded the stop index
            finishRestoration()
        } else if params.fetchDirection == .forward && params.fetchStartIndex > totalHighestIndex {
            // Conclude the restoration if we have reached or exceeded the total highest index in forward direction
            finishRestoration()
        }
    }


    
    func resetWatchdogTimer() {
        // Invalidate any existing timer
        watchdogTimer?.invalidate()
        
        // Start a new timer
        watchdogTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(watchdogTimerFired), userInfo: nil, repeats: false)
    }
    
    @objc func watchdogTimerFired() {
        // This method is called when the watchdog timer expires

        // Perform cleanup or restart attempts here
        NotificationCenter.default.removeObserver(self, name: .newOnionMessageWasReceived, object: nil)
        
        // Log or handle the timeout as needed
        print("Watchdog timer expired - Fetch process may be stalled or complete.")
        resetFromRestore()
        // Optionally, attempt to restart the process or notify the user
    }
    
    func finishRestoration() {
        // Concluding the restoration or synchronization process
        NotificationCenter.default.removeObserver(self, name: .newOnionMessageWasReceived, object: nil)
        resetWatchdogTimer()
        messageFetchParams?.restoreInProgress = false
        // Additional logic for setting the last message index in UserData or similar actions
        if let counts = msgTotalCounts,
           let maxIndex = counts.totalMessageMaxIndex{
            UserData.sharedInstance.setLastMessageIndex(index: maxIndex)
            resetFromRestore()
        }
    }
    
    func resetFromRestore(){
        for chat in Chat.getAll(){
            if let lastMessage = TransactionMessage.getMaxIndexMessageFor(chat: chat){
                chat.lastMessage = lastMessage
            }
        }
        for deleteRequest in TransactionMessage.getMessageDeletionRequests(){
            if let replyUUID = deleteRequest.replyUUID,
               let messageToDelete = TransactionMessage.getMessageWith(uuid: replyUUID){
                messageToDelete.status = TransactionMessage.TransactionMessageStatus.deleted.rawValue
                messageToDelete.managedObjectContext?.saveContext()
            }
        }
        
        self.isV2InitialSetup = false
        self.contactRestoreCallback = nil
        self.messageRestoreCallback = nil
        self.updateIsPaidAllMessages() // ensure all paid invoices are marked as such
//        if let hideRestoreCallback = hideRestoreCallback{
//            hideRestoreCallback()
//        }
    }

}
