//
//  SphinxOnionManager.swift
//  
//
//  Created by James Carucci on 11/8/23.
//

import Foundation
import CocoaMQTT
import ObjectMapper
import SwiftyJSON


class SphinxOnionManager : NSObject {
    class var sharedInstance : SphinxOnionManager {
        struct Static {
            static let instance = SphinxOnionManager()
        }
        return Static.instance
    }
    
    var pendingContact : UserContact? = nil
    var currentServer : Server? = nil
    let newMessageBubbleHelper = NewMessageBubbleHelper()
    var shouldPostUpdates : Bool = false
    let server_IP = "34.229.52.200"
    let server_PORT = 1883
    //let test_mnemonic1 = "artist globe myself huge wing drive bright build agree fork media gentle"//TODO: stop using this in favor of one generated by user, backed up by hand and stored in secure memory
    let network = "regtest"
    var vc: UIViewController! = nil
    var mqtt: CocoaMQTT! = nil
    let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
    
    func getAccountSeed(mnemonic:String?=nil)->String?{
        do{
            if let mnemonic = mnemonic{
                let seed = try mnemonicToSeed(mnemonic: mnemonic)
                return seed
            }
            else if let mnemonic = UserData.sharedInstance.getMnemonic(){
                let seed = try mnemonicToSeed(mnemonic: mnemonic)
                return seed
            }
            else{
                return nil
            }
        }
        catch{
            print("error in getAccountSeed")
            return nil
        }
    }
    
    func generateMnemonic()->String?{
        var result : String? = nil
        do {
            result = try mnemonicFromEntropy(entropy: Data.randomBytes(length: 16).hexString)
            guard let result = result else{
                return nil
            }
            UserData.sharedInstance.save(walletMnemonic: result)
        }
        catch let error{
            print("error getting seed\(error)")
        }
        return result
    }
    
    func getAccountXpub(seed:String) -> String?  {
        do{
            let xpub = try xpubFromSeed(seed: seed, time: getEntropyString(), network: network)
            return xpub
        }
        catch{
            return nil
        }
    }
    
    func getAccountOnlyKeysendPubkey(seed:String)->String?{
        do{
            let pubkey = try pubkeyFromSeed(seed: seed, idx: 0, time: getEntropyString(), network: network)
            return pubkey
        }
        catch{
            return nil
        }
    }
    
    func getEntropyString()->String{
        let upperBound = 10_000_000_000
        let randomInt = CrypterManager().generateCryptographicallySecureRandomInt(upperBound: upperBound)
        let randomString = String(describing: randomInt!)
        return randomString
    }
    
    func connectToBroker(seed:String,xpub:String)->Bool{
        //        if let mqtt = mqtt{
        //            mqtt.disconnect()
        //        }
        
        
        //        if mqtt?.connState == .connected || mqtt?.connState == .connecting {
        //            showSuccessWithMessage("MQTT already connected or connecting")
        //            return true
        //        }
        do{
            let now = getEntropyString()
            let sig = try rootSignMs(seed: seed, time: now, network: network)
            
            mqtt = CocoaMQTT(clientID: xpub,host: server_IP ,port:  UInt16(server_PORT))
            mqtt.username = now
            mqtt.password = sig
            
            let success = mqtt.connect()
            print("mqtt.connect success:\(success)")
            return success
        }
        catch{
            return false
        }
    }
    
    
    
    func publishMyTopics(pubkey:String,idx:Int){
        self.mqtt.publish(
            CocoaMQTTMessage(
                topic: "\(pubkey)/\(idx)/req/balance",
                payload: []
            )
        )
        
        self.mqtt.publish(
            CocoaMQTTMessage(
                topic: "\(pubkey)/\(idx)/req/register",
                payload: []
            )
        )
        self.mqtt.publish(
            CocoaMQTTMessage(
                topic: "\(pubkey)/\(idx)/req/pubkey",
                payload: []
            )
        )
    }
    
    func disconnectMqtt(){
        if let mqtt = self.mqtt{
            mqtt.disconnect()
        }
    }
    
    func subscribeToMyTopics(pubkey:String,idx:Int){
        self.mqtt.subscribe([
            ("\(pubkey)/\(idx)/res/#", CocoaMQTTQoS.qos1)
        ])

    }

    func subscribeAllContactChildKeys(){
        for contact in UserContact.getAll(){
            let contactChildKey = contact.childPubKey
            let contactIdx = contact.index
            subscribeToContactChildPubkey(contactChildKey: contactChildKey, contactIdx: contactIdx)
        }
    }

