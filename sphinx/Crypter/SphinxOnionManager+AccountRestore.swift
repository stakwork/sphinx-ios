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
    var fetchDirection: FetchDirection
    var arbitraryStartIndex: Int?
    var stopIndex: Int?

    enum FetchDirection {
        case forward, backward
    }

    init(restoreInProgress: Bool, fetchStartIndex: Int, fetchTargetIndex: Int, fetchLimit: Int, blockCompletionHandler: (() -> ())?, initialCount:Int, fetchDirection: FetchDirection = .backward, arbitraryStartIndex: Int? = nil, stopIndex: Int? = nil) {
        self.restoreInProgress = restoreInProgress
        self.fetchStartIndex = fetchStartIndex
        self.fetchTargetIndex = fetchTargetIndex
        self.fetchLimit = fetchLimit
        self.blockCompletionHandler = blockCompletionHandler
        self.messageCountForPhase = initialCount
        self.fetchDirection = fetchDirection
        self.arbitraryStartIndex = arbitraryStartIndex
        self.stopIndex = stopIndex
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
//        self.messageRestoreCallback = messageRestoreCallback
//        self.contactRestoreCallback = contactRestoreCallback
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
            restoreAllMessages()
            break
        case .allMessages:
            messageFetchParams.restoreInProgress = false
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
        
        let indexStepSize = 50
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
        do{
            let rr = try fetchFirstMsgsPerKey(seed: seed, uniqueTime: getTimeWithEntropy(), state: loadOnionStateAsData(), lastMsgIdx: UInt64(lastMessageIndex), limit: UInt32(msgCountLimit), reverse: false)
            handleRunReturn(rr: rr)
        }
        catch{
            
        }
    }
    
    func restoreAllMessages(fetchDirection: MessageFetchParams.FetchDirection = .backward, arbitraryStartIndex: Int? = nil) {
        // Use the highest index as the starting point for backward fetching
        let startIndex = arbitraryStartIndex ?? (msgTotalCounts?.totalMessageMaxIndex ?? 0)
        
        // Begin the fetching process
        startAllMsgBlockFetch(startIndex: startIndex, indexStepSize: 50, fetchDirection: fetchDirection)
    }

    func syncMessagesSinceLastKnownIndexHeight(){
        guard let lastKnownHeight = UserData.sharedInstance.getLastMessageIndex() else{
            return
        }
        
        let startIndex = (msgTotalCounts?.totalMessageMaxIndex ?? 0)
        
        // Begin the fetching process
        startAllMsgBlockFetch(startIndex: startIndex, indexStepSize: 50, fetchDirection: .backward, stopIndex: lastKnownHeight)
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
            lastMessageIndex: startIndex, // Ensure we start from 150 for backward fetch
            msgCountLimit: indexStepSize,
            fetchDirection: fetchDirection
        )
    }


    
    func fetchMessageBlock(seed: String, lastMessageIndex: Int, msgCountLimit: Int, fetchDirection: MessageFetchParams.FetchDirection) {
        let reverse = fetchDirection == .backward
        let safeLastMsgIndex = max(lastMessageIndex, 0)
        do {
            let rr = try fetchMsgsBatch(
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
           let totalMsgCount = msgTotalCounts?.totalMessageAvailableCount,
           let contactRestoreCallback = contactRestoreCallback{
            let percentage = (Double(messageCount) / Double(totalMsgCount)) * 100
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
              let totalHighestIndex = msgTotalCounts?.totalMessageMaxIndex else { return }

        if params.fetchDirection == .backward {
            // Decrement the start index for the next batch in backward fetching
            params.fetchStartIndex -= params.fetchLimit

            // Stop fetching if we've reached the beginning
            if params.fetchStartIndex <= (messageFetchParams?.stopIndex ?? 0) {
                if let maxIndex = msgTotalCounts?.totalMessageMaxIndex{
                    UserData.sharedInstance.setLastMessageIndex(index: maxIndex)
                }
                finishRestoration()
                return
            }
        } else {
            // Increment the start index for the next batch in forward fetching
            params.fetchStartIndex += params.fetchLimit

            // Stop fetching if we've reached or exceeded the highest index
            if params.fetchStartIndex >= totalHighestIndex {
                finishRestoration()
                return
            }
        }

        // Fetch the next batch of messages
        fetchMessageBlock(
            seed: getAccountSeed() ?? "",
            lastMessageIndex: params.fetchStartIndex,
            msgCountLimit: params.fetchLimit,
            fetchDirection: params.fetchDirection
        )
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
        
        // Optionally, attempt to restart the process or notify the user
    }
    
    func finishRestoration() {
        NotificationCenter.default.removeObserver(self, name: .newOnionMessageWasReceived, object: nil)
        resetWatchdogTimer() // Stop the watchdog timer as fetching is complete
        messageFetchParams?.restoreInProgress = false
        // Optionally, notify UI that restoration is complete
    }

}
