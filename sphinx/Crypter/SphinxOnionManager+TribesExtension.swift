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
    
    func joinTribe(tribePubkey:String){
        guard let seed = getAccountSeed() else{
            return
        }
        do{
           let rr = try! sphinx.joinTribe(seed: seed, uniqueTime: getEntropyString(), state: loadOnionStateAsData(), tribePubkey: "03b0d6fc6549db3134a01dcadf3d26b0faa201c46aa34fa019135f5ffe7aa256ee", tribeRouteHint: "03b8873a89885aa54cd8d98a639a793e43d27100ee17638a00c3685d29a64b3c6e_529771090552487942", alias: "test", amtMsat: 10000)
            handleRunReturn(rr: rr)
        }
        catch{
            
        }
    }
    
    
    
    
}
