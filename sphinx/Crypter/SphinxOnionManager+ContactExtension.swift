//
//  SphinxOnionManager+ContactExtension.swift
//  sphinx
//
//  Created by James Carucci on 12/4/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import CocoaMQTT
import ObjectMapper
import SwiftyJSON

extension SphinxOnionManager{//contacts related
    func saveLSPServerData(retrievedCredentials:SphinxOnionBrokerResponse){
        let server = Server(context: managedContext)

        server.pubKey = retrievedCredentials.serverPubkey
        server.ip = self.server_IP
        (shouldPostUpdates) ?  NotificationCenter.default.post(Notification(name: .onMQTTConnectionStatusChanged, object: nil, userInfo: ["server" : server])) : ()
        self.currentServer = server
        managedContext.saveContext()
    }
    
    func createSelfContact(scid:String,serverPubkey:String,myOkKey:String){
        self.pendingContact = UserContact(context: managedContext)
        self.pendingContact?.scid = scid
        self.pendingContact?.isOwner = true
        self.pendingContact?.index = 0
        self.pendingContact?.publicKey = myOkKey
        self.pendingContact?.routeHint = "\(serverPubkey)_\(scid)"
        self.pendingContact?.status = UserContact.Status.Confirmed.rawValue
        managedContext.saveContext()
    }
    
    func parseContactInfoString(routeHint:String)->(String,String,String)?{
        let components = routeHint.split(separator: "_").map({String($0)})
        return (components.count == 3) ? (components[0],components[1],components[2]) : nil
    }
    
    func makeFriendRequest(
        contactInfo:String,
        nickname:String?=nil
    ){
        guard let (recipientPubkey, recipLspPubkey,scid) = parseContactInfoString(routeHint: contactInfo) else{
            return
        }
//        if let existingContact = UserContact.getContactWithDisregardStatus(pubkey: recipientPubkey){
//            AlertHelper.showAlert(title: "Error", message: "Contact already exists for \(existingContact.nickname ?? "this contact")")
//            return
//        }
        
        let routeHint = "\(recipLspPubkey)_\(scid)"
        guard let mnemonic = UserData.sharedInstance.getMnemonic(),
              let seed = getAccountSeed(mnemonic: mnemonic),
              let xpub = getAccountXpub(seed: seed),
              let nextIndex = UserContact.getNextAvailableContactIndex()
        else{
            return
        }
        let idx = UInt32(nextIndex)
        let time = getTimestampInMilliseconds()
        do{
            let childPubKey = try pubkeyFromSeed(seed: seed, idx: idx, time: time, network: network)
            let success = connectToBroker(seed: seed, xpub: xpub)
            if (success == false){return}
            
            createNewContact(pubkey: recipientPubkey, childPubkey: childPubKey, routeHint: routeHint, idx: nextIndex,nickname:nickname)
            
            mqtt.didReceiveMessage = { mqtt, receivedMessage, id in
                self.processMqttMessages(message: receivedMessage)
            }
            
            //subscribe to relevant topics
            mqtt.didConnectAck = { _, _ in
                //self.showSuccessWithMessage("MQTT connected")
                print("SphinxOnionManager: MQTT Connected")
                print("mqtt.didConnectAck")
                self.mqtt.subscribe([
                    ("\(childPubKey)/\(idx)/res/#", CocoaMQTTQoS.qos1)
                ])
                self.mqtt.publish(
                    CocoaMQTTMessage(
                        topic: "\(childPubKey)/\(idx)/req/register",
                        payload: []
                    )
                )
            }
        }
        catch{
            print("error: \(error)")
        }
    }
    
    func createNewContact(
        pubkey:String,
        childPubkey:String,
        routeHint:String,
        idx:Int,
        scid:String?=nil,
        nickname:String?=nil
    ){
        let contact = UserContact(context: managedContext)
        contact.publicKey = pubkey//
        contact.childPubKey = childPubkey
        contact.routeHint = routeHint//
        contact.index = idx//
        contact.id = idx
        contact.isOwner = false//
        contact.nickname = nickname
        contact.createdAt = Date()
        contact.status = UserContact.Status.Pending.rawValue
        
        managedContext.saveContext()
    }
    
