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
    let tribeServerPubkey = "036b441c86acf790ff00694dfbf83e49cc8d537d166ec68b1077a719e61aa9bb42"
    var stashedCallback : (([String:AnyObject]) ->())? = nil
    
    func getAccountSeed(mnemonic:String?=nil)->String?{
        do{
            if let mnemonic = mnemonic{ // if we have a non-default value, use it
                let seed = try mnemonicToSeed(mnemonic: mnemonic)
                return seed
            }
            else if let mnemonic = UserData.sharedInstance.getMnemonic(){ //pull from memory if argument is nil
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
    
    
    
    
    func disconnectMqtt(){
        if let mqtt = self.mqtt{
            mqtt.disconnect()
        }
    }
    func getAllUnreadMessages(sinceIndex:Int?=nil,limit:Int?=nil){
        guard let seed = getAccountSeed() else {
            return //throw error?
        }
        let sinceMsgIndex = UserData.sharedInstance.getLastMessageIndex() != nil ? UserData.sharedInstance.getLastMessageIndex()! + 1 : 0 //TODO: store last read index?
        let msgCountLimit = limit ?? 50
        do{
            let rr = try fetchMsgs(seed: seed, uniqueTime: getEntropyString(), state: loadOnionStateAsData(), lastMsgIdx: UInt64(sinceMsgIndex), limit: UInt32(msgCountLimit))
            handleRunReturn(rr: rr)
        }
        catch{
            
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
            
            let tribeMgmtTopic = try getTribeManagementTopic(seed: seed, uniqueTime: getEntropyString(), state: loadOnionStateAsData())
            
            
            self.mqtt.subscribe([
                (tribeMgmtTopic, CocoaMQTTQoS.qos1)
            ])
        }
        catch{
            
        }
    }
    
    func fetchMyAccountFromState(){
        guard let seed = getAccountSeed() else{
            return
        }
        do{
            let myPubkey = try pubkeyFromSeed(seed: seed, idx: 0, time: getEntropyString(), network: network)
            let myFullAccount = try listContacts(state: loadOnionStateAsData())
            print(myFullAccount)
        }
        catch{
            
        }
        
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
    
    
    func processMqttMessages(message:CocoaMQTTMessage){
        guard let seed = getAccountSeed() else{
            return
        }
        do{
            let owner = UserContact.getOwner()
            let alias = owner?.nickname ?? ""
            let pic = owner?.avatarUrl ?? ""
            let ret4 = try handle(topic: message.topic, payload: Data(message.payload), seed: seed, uniqueTime: getEntropyString(), state: self.loadOnionStateAsData(), myAlias: alias, myImg: pic)
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

