//
//  SphinxOnionManager+HandleStateExtension.swift
//  sphinx
//
//  Created by James Carucci on 12/19/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import MessagePack
import CocoaMQTT


extension SphinxOnionManager {
    func handleRunReturn(rr: RunReturn){
        if let sm = rr.stateMp{
            //update state map
            let _ = storeOnionState(inc: sm.bytes)
        }
        
        if let topic0 = rr.topic0{
            pushRRTopic(topic: topic0, payloadData: rr.payload0)
        }
        
        if let topic1 = rr.topic1{
            pushRRTopic(topic: topic1, payloadData: rr.payload1)
        }
        
        if let topic2 = rr.topic2{
            pushRRTopic(topic: topic2, payloadData: rr.payload2)
        }
        
        if let mci = rr.myContactInfo{
            let components = mci.split(separator: "_").map({String($0)})
            if components.count == 3{
                createSelfContact(scid: components[2], serverPubkey: components[1],myOkKey: components[0])
            }
        }
        
        if let balance = rr.newBalance{
            NotificationCenter.default.post(Notification(name: .onBalanceDidChange, object: nil, userInfo: ["balance" : balance]))
        }
        
        // set your balance
    //          // incoming message json
    //          if (rr.msg) {
    //            // any time there is a "msg"
    //            // there will also be a "msg_uuid" and "msg_index"
    //            console.log("=> received msg", rr.msg, rr.msg_uuid, rr.msg_index);
    //          }
    //          // incoming sender info json
    //          if (rr.msg_sender) {
    //            // you can parse this JSON, and check the "pubkey" field
    //            // to see if its new or updated or not.
    //            console.log("=> received msg_sender", rr.msg_sender);
    //          }
    //          // sent
    //          if (rr.sent_status) {
    //            console.log("=> sent_status", rr.sent_status);
    //          }
    //          // settled
    //          if (rr.settled_status) {
    //            console.log("=> settled_status", rr.settled_status);
    //          }
    //          // incoming error string?
    //          if (rr.error) {
    //            console.log("=> error", rr.error);
    //          }
    }

    func pushRRTopic(topic:String,payloadData:Data?){
        let byteArray: [UInt8] = payloadData != nil ? [UInt8](payloadData!) : [UInt8]()
        self.mqtt.publish(
            CocoaMQTTMessage(
                topic: topic,
                payload: byteArray
            )
        )
    }


    var mutationKeys: [String] {
        get {
            if let onionState: String = UserDefaults.Keys.onionState.get() {
                return onionState.components(separatedBy: ",")
            }
            return []
        }
        set {
            UserDefaults.Keys.onionState.set(
                newValue.joined(separator: ",")
            )
        }
    }
    
    func loadOnionStateAsData() -> Data {
        let state = loadOnionState()
        
        var mpDic = [MessagePackValue:MessagePackValue]()

        for (key, value) in state {
            mpDic[MessagePackValue(key)] = MessagePackValue(Data(value))
        }
        
        let stateBytes = pack(
            MessagePackValue(mpDic)
        ).bytes
        
        return Data(stateBytes)
    }

    func loadOnionState() -> [String: [UInt8]] {
        var state:[String: [UInt8]] = [:]
        
        for key in mutationKeys {
            if let value = UserDefaults.standard.object(forKey: key) as? [UInt8] {
                state[key] = value
            }
        }
        return state
    }
    

    func storeOnionState(inc: [UInt8]) -> [NSNumber] {
        let muts = try? unpack(Data(inc))
        
        guard let mutsDictionary = (muts?.value as? MessagePackValue)?.dictionaryValue else {
            return []
        }
        
        persist_muts(muts: mutsDictionary)

        return []
    }

    func persist_muts(muts: [MessagePackValue: MessagePackValue]) {
        var keys: [String] = []
        
        for  mut in muts {
            if let key = mut.key.stringValue, let value = mut.value.dataValue?.bytes {
                keys.append(key)
              
                UserDefaults.standard.set(value, forKey: key)
                UserDefaults.standard.synchronize()
            }
        }
        
        keys.append(contentsOf: mutationKeys)
        mutationKeys = keys
    }

}