    func subscribeToContactChildPubkey(contactChildKey:String, contactIdx:Int){
        self.mqtt.subscribe([
            ("\(contactChildKey)/\(contactIdx)/res/#", CocoaMQTTQoS.qos1)
        ])
    }

    func getAllUnreadMessages(){
        getUnreadOkKeyMessages()
//        for contact in UserContact.getAll(){
//            getUnreadMessages(from: contact)
//        }
    }

    func getUnreadOkKeyMessages(sinceIndex:Int?=nil,limit:Int?=nil){
        guard let mnemonic = UserData.sharedInstance.getMnemonic(),
              let seed = getAccountSeed(mnemonic: mnemonic),
              let myOkKey = getAccountOnlyKeysendPubkey(seed: seed) else {
            return //throw error?
        }
        let sinceMsgIndex = 0//UserData.sharedInstance.getLastMessageIndex() != nil ? UserData.sharedInstance.getLastMessageIndex()! + 1 : 0 //TODO: store last read index?
        let msgCountLimit = limit ?? 50
        let topic = "\(myOkKey)/\(0)/req/msgs"
        requestUnreadMessages(on: topic, sinceMsgIndex: sinceMsgIndex, msgCountLimit: msgCountLimit)
    }

    func getUnreadMessages(from contact: UserContact){
        let contactChildKey = contact.childPubKey
        let contactIdx = contact.index
        let sinceMsgIndex = 0 //TODO: store last read index?
        let msgCountLimit = 1000
        let topic = "\(contactChildKey)/\(contactIdx)/req/msgs"
        requestUnreadMessages(on: topic, sinceMsgIndex: sinceMsgIndex, msgCountLimit: msgCountLimit)
    }

    func requestUnreadMessages(on topic:String,sinceMsgIndex:Int, msgCountLimit:Int){
        let msgDict: [String: Int] = [
            "since": sinceMsgIndex,
            "limit": msgCountLimit
        ]

        // Serialize the hopsArray to JSON
        guard let msgJSON = try? JSONSerialization.data(withJSONObject: msgDict, options: []) else {

            return
        }

        var msgAsArray = [UInt8](repeating: 0, count: msgJSON.count)

        // Use withUnsafeBytes to copy the Data into the UInt8 array
        msgJSON.withUnsafeBytes { bufferPointer in
            guard let baseAddress = bufferPointer.baseAddress else {
                fatalError("Failed to get the base address")
            }
            memcpy(&msgAsArray, baseAddress, msgJSON.count)
            self.mqtt.publish(
                CocoaMQTTMessage(
                    topic: topic,
                    payload: msgAsArray
                )
            )
        }
    }
    
    func subscribeAndPublishMyTopics(pubkey:String,idx:Int){
        do{
            let ret = try setNetwork(network: network)
            handleRunReturn(rr: ret)
            let ret2 = try setBlockheight(blockheight: 0)
            handleRunReturn(rr: ret2)
            
            guard let seed = getAccountSeed() else{
                return
            }
            
            let subtopic = try! sphinx.getSubscriptionTopic(seed: seed, uniqueTime: getEntropyString(), state: loadOnionStateAsData())
            
            mqtt.didReceiveMessage = { mqtt, receivedMessage, id in
                self.processMqttMessages(message: receivedMessage)
            }
            
            self.mqtt.subscribe([
                (subtopic, CocoaMQTTQoS.qos1)
            ])
            
            let ret3 = try initialSetup(seed: seed, uniqueTime: getEntropyString(), state: loadOnionStateAsData())
            handleRunReturn(rr: ret3)
            
        }
        catch{
            
        }
        
        
        
//        subscribeToMyTopics(pubkey: pubkey, idx: idx)
//        publishMyTopics(pubkey: pubkey, idx: idx)
    }
    
    
    func createMyAccount(mnemonic:String)->Bool{
        do{
            //1. Generate Seed -> Display to screen the mnemonic for backup???
            guard let seed = getAccountSeed(mnemonic: mnemonic) else{
                //possibly send error message?
                return false
            }
            //2. Create the 0th pubkey
            guard let pubkey = getAccountOnlyKeysendPubkey(seed: seed),
                  let my_xpub = getAccountXpub(seed: seed) else{
                  return false
            }
            //3. Connect to server/broker
            let success = connectToBroker(seed:seed,xpub: my_xpub)
            
            //4. Subscribe to relevant topics based on OK key
            let idx = 0
            if success{
                mqtt.didReceiveMessage = { mqtt, receivedMessage, id in
                    self.processMqttMessages(message: receivedMessage)
                }
                
                //subscribe to relevant topics
                mqtt.didConnectAck = { _, _ in
                    //self.showSuccessWithMessage("MQTT connected")
                    print("SphinxOnionManager: MQTT Connected")
                    print("mqtt.didConnectAck")
                    self.subscribeAndPublishMyTopics(pubkey: pubkey, idx: idx)
                }
            }
            return success
        }
        catch{
            print("error connecting to mqtt broker")
            return false
        }
       
    }
    
    
    func processRegisterTopicResponse(message:CocoaMQTTMessage){
        let payloadData = Data(message.payload)
        if let payloadString = String(data: payloadData, encoding: .utf8) {
            print("MQTT Topic:\(message.topic) with Payload as String: \(payloadString)")
            if let retrievedCredentials = Mapper<SphinxOnionBrokerResponse>().map(JSONString: payloadString){
                print("Onion Credentials register over MQTT:\(retrievedCredentials)")
                //5. Store my credentials (SCID, serverPubkey, myPubkey)
                if let _ = retrievedCredentials.scid{
                    processContact(from: message.topic,retrievedCredentials: retrievedCredentials)
                }
            }
        } else {
            print("MQTT Unable to convert payload to a string")
        }
    }
    
