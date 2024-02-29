//
//  SphinxOnionManager+InvitesExtension.swift
//  sphinx
//
//  Created by James Carucci on 2/27/24.
//  Copyright © 2024 sphinx. All rights reserved.
//

import Foundation

extension SphinxOnionManager{//invites related
    
    func issueInvite(amountMsat:Int)->String?{
        guard let seed = getAccountSeed(),
            let selfContact = UserContact.getSelfContact(),
            let nickname = selfContact.nickname else{
            return nil
        }
        do{
            
            let rr = try! makeInvite(seed: seed, uniqueTime: getEntropyString(), state: loadOnionStateAsData(), host: self.server_IP, amtMsat: UInt64(amountMsat), myAlias: nickname)
            handleRunReturn(rr: rr)
            return rr.newInvite
        }
        catch{
            return nil
        }
    }
    
    func redeemInvite(inviteCode:String){
        guard let seed = getAccountSeed() else{
            return
        }
        do{
            let rr = try! processInvite(seed: seed, uniqueTime: getEntropyString(), state: loadOnionStateAsData(), inviteQr: inviteCode)
            handleRunReturn(rr: rr)
            if let lsp = rr.lspHost{
                self.server_IP = lsp
            }
            self.stashedContactInfo = rr.inviterContactInfo
            self.stashedInitialTribe = rr.initialTribe
            self.stashedInviteCode = inviteCode
            self.stashedInviterAlias = rr.inviterAlias
        }
        catch{
            return
        }
    }
    
    
    func doInitialInviteSetup(){
        guard let stashedInviteCode = stashedInviteCode else{
            return
        }
        if let stashedContactInfo = stashedContactInfo{
            makeFriendRequest(contactInfo: stashedContactInfo,inviteCode: stashedInviteCode)
        }
        if let stashedInitialTribe = stashedInitialTribe{
            //joinTribe(tribePubkey: <#T##String#>, routeHint: <#T##String#>)
        }
    }
    
}
