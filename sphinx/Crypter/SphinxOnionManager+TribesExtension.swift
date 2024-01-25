//
//  SphinxOnionManager+TribesExtension.swift
//  sphinx
//
//  Created by James Carucci on 1/22/24.
//  Copyright © 2024 sphinx. All rights reserved.
//

import Foundation
import Foundation
import CocoaMQTT
import ObjectMapper
import SwiftyJSON

extension SphinxOnionManager{//tribes related
    
    func createTribe(){
        guard let seed = getAccountSeed() else{
            return
        }
        let pubkey = getAccountOnlyKeysendPubkey(seed: seed)
        let tribe = [
            "name":"myTribe \(CrypterManager.sharedInstance.generateCryptographicallySecureRandomBytes(count: 1000))"
        ]
        guard let tribeData = try? JSONSerialization.data(withJSONObject: tribe),
              let tribeJSONString = String(data: tribeData, encoding: .utf8)
               else{
            return
        }
        do{
            try! sphinx.createTribe(seed: seed, uniqueTime: getEntropyString(), state: loadOnionStateAsData(), tribeServerPubkey: pubkey!, tribeJson: tribeJSONString)
        }
        catch{
            
        }
    }
    
    func joinTribe(tribePubkey:String,routeHint:String ,alias:String?=nil){
        guard let seed = getAccountSeed() else{
            return
        }
        do{
           let rr = try! sphinx.joinTribe(seed: seed, uniqueTime: getEntropyString(), state: loadOnionStateAsData(), tribePubkey: tribePubkey, tribeRouteHint: routeHint, alias: alias ?? "test", amtMsat: 10000)
            handleRunReturn(rr: rr)
        }
        catch{
            
        }
    }
    
    
    
    
}