    func processBalanceTopicMessage(message:CocoaMQTTMessage){
        let payloadData = Data(message.payload)
        if let payloadString = String(data: payloadData, encoding: .utf8) {
            print("MQTT Topic:\(message.topic) with Payload as String: \(payloadString)")
            (shouldPostUpdates) ?  NotificationCenter.default.post(Notification(name: .onBalanceDidChange, object: nil, userInfo: ["balance" : payloadString])) : ()
        }
    }
    
    func processSendTopicMessage(message:CocoaMQTTMessage){
        let payloadData = Data(message.payload)
        if let payloadString = String(data: payloadData, encoding: .utf8) {
            print("MQTT Topic:\(message.topic) with Payload as String: \(payloadString)")
        }
    }
    
    func processStreamTopicMessage(message:CocoaMQTTMessage){
//        let tops = message.topic.split(separator: "/").map({String($0)})
//        guard let mnemonic = UserData.sharedInstance.getMnemonic(),
//              let seed = getAccountSeed(mnemonic: mnemonic),
//        tops.count > 1,
//        let index = UInt32(tops[1]) else{
//            return
//        }
//        
//        print("MQTT Stream Topic:\(message.topic)")
//        let payloadData = Data(message.payload)
//        do{
//            let peeledOnion = try peelOnionMsg(seed: seed, idx: index, time: getEntropyString(), network: network, payload: payloadData)
//            if let dataFromString = peeledOnion.data(using: .utf8, allowLossyConversion: false) {
//                let json = try JSON(data: dataFromString)
//                if json["type"] == 11 || json["type"] == 10 || json["type"] == 0{
//                    //process contact confirmation
//                    if json["type"] == 11,
//                       let senderInfo = json["sender"].dictionaryObject as? [String: String],
//                       let pubkey = senderInfo["pubkey"],
//                       let contact = UserContact.getContactWithDisregardStatus(pubkey: pubkey,managedContext: managedContext)
//                    {
//                        //TODO: fix this. I can't get this information to save to the db record!!
//                        contact.contactKey = senderInfo["contactPubkey"]
//                        contact.routeHint = senderInfo["routeHint"]
//                        contact.contactRouteHint = senderInfo["contactRouteHint"]
//                        contact.nickname = senderInfo["alias"]
//                        contact.publicKey = pubkey
//                        contact.status = UserContact.Status.Confirmed.rawValue
//                        contact.createdAt = Date()
//                        createChat(for: contact)
//                        managedContext.saveContext()
//                        
//                        
//                        NotificationCenter.default.post(Notification(name: .newContactKeyExchangeResponseWasReceived, object: nil, userInfo: nil))
//                    }
//                    else if json["type"] == 10,//do key exchange confirmation
//                       let mnemonic = UserData.sharedInstance.getMnemonic(),
//                       let seed = getAccountSeed(mnemonic: mnemonic),
//                       let xpub = getAccountXpub(seed: seed),
//                        let senderInfo = json["sender"].dictionaryObject as? [String: String],
//                       let nextIndex = UserContact.getNextAvailableContactIndex(){//reply with contact info if it's not initiated by me
//                        do{
//                            guard let validPubkey = senderInfo["pubkey"],
//                                  let validRouteHint = senderInfo["routeHint"],
//                                  let validCRH = senderInfo["contactRouteHint"],
//                                  let validNickname = senderInfo["alias"],
//                                  let validContactKey = senderInfo["contactPubkey"] else{
//                                return
//                            }
//                            
//                            
//                            let childPubKey = try pubkeyFromSeed(seed: seed, idx: UInt32(nextIndex), time: getEntropyString(), network: network)
//                            let contact = createNewContact(pubkey: validPubkey, childPubkey: childPubKey, routeHint: validRouteHint, idx: nextIndex,nickname: validNickname,contactRouteHint: validCRH,contactKey: validContactKey)
//                            
//                            guard let contact = contact else{
//                                //AlertHelper.showAlert(title: "Key Exchange Error", message: "Already have a contact for:\(validNickname)")
//                                return
//                            }
//                            contact.status = UserContact.Status.Confirmed.rawValue
//                            createChat(for: contact)
//                            
//                                //self.showSuccessWithMessage("MQTT connected")
//                                print("SphinxOnionManager: MQTT Connected")
//                                print("mqtt.didConnectAck")
//                                self.mqtt.subscribe([
//                                    ("\(childPubKey)/\(nextIndex)/res/#", CocoaMQTTQoS.qos1)
//                                ])
//                                self.mqtt.publish(
//                                    CocoaMQTTMessage(
//                                        topic: "\(childPubKey)/\(nextIndex)/req/register",
//                                        payload: []
//                                    )
//                                )
//                            
//                            
//                            sendKeyExchangeMsg(isInitiatorMe: false, to: contact)
//                            
//                            managedContext.saveContext()
//                            
//                            NotificationCenter.default.post(Notification(name: .newContactKeyExchangeResponseWasReceived, object: nil, userInfo: nil))
//                        }
//                        catch{
//                            print("error generating childPubkey")
//                        }
//                    }
//                    else if json["type"] == 0{
//                        var index: Int?
//                        if tops.contains("stream"){
//                            index = Int(tops[4])
//                        }
//                        processPlaintextMessage(messageJSON: json,index:index)
//                    }
//                }
//            }
//        }
//        catch{
//            print("error")
//        }
    }
    
    
    func processMqttMessages(message:CocoaMQTTMessage){
        guard let seed = getAccountSeed() else{
            return
        }
        do{
            let ret4 = try handle(topic: message.topic, payload: Data(message.payload), seed: seed, uniqueTime: getEntropyString(), state: self.loadOnionStateAsData(), myAlias: "", myImg: "")
            handleRunReturn(rr: ret4)
        }
        catch{
            
        }
        
    }
    
