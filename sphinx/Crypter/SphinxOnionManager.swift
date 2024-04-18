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
import CoreData


class SphinxOnionManager : NSObject {
    class var sharedInstance : SphinxOnionManager {
        struct Static {
            static let instance = SphinxOnionManager()
        }
        return Static.instance
    }
    
    var pendingContact : UserContact? = nil
    var currentServer : Server? = nil
    var pendingInviteLookupByTag : [String:String] = [String:String]()
    var stashedContactInfo:String?=nil
    var stashedInitialTribe:String?=nil
    var stashedInviteCode:String?=nil
    var stashedInviterAlias:String?=nil
    var watchdogTimer:Timer?=nil
    var nextMessageBlockWasReceived = false
    
    var messageFetchParams : MessageFetchParams? = nil
    var newMessageSyncedListener: NSFetchedResultsController<TransactionMessage>?
    var isV2InitialSetup:Bool=false
    let newMessageBubbleHelper = NewMessageBubbleHelper()
    var shouldPostUpdates : Bool = false
    let tribeMinEscrowSats = 3
    
    var vc: UIViewController! = nil{
        didSet{
            print("vc set:\(vc)")
        }
    }
    var mqtt: CocoaMQTT! = nil
    let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
    
    var stashedCallback : (([String:AnyObject]) ->())? = nil
    var isConnected : Bool = false{
        didSet{
            NotificationCenter.default.post(name: .onConnectionStatusChanged, object: nil)
        }
    }
    var msgTotalCounts : MsgTotalCounts? = nil
    typealias RestoreProgressCallback = (Int) -> Void
    var messageRestoreCallback : RestoreProgressCallback? = nil
    var contactRestoreCallback : RestoreProgressCallback? = nil
    var hideRestoreCallback: (() -> ())? = nil
    public static let kMessageBatchSize = 50

    
    //MARK: Hardcoded Values!
    var server_IP = "34.229.52.200"
    let server_PORT = 1883
    let defaultTribePubkey = "032dbf9a31140897e52b66743f2c78e93cff2d5ecf6fe4814327d8912243106ff6"
    let network = "regtest"
    
    
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
            let xpub = try xpubFromSeed(seed: seed, time: getTimeWithEntropy(), network: network)
            return xpub
        }
        catch{
            return nil
        }
    }
    
    func getAccountOnlyKeysendPubkey(seed:String)->String?{
        do{
            let pubkey = try pubkeyFromSeed(seed: seed, idx: 0, time: getTimeWithEntropy(), network: network)
            return pubkey
        }
        catch{
            return nil
        }
    }
    
    func getTimeWithEntropy()->String{
        let currentTimeMilliseconds = Int(Date().timeIntervalSince1970 * 1000)
        let upperBound = 1_000
        let randomInt = CrypterManager().generateCryptographicallySecureRandomInt(upperBound: upperBound)
        let timePlusRandom = currentTimeMilliseconds + randomInt!
        let randomString = String(describing: timePlusRandom)
        return randomString
    }
    
    func connectToBroker(seed:String,xpub:String)->Bool{
        do{
            let now = getTimeWithEntropy()
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

    func connectToV2Server(contactRestoreCallback: @escaping RestoreProgressCallback, messageRestoreCallback: @escaping RestoreProgressCallback,hideRestoreViewCallback: @escaping ()->()){
        let som = self
        guard let seed = som.getAccountSeed(),
              let myPubkey = som.getAccountOnlyKeysendPubkey(seed: seed),
              let my_xpub = som.getAccountXpub(seed: seed)
        else{
            //possibly send error message?
            AlertHelper.showAlert(title: "Error", message: "Could not connect to server")
            return
        }
        som.disconnectMqtt()
        DelayPerformedHelper.performAfterDelay(seconds: 2.0, completion: {
            let success = som.connectToBroker(seed:seed,xpub: my_xpub)
            if(success == false) {
                AlertHelper.showAlert(title: "Error", message: "Could not connect to MQTT Broker.")
                return
              }
            som.mqtt.didConnectAck = {_, _ in
                som.subscribeAndPublishMyTopics(pubkey: myPubkey, idx: 0)
                if(som.isV2InitialSetup){
                    //self.contactRestoreCallback(percentage: 0)
                    som.isV2InitialSetup = false
                    som.doInitialInviteSetup()
                    som.performAccountRestore(
                        contactRestoreCallback: contactRestoreCallback,
                        messageRestoreCallback: messageRestoreCallback,
                        hideRestoreViewCallback: hideRestoreViewCallback
                    )
                }
                else{
                    if let hideRestoreCallback = self.hideRestoreCallback{
                        hideRestoreCallback()
                    }
                    som.syncMessagesSinceLastKnownIndexHeight()
                }
            }
        })
    }

    func listContacts()->String{
        let contacts = try! sphinx.listContacts(state: self.loadOnionStateAsData())
        return contacts
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
            
            let subtopic = try! sphinx.getSubscriptionTopic(seed: seed, uniqueTime: getTimeWithEntropy(), state: loadOnionStateAsData())
            
            mqtt.didReceiveMessage = { mqtt, receivedMessage, id in
                self.isConnected = true
                self.processMqttMessages(message: receivedMessage)
            }
            
            self.mqtt.subscribe([
                (subtopic, CocoaMQTTQoS.qos1)
            ])
            
            let ret3 = try initialSetup(seed: seed, uniqueTime: getTimeWithEntropy(), state: loadOnionStateAsData())
            handleRunReturn(rr: ret3)
            
            let tribeMgmtTopic = try getTribeManagementTopic(seed: seed, uniqueTime: getTimeWithEntropy(), state: loadOnionStateAsData())
            
            
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
            let myPubkey = try pubkeyFromSeed(seed: seed, idx: 0, time: getTimeWithEntropy(), network: network)
            let myFullAccount = try sphinx.listContacts(state: loadOnionStateAsData())
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
                    self.isConnected = true
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
            let ret4 = try handle(topic: message.topic, payload: Data(message.payload), seed: seed, uniqueTime: getTimeWithEntropy(), state: self.loadOnionStateAsData(), myAlias: alias, myImg: pic)
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
    func chooseImportOrGenerateSeed(completion:@escaping (Bool)->()){
        let requestEnteredMneumonicCallback: (() -> ()) = {
            self.importSeedPhrase()
        }
        
        let generateSeedCallback: (() -> ()) = {
            guard let mneomnic = self.generateMnemonic(),
                  let _ = self.vc as? NewUserSignupFormViewController else{
                completion(false)
                return
            }
            self.showMnemonicToUser(mnemonic: mneomnic, callback: {
                completion(true)
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

