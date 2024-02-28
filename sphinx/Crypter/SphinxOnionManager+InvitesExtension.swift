//
//  SphinxOnionManager+InvitesExtension.swift
//  sphinx
//
//  Created by James Carucci on 2/27/24.
//  Copyright © 2024 sphinx. All rights reserved.
//

import Foundation

extension SphinxOnionManager{//invites related
    
    func issueInvite(host:String,amountMsat:Int)->String?{
        guard let seed = getAccountSeed() else{
            return nil
        }
        do{
            let rr = try! makeInvite(seed: seed, uniqueTime: getEntropyString(), state: loadOnionStateAsData(), host: host, amtMsat: UInt64(amountMsat))
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
        }
        catch{
        }
    }
    
    
}