    func processContact(from mqttTopic:String, retrievedCredentials: SphinxOnionBrokerResponse){
        guard let topicParams = getValidatedRegisterTopicParams(topic:mqttTopic),
              let scid = retrievedCredentials.scid,
              let serverPubkey = retrievedCredentials.serverPubkey,
              let mnemonic = UserData.sharedInstance.getMnemonic(),
              let seed = getAccountSeed(mnemonic: mnemonic),
              let myPubkey = getAccountOnlyKeysendPubkey(seed: seed) else{
            AlertHelper.showAlert(title: "pub.key.options-add.contact.error.title".localized, message: "pub.key.options-add.contact.error.message".localized)
              return
          }
        if(mqttTopic.contains(myPubkey)){//"self" contact case
            let myOkKey = topicParams[0]
            createSelfContact(scid: scid, serverPubkey: serverPubkey,myOkKey: myOkKey)
            saveLSPServerData(retrievedCredentials: retrievedCredentials)//only save LSP if it's a self contact
        }
        else if let index = Int(topicParams[1]),
                let existingContact = UserContact.getContactWith(indices: [index]).first{
            NotificationCenter.default.post(Notification(name: .newContactWasRegisteredWithServer, object: nil, userInfo: ["contactIndex" : existingContact.publicKey]))
            existingContact.contactRouteHint = "\(serverPubkey)_\(scid)"
            existingContact.scid = scid
            CoreDataManager.sharedManager.saveContext()
            
            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {//give new contact time to take to DB
                self.sendKeyExchangeMsg(isInitiatorMe: true, to: existingContact)
            })
            
        }
        else{//falls thorugh & should not hit..throw error
            print("error")
        }
    }
    
    func getValidatedRegisterTopicParams(topic:String) -> [String]?{
        let topicParams = topic.split(separator: "/")
        if topicParams.count != 4{
            AlertHelper.showAlert(title: "pub.key.options-add.contact.error.title".localized, message: "pub.key.options-add.contact.error.message".localized)
            return nil
        }
        return topicParams.map({String($0)})
    }
}


extension SphinxOnionManager{//Composing outgoing messages & processing incoming messages
    
    func getHopsJSON(serverPubkey:String,recipPubkey:String)->String?{
        let hopsArray: [[String: String]] = [
            ["pubkey": "\(serverPubkey)"],
            ["pubkey": "\(recipPubkey)"]
        ]

        // Serialize the hopsArray to JSON
        guard let hopsJSON = try? JSONSerialization.data(withJSONObject: hopsArray, options: []),
              let hopsJSONString = String(data: hopsJSON, encoding: .utf8) else {
            return nil
        }
        
        return hopsJSONString
    }
    
    func getSenderInfo(for recipContact: UserContact, myOkKey:String,selfRouteHint:String,selfContact:UserContact) -> [String:Any]{
        let senderInfo : [String:String] = [
            "pubkey": myOkKey,
            "routeHint": selfRouteHint,
            "contactPubkey": recipContact.childPubKey,
            "contactRouteHint": selfContact.routeHint!,
            "alias": (selfContact.nickname ?? "anon"),
            "photo_url": ""
        ]
        
        return senderInfo
    }
    
