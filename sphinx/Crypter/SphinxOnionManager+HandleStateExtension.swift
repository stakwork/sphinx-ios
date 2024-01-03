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
import ObjectMapper
import SwiftyJSON


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
            if let components = parseContactInfoString(routeHint: mci),
               UserContact.getContactWithDisregardStatus(pubkey: components.0) == nil{//only add this if we don't already have a "self" contact
                createSelfContact(scid: components.2, serverPubkey: components.1,myOkKey: components.0)
            }
        }
        
        if let balance = rr.newBalance{
            NotificationCenter.default.post(Notification(name: .onBalanceDidChange, object: nil, userInfo: ["balance" : balance]))
        }
        
        
        if let message = rr.msg,
           let type = rr.msgType{
            if type == TransactionMessage.TransactionMessageType.message.rawValue,
               var plaintextMessage = PlaintextMessageFromServer(JSONString: message),
               let sender = rr.msgSender,
               let uuid = rr.msgUuid,
               let index = rr.msgIndex,
               let csr = ContactServerResponse(JSONString: sender){
                plaintextMessage.senderPubkey = csr.pubkey
                plaintextMessage.uuid = uuid
                plaintextMessage.index = index
                processPlaintextMessage(message: plaintextMessage)
            }
            print("handleRunReturn message: \(message)")
        }
        
        if let sender = rr.msgSender,
           let csr = ContactServerResponse(JSONString: sender),
           let senderPubkey = csr.pubkey{
            print(sender)
            let type = rr.msgType ?? 255
            if type == TransactionMessage.TransactionMessageType.contactKeyConfirmation.rawValue || true, // incoming key exchange confirmation
               let existingContact = UserContact.getContactWithDisregardStatus(pubkey: senderPubkey){ // if contact exists it's a key exchange response from them or it exists already
                NotificationCenter.default.post(Notification(name: .newContactWasRegisteredWithServer, object: nil, userInfo: ["contactPubkey" : existingContact.publicKey]))
                if existingContact.getChat() == nil{
                    createChat(for: existingContact)
                }
                existingContact.nickname = csr.alias
                existingContact.status = UserContact.Status.Confirmed.rawValue
                CoreDataManager.sharedManager.saveContext()
            }
            else if type == TransactionMessage.TransactionMessageType.contactKey.rawValue || true, // incoming key exchange request
                let newContactRequest = createNewContact(pubkey: senderPubkey, nickname: csr.alias, photo_url: csr.photoUrl, person: csr.person){//new contact from a key exchange message
                NotificationCenter.default.post(Notification(name: .newContactWasRegisteredWithServer, object: nil, userInfo: ["contactPubkey" : newContactRequest.publicKey]))
                newContactRequest.status = UserContact.Status.Confirmed.rawValue
                createChat(for: newContactRequest)
                print("\n\n\n handleRunReturn L64 - NEW CONTACT RECEIVED: \(newContactRequest)")
                managedContext.saveContext()
            }
        }
        
        if let sentStatus = rr.sentStatus{
            
        }
        
        if let settledStatus = rr.settledStatus{
            
        }
        
        if let error = rr.error {
            
        }
        
    }

    func pushRRTopic(topic:String,payloadData:Data?){
        let byteArray: [UInt8] = payloadData != nil ? [UInt8](payloadData!) : [UInt8]()
        print("pushRRTopic | topic:\(topic) | payload:\(byteArray)")
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

    private func loadOnionState() -> [String: [UInt8]] {
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

    private func persist_muts(muts: [MessagePackValue: MessagePackValue]) {
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


struct ContactServerResponse: Mappable {
    var pubkey: String?
    var alias: String?
    var photoUrl: String?
    var person: String?

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        pubkey    <- map["pubkey"]
        alias     <- map["alias"]
        photoUrl  <- map["photo_url"]
        person    <- map["person"]
    }
    
}


struct PlaintextMessageFromServer: Mappable {
    var content:String?
    var amount:Int?
    var senderPubkey:String?=nil
    var uuid:String?=nil
    var index:String?=nil

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        content    <- map["content"]
        amount     <- map["amount"]
    }
    
}
