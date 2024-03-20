//
//  SphinxOnionManager+AccountRestore.swift
//  sphinx
//
//  Created by James Carucci on 3/20/24.
//  Copyright © 2024 sphinx. All rights reserved.
//

import Foundation

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
        var lastMessageIndex = 0
        var indexStepSize = 50
        //emulating getAllUnreadMessages()
        while(lastMessageIndex <= UserData.sharedInstance.getLastMessageIndex() ?? -1){
            let rr = try! fetchMsgs(seed: seed, uniqueTime: getTimeWithEntropy(), state: loadOnionStateAsData(), lastMsgIdx: UInt64(lastMessageIndex), limit: UInt32(indexStepSize))
            handleRunReturn(rr: rr)
            
            var nextBlockWasReceived = false
            var timeOutDidOccur = false
            
            while(nextBlockWasReceived == false && timeOutDidOccur == false){
                
            }
            
            DelayPerformedHelper.performAfterDelay(seconds: 1.5, completion: {
                lastMessageIndex = UserData.sharedInstance.getLastMessageIndex() ?? 0
            })
        }
    }
    
}