    func constructKeyExchangeJSONString(isInitiatorMe:Bool,
                                        recipPubkey:String,
                                        recipRouteHint:String,
                                        myOkKey:String,
                                        selfRouteHint:String,
                                        selfContact:UserContact,
                                        recipContact:UserContact)->(String,String)?{
        let serverPubkey = recipRouteHint.split(separator: "_")[0]
        let scid = recipRouteHint.split(separator: "_")[1]

        let senderInfo = getSenderInfo(for: recipContact,myOkKey:myOkKey,selfRouteHint: selfRouteHint,selfContact:selfContact)
                
        guard let hopsJSONString = getHopsJSON(serverPubkey: String(serverPubkey), recipPubkey: recipPubkey) else{
            return nil
        }
        
        let msg : [String:Any] = [
            "type": isInitiatorMe ? SphinxMsgTypes.KeyExchangeInitiator.rawValue : SphinxMsgTypes.KeyExchangeConfirmation.rawValue,
            "sender": senderInfo,
            "message":["content":""]
        ]
        
        guard let contentData = try? JSONSerialization.data(withJSONObject: msg),
              let contentJSONString = String(data: contentData, encoding: .utf8)
               else{
            return nil
        }
        
        (shouldPostUpdates) ?  NotificationCenter.default.post(Notification(name: .keyExchangeResponseMessageWasConstructed, object: nil, userInfo: ["hopsJSON" : hopsJSONString, "contentStringJSON": senderInfo])) : ()
        
        return (contentJSONString,hopsJSONString)
    }
    
    func sendKeyExchangeMsg(isInitiatorMe:Bool,to contact: UserContact) -> SphinxMsgError? {
        guard let mnemonic = UserData.sharedInstance.getMnemonic(),
              let seed = getAccountSeed(mnemonic: mnemonic),
              let myOkKey = getAccountOnlyKeysendPubkey(seed: seed) else {
            return SphinxMsgError.credentialsError
        }
        guard let recipPubkey = contact.publicKey, // OK key
              let recipRouteHint = contact.contactRouteHint,
              recipRouteHint.split(separator: "_").count == 2 else {
            return SphinxMsgError.contactDataError
        }

        guard let selfContact = UserContact.getSelfContact(),
              let selfRouteHint = selfContact.routeHint else {
            return SphinxMsgError.credentialsError
        }
        
        
        let time = getTimestampInMilliseconds()
        
        if(isInitiatorMe){
            self.mqtt.subscribe("\(myOkKey)/0/res/#")
            self.mqtt.subscribe("\(contact.childPubKey)/\(contact.index)/res/#")
        }
        
        guard let (contentJSONString,hopsJSONString) = constructKeyExchangeJSONString(isInitiatorMe: isInitiatorMe, recipPubkey: recipPubkey, recipRouteHint: recipRouteHint,myOkKey: myOkKey, selfRouteHint: selfRouteHint, selfContact: selfContact, recipContact: contact) else{
            return SphinxMsgError.encodingError
        }
        
        do {
            let onion = try! createOnionMsg(seed: seed, idx: UInt32(0), time: time, network: network, hops: hopsJSONString, json: contentJSONString)
            //let onion = try! createOnion(seed: seed, idx: UInt32(0), time: time, network: network, hops: hopsJSONString, payload: finalData)
            var onionAsArray = [UInt8](repeating: 0, count: onion.count)

            // Use withUnsafeBytes to copy the Data into the UInt8 array
            onion.withUnsafeBytes { bufferPointer in
                guard let baseAddress = bufferPointer.baseAddress else {
                    fatalError("Failed to get the base address")
                }
                memcpy(&onionAsArray, baseAddress, onion.count)
                self.mqtt.publish(
                    CocoaMQTTMessage(
                        topic: "\(myOkKey)/0/req/send",
                        payload: onionAsArray
                    )
                )
            }

        } catch {
            return SphinxMsgError.encodingError
        }

        return nil
    }
    
}


//MARK: Helper Structs & Functions:

// Parsing Helper Struct
struct SphinxOnionBrokerResponse: Mappable {
    var scid: String?
    var serverPubkey: String?
    var myPubkey: String?

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        scid <- map["scid"]
        serverPubkey <- map["server_pubkey"]
    }
}


enum SphinxMsgTypes: UInt8{
    case PlaintextMessage = 0
    case KeyExchangeInitiator = 10
    case KeyExchangeConfirmation = 11
}

enum SphinxMsgError: Error {
    case encodingError
    case credentialsError //can't get access to my Private Keys/other data!
    case contactDataError // not enough data about contact!
}


