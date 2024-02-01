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
    
    func createTribe(params:[String:Any]){
        guard let seed = getAccountSeed() else{
            return
        }
        
        guard let tribeData = try? JSONSerialization.data(withJSONObject: params),
              let tribeJSONString = String(data: tribeData, encoding: .utf8)
               else{
            return
        }
        do{
            let rr = try! sphinx.createTribe(seed: seed, uniqueTime: getEntropyString(), state: loadOnionStateAsData(), tribeServerPubkey: "0356091a4d8a1bfa8e2b9d19924bf8275dd057536e12427c557dd91a6cb1c03e8b", tribeJson: tribeJSONString)
            handleRunReturn(rr: rr)
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
    
    func exitTribe(tribeChat:Chat){
        self.sendMessage(
            to: nil,
            content: "",
            chat: tribeChat,
            msgType: UInt8(TransactionMessage.TransactionMessageType.groupLeave.rawValue),
            threadUUID: nil,
            replyUUID: nil
        )
    }
    
    
}