    func showSuccessWithMessage(_ message: String) {
        self.newMessageBubbleHelper.showGenericMessageView(
            text: message,
            delay: 6,
            textColor: UIColor.white,
            backColor: UIColor.Sphinx.PrimaryGreen,
            backAlpha: 1.0
        )
    }
}

extension SphinxOnionManager{//Sign Up UI Related:
    func chooseImportOrGenerateSeed(){
        let requestEnteredMneumonicCallback: (() -> ()) = {
            self.importSeedPhrase()
        }
        
        let generateSeedCallback: (() -> ()) = {
            guard let mneomnic = self.generateMnemonic(),
                  let vc = self.vc as? NewUserSignupFormViewController else{
                return
            }
            self.showMnemonicToUser(mnemonic: mneomnic, callback: {
                self.createMyAccount(mnemonic: mneomnic)
                vc.signup_v2_with_test_server()
            })
        }
        
        AlertHelper.showTwoOptionsAlert(
            title: "profile.mnemonic-generate-or-import-title".localized,
            message: "profile.mnemonic-generate-or-import-prompt".localized,
            confirmButtonTitle: "profile.mnemonic-generate-prompt".localized,
            cancelButtonTitle: "profile.mnemonic-import-prompt".localized,
            confirm: generateSeedCallback,
            cancel: requestEnteredMneumonicCallback
        )
    }
    
    func importSeedPhrase(){
        if let vc = self.vc as? ImportSeedViewDelegate {
            vc.showImportSeedView()
        }
    }
    
    func showMnemonicToUser(mnemonic: String, callback: @escaping () -> ()) {
        guard let vc = vc else {
            callback()
            return
        }
        
        let copyAction = UIAlertAction(
            title: "Copy",
            style: .default,
            handler: { _ in
                ClipboardHelper.copyToClipboard(text: mnemonic, message: "profile.mnemonic-copied".localized)
                callback()
            }
        )
        
        AlertHelper.showAlert(
            title: "profile.store-mnemonic".localized,
            message: mnemonic,
            on: vc,
            additionAlertAction: copyAction,
            completion: {
                callback()
            }
        )
    }
    
}

