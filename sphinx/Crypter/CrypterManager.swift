//
//  CrypterManager.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/07/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import UIKit
import NetworkExtension
import CoreLocation
import CocoaMQTT
import MessagePack

var wordsListPossibilities : [WordList] = [
    .english,
    .japanese,
    .korean,
    .spanish,
    .simplifiedChinese,
    .traditionalChinese,
    .french,
    .italian
]

func localizedString(_ key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

struct Hop: Codable {
    let pubkey: String
}

enum SeedValidationError: Error {
    case incorrectWordNumber
    case invalidWord
    
    var localizedDescription: String {
        switch self {
        case .incorrectWordNumber:
            return localizedString("profile.mnemonic-incorrect-length")
        case .invalidWord:
            return localizedString("profile.mnemonic-invalid-word")
        }
    }
}

class CrypterManager : NSObject {
    
    class var sharedInstance : CrypterManager {
        struct Static {
            static let instance = CrypterManager()
        }
        return Static.instance
    }
    
    enum Topics: String {
        case VLS = "vls"
        case VLS_RES = "vls-res"
        case CONTROL = "control"
        case CONTROL_RES = "control-res"
        case PROXY = "proxy"
        case PROXY_RES = "proxy-res"
        case ERROR = "error"
        case INIT_1_MSG = "init-1-msg"
        case INIT_1_RES = "init-1-res"
        case INIT_2_MSG = "init-2-msg"
        case INIT_2_RES = "init-2-res"
        case LSS_MSG = "lss-msg"
        case LSS_RES = "lss-res"
        case HELLO = "hello"
        case BYE = "bye"
    }
    
    struct HardwareLink {
        var mqtt: String? = nil
        var network: String? = nil
        var relay: String? = nil
        
        init(
            mqtt: String,
            network: String,
            relay:String
        ) {
            self.mqtt = mqtt
            self.network = network
            self.relay = relay
        }
        
        static func getHardwareLinkFrom(query: String) -> HardwareLink? {
            guard let mqtt = query.getLinkComponentWith(key: "mqtt"), mqtt.isNotEmpty else {
                return nil
            }
            
            guard let network = query.getLinkComponentWith(key: "network"), network.isNotEmpty else {
                return nil
            }
            
            guard let relay = query.getLinkComponentWith(key: "relay"), network.isNotEmpty else {
                return nil
            }
            
            return HardwareLink(
                mqtt: mqtt,
                network: network,
                relay: relay
            )
        }
    }
    
    struct HardwarePostDto {
        var lightningNodeUrl:String? = nil
        var networkName:String? = nil
        var networkPassword:String? = nil
        var publicKey: String? = nil
        var bitcoinNetwork: String? = nil
        var encryptedSeed: String? = nil
        var relay:String? = nil
    }
    
    struct OnionData{
        var serverPubkey:String? = nil
        var destinationPubkey:String? = nil
    }
    
    var vc: UIViewController! = nil
    var endCallback: ((String?) -> ()) = {_ in }
    
    var onionConfig = OnionData()
    var hardwarePostDto = HardwarePostDto()
    let newMessageBubbleHelper = NewMessageBubbleHelper()
    var didDisconnect = false
    var scannerVC : NewQRScannerViewController? = nil
    let test_mnemonic1 = "grape memory stadium already soap vintage lend gospel actual also major goat"
    
    var clientID: String {
        get {
            if let clientId: String = UserDefaults.Keys.clientID.get() {
                return clientId
            }
            self.clientID = "CocoaMQTT-" + EncryptionManager.randomString(length: 20)
            return self.clientID
        }
        set {
            UserDefaults.Keys.clientID.set(newValue)
        }
    }
    
    var lssNonce: String {
        get {
            if let lssNonce: String = UserDefaults.Keys.lssNonce.get() {
                return lssNonce
            }
            let lssNonce = Nonce(length: 32).hexString
            UserDefaults.Keys.lssNonce.set(lssNonce)
            return lssNonce
        }
        set {
            UserDefaults.Keys.lssNonce.set(newValue)
        }
    }
    
    var signerIdNonce: String {
        get {
            if let signerIdNonce: String = UserDefaults.Keys.signerIdNonce.get() {
                return signerIdNonce
            }
            let signerIdNonce = Nonce(length: 16).hexString
            UserDefaults.Keys.lssNonce.set(signerIdNonce)
            return signerIdNonce
        }
        set {
            UserDefaults.Keys.signerIdNonce.set(newValue)
        }
    }
    
    var mutationKeys: [String] {
        get {
            if let signerKeys: String = UserDefaults.Keys.signerKeys.get() {
                return signerKeys.components(separatedBy: ",")
            }
            return []
        }
        set {
            UserDefaults.Keys.signerKeys.set(
                newValue.joined(separator: ",")
            )
        }
    }
    
    var sequence: UInt16! {
        get {
            if let sequence: UInt16 = UserDefaults.Keys.sequence.get() {
                return sequence
            }
            return nil
        }
        set {
            UserDefaults.Keys.sequence.set(newValue)
        }
    }
    
    var mqtt: CocoaMQTT! = nil{
        didSet{
            API.sharedInstance.postMQTTStatusChange()
        }
    }
    
    override init() {
        super.init()
        
        clear()
    }
    
    func setupSigningDevice(
        vc: UIViewController,
        overrideMessages: Bool = false,
        hardwareLink: HardwareLink? = nil,
        callback: @escaping ((String?) -> ())
    ) {
        self.vc = vc
        self.endCallback = callback
        self.hardwarePostDto = HardwarePostDto()
        
        if let hardwareLink = hardwareLink {
            hardwarePostDto.lightningNodeUrl = hardwareLink.mqtt
            hardwarePostDto.bitcoinNetwork = hardwareLink.network
            hardwarePostDto.relay = hardwareLink.relay
        }
        
        chooseConnectionType(overrideMessages: overrideMessages)
    }
    
    func chooseConnectionType(
        overrideMessages: Bool = false
    ) {
        overrideMessages ? (self.resetMQTTConnection(overrideMessages: overrideMessages)) : ()//disconnect MQTT if it is connected
        
        let setupHardwareCallback: (() -> ()) = {
            self.startSigningDeviceSetup()
        }
        
        let setupPhoneDeviceCallback: (() -> ()) = {
            self.startMQTTSetup()
        }
        
        AlertHelper.showOptionsPopup(
            title: "profile.signer-setup-title".localized,
            message: "profile.signer-setup-message".localized,
            options: [
                "profile.harware-option".localized,
                "profile.phone-signer-option".localized
            ],
            callbacks: [
                setupHardwareCallback,
                setupPhoneDeviceCallback
            ],
            sourceView: self.vc.view,
            vc: self.vc
        )
    }
    
    func showQRScanner(presentingVC:UIViewController?=nil) {
        if(presentingVC != nil){
            self.vc = presentingVC
        }
        guard let vc = self.vc else {
            return
        }
        
        scannerVC = NewQRScannerViewController.instantiate(
            currentMode: NewQRScannerViewController.Mode.ScanAndDismiss
        )
        if let scannerVC = scannerVC{
            scannerVC.delegate = self
            vc.present(scannerVC, animated: true)
        }
    }
    
    func resetMQTTConnection(overrideMessages:Bool=false) {
        if mqtt?.connState != .connected && mqtt?.connState != .connecting && overrideMessages == false {
            showErrorWithMessage("MQTT not connected yet")
            return
        }
        
        didDisconnect = true
        
        UserDefaults.Keys.phoneSignerHost.removeValue()
        UserDefaults.Keys.phoneSignerNetwork.removeValue()
        UserDefaults.Keys.setupPhoneSigner.removeValue()
        UserDefaults.Keys.signerKeys.removeValue()
        UserDefaults.Keys.sequence.removeValue()
        
        mqtt?.disconnect()
        mqtt = nil
        
        if(overrideMessages == false){
            showSuccessWithMessage("MQTT disconnected")
        }
        
        DelayPerformedHelper.performAfterDelay(seconds: 2, completion: {
            self.didDisconnect = false
        })
        
        API.sharedInstance.postMQTTStatusChange()
    }
    
    func startMQTTSetup() {
        if mqtt?.connState == .connected || mqtt?.connState == .connecting {
            showSuccessWithMessage("MQTT already connected or connecting")
            return
        }
        
        let host = hardwarePostDto.lightningNodeUrl ?? UserDefaults.Keys.phoneSignerHost.get()
        let network = hardwarePostDto.bitcoinNetwork ?? UserDefaults.Keys.phoneSignerNetwork.get()
        let relay = hardwarePostDto.relay ?? UserDefaults.Keys.phoneSignerRelay.get()
        
        guard let host = host, let network = network , let relay = relay else {
            showQRScanner()
            return
        }
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.05, completion: {
            self.chooseImportOrGenerateSeed(network: network, host: host,relay: relay)
        })
        
        API.sharedInstance.postMQTTStatusChange()
    }
    
    func chooseImportOrGenerateSeed(network:String,host:String,relay:String){
        let requestEnteredMneumonicCallback: (() -> ()) = {
            self.importSeedPhrase(network: network, host: host, relay: relay)
        }
        
        let generateSeedCallback: (() -> ()) = {
            let _ = self.performWalletFinalization(network: network, host: host, relay: relay)
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
    
    func importSeedPhrase(
        network: String,
        host: String,
        relay: String
    ){
        if let vc = self.vc as? ImportSeedViewDelegate {
            vc.showImportSeedView(
                network: network,
                host: host,
                relay: relay
            )
        }
    }
    
    func validateSeed(
        words: [String]
    ) -> (SeedValidationError?, String?) {
        if (words.count != 12 && words.count != 24) {
            return (SeedValidationError.incorrectWordNumber,nil)
        }
        if let languageList = findListForWord(words[0]){
            for i in 1..<words.count{
                if languageList.words.contains(words[i]) == false {
                    return (SeedValidationError.invalidWord, "\(i + 1) - \(words[i])")
                }
            }
        }
        else {
            return (SeedValidationError.invalidWord, "1 -\(words[0])")
        }
        
        return (nil, nil)
    }
    
    func findListForWord(_ word: String) -> WordList? {
        for language in wordsListPossibilities {
            if language.words.contains(word) {
                return language
            }
        }
        return nil
    }
    
    func performWalletFinalization(
        network: String,
        host: String,
        relay: String,
        enteredMnemonic: String? = nil
    ) -> Bool {
        let (mnemonic, _) = getOrCreateWalletMnemonic(enteredMnemonic: enteredMnemonic?.lowercased())
        
        if mnemonic.isEmpty {
            showErrorWithMessage("Entered mnemonic is not valid")
            return false
        }
        
        self.showMnemonicToUser(mnemonic: mnemonic) {
            var keys: Keys? = nil
            do {
                keys = try nodeKeys(net: network, seed: mnemonicToSeed(mnemonic: mnemonic))
            } catch {
                print(error.localizedDescription)
            }
            guard let keys = keys else {
                return
            }
            
            var password: String? = nil
            do {
                password = try makeAuthToken(ts: UInt32(Date().timeIntervalSince1970), secret: keys.secret)
            } catch {
                print(error.localizedDescription)
            }
            
            guard let password = password else {
                return
            }
            
            self.connectToMQTTWith(
                host: host,
                network: network,
                relay:relay,
                keys: keys,
                and: password
            )
            
            self.endCallback(relay)
        }
        
        return true
    }
    
    
    
    func connectToMQTTWith(
        host: String,
        network: String,
        relay:String,
        keys: Keys,
        and password: String
    ) {
        if didDisconnect {
            didDisconnect = false
            return
        }
        
        let (actualHost, actualPort, ssl) = host.getHostAndPort(defaultPort: 1883)
        
        mqtt = CocoaMQTT(
            clientID: clientID,
            host: actualHost,
            port: actualPort
        )
        
        mqtt.username = keys.pubkey
        mqtt.password = password
        mqtt.enableSSL = ssl
        mqtt.allowUntrustCACertificate = true
        showSuccessWithMessage("Connecting to MQTT")

        let success = mqtt.connect()

        if success {
            UserDefaults.Keys.phoneSignerHost.set(host)
            UserDefaults.Keys.phoneSignerNetwork.set(network)
            UserDefaults.Keys.phoneSignerRelay.set(relay)
            
            mqtt.didReceiveMessage = { mqtt, message, id in
                
                self.processMessage(
                    topic: message.topic.replacingOccurrences(of: "\(self.clientID)/", with: ""),
                    payload: message.payload,
                    network:network
                )
            }
            mqtt.didDisconnect =  { cocaMQTT2, error in
                self.showErrorWithMessage("MQTT disconnected. Trying to reconnect...")
                API.sharedInstance.postMQTTStatusChange()
                
                self.mqtt.didDisconnect = { _, _ in }
                self.sequence = nil
                
                DelayPerformedHelper.performAfterDelay(seconds: 2, completion: {
                    guard let _ = self.mqtt else {
                        return
                    }
                    
                    self.connectToMQTTWith(
                        host: host,
                        network: network,
                        relay: relay,
                        keys: keys,
                        and: password
                    )
                })
            }
            
            mqtt.didConnectAck = { _, _ in
                self.showSuccessWithMessage("MQTT connected")
                API.sharedInstance.postMQTTStatusChange()
                
                self.mqtt.subscribe([
                    ("\(self.clientID)/\(Topics.VLS.rawValue)", CocoaMQTTQoS.qos1),
                    ("\(self.clientID)/\(Topics.INIT_1_MSG.rawValue)", CocoaMQTTQoS.qos1),
                    ("\(self.clientID)/\(Topics.INIT_2_MSG.rawValue)", CocoaMQTTQoS.qos1),
                    ("\(self.clientID)/\(Topics.LSS_MSG.rawValue)", CocoaMQTTQoS.qos1)
                ])

                self.mqtt.publish(
                    CocoaMQTTMessage(
                        topic: "\(self.clientID)/\(Topics.HELLO.rawValue)",
                        payload: []
                    )
                )
            }
        }
    }
    
    func connectToMQTTWith(
        clientId: String,
        username:String,
        password:String
    ){
        
    }
    
    func clear() {
        mutationKeys = []
        sequence = nil
    }
    
    func restart() {
        clear()
        
        mqtt.publish(
            CocoaMQTTMessage(
                topic: "\(clientID)/\(Topics.HELLO.rawValue)",
                payload: []
            )
        )
    }
    
    func processMessage(
        topic: String,
        payload: [UInt8],
        network: String
    ) {
        let a = argsAndState(network: network)
        
        var ret: VlsResponse? = nil
        do {
            ret = try run(
                topic: topic,
                args: a.0,
                state: Data(bytes: a.1),
                msg1: Data(payload),
                expectedSequence: sequence
            )
        } catch {
            if (error.localizedDescription.contains("Error: VLS Failed: invalid sequence")) {
                restart()
                return
            }
        }
        
        guard let ret = ret else {
            print("guard let ret = ret else statement")
            return
        }
        
        processVlsResult(ret: ret)
        
        if topic.hasSuffix(Topics.VLS.rawValue) {
//            if let cmd = ret.cmd {
//                cmds.update((cs) => [...cs, ret.cmd]);
//            }
            // update expected sequence
            print("topic in topic.hasSuffix \(topic)")
            sequence = ret.sequence + 1
        }
    }
    
    func processVlsResult(ret: VlsResponse) {
        let _ =  storeMutations(inc: ret.state.bytes)
        publish(topic: ret.topic, payload: ret.bytes.bytes)
        print("processVlsResult publishing topic:\(ret.topic), bytes:\(ret.bytes.bytes)")
    }
    
    func argsAndState(network:String) -> (String, [UInt8]) {
        let args = makeArgs(network: network)
        let stringArgs = asString(jsonDictionary: args)
        
        let sta: [String: [UInt8]] = load_muts()

        var mpDic = [MessagePackValue:MessagePackValue]()

        for (key, value) in sta {
            mpDic[MessagePackValue(key)] = MessagePackValue(Data(value))
        }
        
        let state = pack(
            MessagePackValue(mpDic)
        ).bytes
        
        return (stringArgs, state)
    }
    
    func apply<T>(_ f:(T ...) -> T, with elements:[T]) -> T {
       var elements = elements

       if elements.count == 0 {
           return f()
       }

       if elements.count == 1 {
           return f(elements[0])
       }

       var result:T = f(elements.removeFirst(), elements.removeFirst())

       result = elements.reduce(result, {f($0, $1)} )

       return result
    }
    
    func makeArgs(network:String) -> [String: AnyObject] {
        print("makeArgs network:\(network)")
        var seed : String?
        do {
            guard let mnemonic = UserData.sharedInstance.getMnemonic() else{
                return [:]
            }
            seed = try mnemonicToSeed(mnemonic: mnemonic)
        } catch {
            return [:]
        }
        guard let hexString = seed, let seedBytes = stringToBytes(hexString) else {
            return [:]
        }
        
        guard let lssN = stringToBytes(lssNonce) else {
            return [:]
        }
        
        guard let signerIdNonce = stringToBytes(signerIdNonce) else{
            return [:]
        }
        
        let defaultPolicy: [String: AnyObject] = [
          "msat_per_interval": 21000000000 as NSNumber,
          "interval": "daily" as NSString,
          "htlc_limit_msat": 1000000000 as NSNumber,
        ]
        
        let args: [String: AnyObject] = [
            "seed": seedBytes as NSArray,
            "network": network as NSString,
            "policy": defaultPolicy as NSDictionary,
            "allowlist": [] as NSArray,
            "timestamp": UInt32(Date().timeIntervalSince1970) as NSNumber,
            "lss_nonce": lssN as NSArray,
            "signer_id": signerIdNonce as NSArray
        ]
        
        return args
    }
    
    ///MARK: Onion Related///
    
    func getTimestampInMilliseconds()->String{
        let nowSeconds = Date().timeIntervalSince1970
        let nowMilliseconds = Int64(nowSeconds * 1000)
        let nowMsString = String(nowMilliseconds)
        return nowMsString
    }
    
    func sendOnionMessage(message:String){//Sending onion messages
        let network = "regtest"
        guard let serverPubkey = onionConfig.serverPubkey?.replacingOccurrences(of: "\"pubkey\":\"", with: ""),
              let alicePubkey = onionConfig.destinationPubkey else{
            return
        }
        do{
            let time = self.getTimestampInMilliseconds()
            //let alicePubkey = "02058e8b6c2ad363ec59aa136429256d745164c2bdc87f98f0a68690ec2c5c9b0b"//example destination pubkey
            
            let hops: [String] = [
                serverPubkey, // Replace serverPubkey with the actual server pubkey
                alicePubkey   // Replace alicePubkey with the actual alice pubkey
            ]
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .withoutEscapingSlashes
            let contentString = message//"The Times 03/Jan/2009 Chancellor on brink of second bailout for banks"
            if let hopsJSON = try? encoder.encode(hops),
               let contentData = contentString.data(using: .utf8){
                if let hopsJSONString = String(data: hopsJSON, encoding: .utf8) {
                    print("Hops JSON String: \(hopsJSONString)")
                    //Setting up like this for demo purposes bc hopsJSONString doesn't work
                    //TODO: fix the fact that parsing isn't workingn of extracting pubkey value from key value pair. This is the hack for now
                    let hopsJSONString2 = """
                    [
                        {"pubkey": "\(serverPubkey)"},
                        {"pubkey": "\(alicePubkey)"}
                    ]
                    """
                    let hopsJSONString3 = """
                    [
                        {"pubkey": "0343f9e2945b232c5c0e7833acef052d10acf80d1e8a168d86ccb588e63cd962cd"},
                        {"pubkey": "02058e8b6c2ad363ec59aa136429256d745164c2bdc87f98f0a68690ec2c5c9b0b"}
                    ]
                    """
                    let seed = try mnemonicToSeed(mnemonic: test_mnemonic1)
                    let pubkey = try pubkeyFromSeed(seed: seed, time: time, network: network)
                    let onion = try! createOnion(seed: seed, time: time, network: hopsJSONString3, hops: network, payload: contentData)
                    var onionAsArray = [UInt8](repeating: 0, count: onion.count)

                    // Use withUnsafeBytes to copy the Data into the UInt8 array
                    onion.withUnsafeBytes { bufferPointer in
                        guard let baseAddress = bufferPointer.baseAddress else {//
                            fatalError("Failed to get base address")
                        }
                        memcpy(&onionAsArray, baseAddress, onion.count)
                        self.mqtt.publish(
                            CocoaMQTTMessage(
                                topic: "\(pubkey)/req/send",
                                payload: onionAsArray
                            )
                        )
                    }
                    
                }
            }
            
        }
        catch{
            print("mqtt error:\(error)")
        }
    }
    
    func processReceivedOnionMessage(message: CocoaMQTTMessage) {//Receiving onion messages
        let network = "regtest"
        do {
            let seed = try mnemonicToSeed(mnemonic: test_mnemonic1)
            let data = Data(message.payload)
            let decrypted_json = try peelOnion(seed: seed, time: getTimestampInMilliseconds(), network: network, payload: data)
            if let decrypted_string = String(data: decrypted_json, encoding: .utf8) {
                print("MQTT message received & decrypted: \(decrypted_string)")

                // Parse the decrypted_string as JSON
                if let jsonData = decrypted_string.data(using: .utf8),
                   let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                    // Access the "content" key in the JSON dictionary
                    if let contentArray = jsonObject["content"] as? [Int]
                        {
                        let contentString = contentArray.compactMap { UnicodeScalar($0) }.map { String($0) }.joined()
                        print("MQTT Content as UTF-8 string: \(contentString)")
                        let provisionalMessage = TransactionMessage.createProvisionalMessage(messageContent: contentString, type: TransactionMessage.TransactionMessageType.message.rawValue, date: Date(), chat: nil)
                        let notification = Notification(name: .onOnionMessageReceived,object: provisionalMessage)
                        NotificationCenter.default.post(notification)
                    }
                }
            }
        } catch {
            print("error decrypting mqtt message")
        }
    }


    
    func setupOnionMessengerMqtt(seed:String){//Setting up & handshaking with server
        print("setupOnionMessengerMqtt")
        do{
            let nowMsString = getTimestampInMilliseconds()
            let network = "regtest"
            let pubkey = try pubkeyFromSeed(seed: seed, time: nowMsString,network: network)
            let sig = try signMs(seed: seed, time: nowMsString, network: network)
            
            print(sig)
            mqtt = CocoaMQTT(clientID: pubkey,host: "54.164.163.153",port: 1883)
            mqtt.username = nowMsString
            mqtt.password = sig
            let success = mqtt.connect()
            if success {
                mqtt.didReceiveMessage = { mqtt, receivedMessage, id in
                    print("MQTT message received with id:\(id) message:\(receivedMessage)")
                    print("MQTT Topic:\(receivedMessage.topic) Payload:\(receivedMessage.payload)")
                    if receivedMessage.topic.contains("pubkey") {
                        let payloadData = Data(receivedMessage.payload)
                        if let serverPubkey = String(data: payloadData, encoding: .utf8) {
                            print("MQTT Payload as String: \(serverPubkey)")
                            self.onionConfig.serverPubkey = serverPubkey
                            self.onionConfig.destinationPubkey = "02058e8b6c2ad363ec59aa136429256d745164c2bdc87f98f0a68690ec2c5c9b0b"
                        } else {
                            print("MQTT Unable to convert payload to a string")
                        }
                    }
                    else{
                        self.processReceivedOnionMessage(message: receivedMessage)
                    }
                }
                
                mqtt.didConnectAck = { _, _ in
                    self.showSuccessWithMessage("MQTT connected")
                    API.sharedInstance.postMQTTStatusChange()
                    print("mqtt.didConnectAck")
                    
                    self.mqtt.subscribe([
                        ("\(pubkey)/res/#", CocoaMQTTQoS.qos1)
                    ])
                    
                    self.mqtt.publish(
                        CocoaMQTTMessage(
                            topic: "\(pubkey)/req/register",
                            payload: []
                        )
                    )
                    self.mqtt.publish(
                        CocoaMQTTMessage(
                            topic: "\(pubkey)/req/pubkey",
                            payload: []
                        )
                    )
                    self.mqtt.publish(
                        CocoaMQTTMessage(
                            topic: "\(pubkey)/req/balance",
                            payload: []
                        )
                    )
                    
                }
//                mqtt.didDisconnect =  { cocaMQTT2, error in
//                    //self.showErrorWithMessage("MQTT disconnected. Trying to reconnect...")
//                    API.sharedInstance.postMQTTStatusChange()
//                    
//                    self.mqtt.didDisconnect = { _, _ in }
//                    self.sequence = nil
//                    
//                    DelayPerformedHelper.performAfterDelay(seconds: 2, completion: {
//                        guard let _ = self.mqtt else {
//                            return
//                        }
//                        
//                    })
//                }
            }
            else{
                print("error connecting to mqtt")
            }
        }
        catch{
            print("pubkey generation error")
        }
        
    }
    ///MARK: END Onion Related///
    
    func load_muts() -> [String: [UInt8]] {
        var state:[String: [UInt8]] = [:]
        
        for key in mutationKeys {
            if let value = UserDefaults.standard.object(forKey: key) as? [UInt8] {
                state[key] = value
            }
        }
        return state
    }
    
    func storeMutations(inc: [UInt8]) -> [NSNumber] {
        let muts = try? unpack(Data(inc))
        
        guard let mutsDictionary = (muts?.value as? MessagePackValue)?.dictionaryValue else {
            return []
        }
        
        persist_muts(muts: mutsDictionary)
        
        if let velocity = mutsDictionary[MessagePackValue(stringLiteral: "VELOCITY")]?.arrayValue {
            let parsedVelocity = parseVelocity(veldata: velocity)
            return parsedVelocity
        }

        return []
    }
    
    func parseVelocity(veldata: [MessagePackValue]) -> [NSNumber] {
        return []
//      if (!veldata) return;
//      try {
//        const vel = msgpack.decode(veldata);
//        if (Array.isArray(vel)) {
//          if (vel.length > 1) {
//            const pmts = vel[1];
//            if (Array.isArray(pmts)) {
//              return pmts;
//            }
//          }
//        }
//      } catch (e) {
//        console.error("invalid velocity");
//      }
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
    
    func asString(jsonDictionary: JSONDictionary) -> String {
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonDictionary, options: .withoutEscapingSlashes)
            return String(data: data, encoding: String.Encoding.utf8) ?? ""
        } catch {
            return ""
        }
    }
    
    func randomBytes(_ length: Int) -> Data {
        guard length > 0 else { return Data() }
        return Data(
            (1...length).map { _ in UInt8.random(in: 0...UInt8.max) }
        )
    }
    
    func stringToBytes(_ string: String) -> [UInt8]? {
        let length = string.count
        if length & 1 != 0 {
            return nil
        }
        var bytes = [UInt8]()
        bytes.reserveCapacity(length/2)
        var index = string.startIndex
        for _ in 0..<length/2 {
            let nextIndex = string.index(index, offsetBy: 2)
            if let b = UInt8(string[index..<nextIndex], radix: 16) {
                bytes.append(b)
            } else {
                return nil
            }
            index = nextIndex
        }
        return bytes
    }
    
    func publish(topic: String, payload: [UInt8]) {
        guard let mqtt = mqtt else  {
            print("NO MQTT CLIENT")
            return
        }

        mqtt.publish(
            CocoaMQTTMessage(
                topic: "\(clientID)/\(topic)",
                payload: payload
            )
        )
    }
    
    ///Signer setup
    func startSigningDeviceSetup() {
        API.sharedInstance.getHardwarePublicKey(callback: {_ in}, errorCallback: {})//force request for LAN access
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
            self.checkNetwork {
                self.promptForNetworkName() { networkName in
                    self.promptForNetworkPassword(networkName) {
                        self.promptForHardwareUrl() {
                            self.promptForBitcoinNetwork {
                                self.setupSigningDevice()
                            }
                        }
                    }
                }
            }
        })
    }
    
    func checkNetwork(callback: @escaping () -> ()) {
        AlertHelper.showTwoOptionsAlert(
            title: "profile.network-check-title".localized,
            message: "profile.network-check-message".localized,
            on: vc,
            confirmButtonTitle: "yes".localized,
            cancelButtonTitle: "no".localized,
            confirm: { 
                callback()
            },
            cancel: {}
        )
    }
    
    func promptForNetworkName(
        callback: @escaping (String) -> ()
    ) {
        promptFor(
            "profile.wifi-network-title".localized,
            message: "profile.wifi-network-message".localized,
            errorMessage: "profile.wifi-network-error".localized,
            callback: { value in
                self.hardwarePostDto.networkName = value
                callback(value)
            }
        )
    }
    
    func promptForNetworkPassword(
        _ networkName: String,
        callback: @escaping () -> ()
    ) {
        promptFor(
            "profile.wifi-password-title".localized,
            message: String(format: "profile.wifi-password-message".localized, networkName),
            errorMessage: "profile.wifi-password-error".localized,
            secureEntry: true,
            callback: { value in
                self.hardwarePostDto.networkPassword = value
                callback()
            }
        )
    }
    
    func promptForHardwareUrl(callback: @escaping () -> ()) {
        if let url = self.hardwarePostDto.lightningNodeUrl, url.isNotEmpty {
            callback()
            return
        }
        
        promptFor(
            "profile.lightning-url-title".localized,
            message: "profile.lightning-url-message".localized,
            errorMessage: "profile.lightning-url-error".localized,
            callback: { value in
                self.hardwarePostDto.lightningNodeUrl = value
                callback()
            }
        )
    }
    
    func promptForBitcoinNetwork(callback: @escaping () -> ()) {
        if let net = self.hardwarePostDto.bitcoinNetwork, net.isNotEmpty {
            callback()
            return
        }
        
        let regtestCallbak: (() -> ()) = {
            self.hardwarePostDto.bitcoinNetwork = "regtest"
            callback()
        }
        
        let mainnetCallback: (() -> ()) = {
            self.hardwarePostDto.bitcoinNetwork = "bitcoin"
            callback()
        }
        
        AlertHelper.showOptionsPopup(
            title: "profile.bitcoin-network".localized,
            message: "profile.select-bitcoin-network".localized,
            options: ["Regtest", "Mainnet"],
            callbacks: [regtestCallbak, mainnetCallback],
            sourceView: self.vc.view,
            vc: self.vc
        )
    }
    
    func promptFor(
        _ title: String,
        message: String,
        errorMessage: String,
        textFieldText: String? = nil,
        secureEntry: Bool = false,
        callback: @escaping (String) -> ()) {
            
        AlertHelper.showPromptAlert(
            title: title,
            message: message,
            textFieldText: textFieldText,
            secureEntry: secureEntry,
            on: vc,
            confirm: { value in
                if let value = value, !value.isEmpty {
                    callback(value)
                } else {
                    self.showErrorWithMessage(errorMessage)
                }
            },
            cancel: {}
        )
    }
    
    func promptForSeedGeneration(
        callback: @escaping ((String, String)) -> ()
    ) {
        if let (mnemonic, seed) = getStoredMnemonicAndSeed() {
            callback((mnemonic, seed))
            return
        }
        
        let generateMnemonicCallbak: (() -> ()) = {
            self.newMessageBubbleHelper.showLoadingWheel()
            let (mnemonic, seed) = self.getOrCreateWalletMnemonic()
            callback((mnemonic, seed))
        }
        
        let enterMnemonicCallback: (() -> ()) = {
            self.promptForSeedEnter(callback: callback)
        }
        
        AlertHelper.showOptionsPopup(
            title: "profile.mnemonic-generation-title".localized,
            message: "profile.mnemonic-generation-description".localized,
            options: [
                "profile.mnemonic-generate".localized,
                "profile.mnemonic-enter".localized
            ],
            callbacks: [generateMnemonicCallbak, enterMnemonicCallback],
            sourceView: self.vc.view,
            vc: self.vc
        )
    }
    
    func promptForSeedEnter(
        callback: @escaping ((String, String)) -> ()
    ) {
        promptFor(
            "profile.mnemonic-enter-title".localized,
            message: "profile.mnemonic-enter-description".localized,
            errorMessage: "profile.mnemonic-enter-error".localized,
            callback: { value in
                let wordsCount = value.split(separator: " ").count
                
                if wordsCount == 12 || wordsCount == 24 {
                    self.newMessageBubbleHelper.showLoadingWheel()
                    
                    let words = value.split(separator: " ").map { String($0).trim() }
                    let fixedWords = words.joined(separator: " ")
                    
                    let (mnemonic, seed) = self.getOrCreateWalletMnemonic(
                        enteredMnemonic: fixedWords
                    )
                    callback((mnemonic, seed))
                } else {
                    self.showErrorWithMessage("profile.mnemonic-enter-error".localized)
                }
            }
        )
    }
    
    func generateMnemonic()->String?{
        var result : String? = nil
        do {
            result = try mnemonicFromEntropy(entropy: Data.randomBytes(length: 16).hexString)
        }
        catch let error{
            print("error getting seed\(error)")
        }
        return result
    }
    
    public func getOrCreateWalletMnemonic(
        enteredMnemonic: String? = nil
    ) -> (String, String) {
        guard let mnemonic = enteredMnemonic ?? UserData.sharedInstance.getMnemonic() ?? generateMnemonic() else{
            AlertHelper.showAlert(title: "Error generating seed", message: "Please try again.")
            return ("","")
        }
        do {
            let seed = try mnemonicToSeed(mnemonic: mnemonic)
            UserData.sharedInstance.save(walletMnemonic: mnemonic)
            
            return (mnemonic, seed)
        } catch {
            return("","")
        }
    }
    
    func getStoredMnemonicAndSeed() -> (String, String)? {
        if let mnemonic: String = UserData.sharedInstance.getMnemonic() {
            do{
                let seed = try mnemonicToSeed(mnemonic: mnemonic)
                
                return (mnemonic, seed)
            }
            catch{
                return nil
            }
        }
        
        return nil
    }
    
    func setupSigningDevice() {
        guard let lssNonceBytes = stringToBytes(lssNonce) else {
            return
        }
        
        let sk1 = Nonce(bytes: lssNonceBytes).description.hexEncoded

        var pk1: String? = nil
        do {
            pk1 = try pubkeyFromSecretKey(mySecretKey: sk1)
        } catch {
            print(error.localizedDescription)
        }

        guard let pk1 = pk1 else {
            self.showSuccessWithMessage("There was an error. Please try again later")
            return
        }

        guard let _ = hardwarePostDto.lightningNodeUrl else {
            self.showSuccessWithMessage("There was an error. Please try again later")
            return
        }
        
        self.newMessageBubbleHelper.showLoadingWheel()

        API.sharedInstance.getHardwarePublicKey(callback: { pubKey in

            var sec1: String? = nil
            do {
                sec1 = try deriveSharedSecret(theirPubkey: pubKey, mySecretKey: sk1)
            } catch {
                print(error.localizedDescription)
            }

            self.newMessageBubbleHelper.hideLoadingWheel()

            self.promptForSeedGeneration() { (mnemonic, seed) in
                
                self.newMessageBubbleHelper.hideLoadingWheel()

                self.showMnemonicToUser(mnemonic: mnemonic) {
                    guard let sec1 = sec1 else {
                        self.showSuccessWithMessage("There was an error. Please try again later")
                        return
                    }

                    // encrypt plaintext with sec1
                    let nonce = Nonce(length: 12).description.hexEncoded
                    var cipher: String? = nil

                    do {
                        cipher = try encrypt(plaintext: seed, secret: sec1, nonce: nonce)
                    } catch {
                        print(error.localizedDescription)
                    }

                    guard let cipher = cipher else {
                        self.showSuccessWithMessage("There was an error. Please try again later")
                        return
                    }

                    self.hardwarePostDto.publicKey = pk1
                    self.hardwarePostDto.encryptedSeed = cipher

                    API.sharedInstance.sendSeedToHardware(
                        hardwarePostDto: self.hardwarePostDto,
                        callback: { success in

                        if (success) {
                            UserDefaults.Keys.setupSigningDevice.set(true)

                            self.showSuccessWithMessage("profile.seed-sent-successfully".localized)
                            
                            self.endCallback(self.hardwarePostDto.relay)
                        } else {
                            self.showErrorWithMessage("profile.error-sending-seed".localized)
                        }
                    })
                }
            }
        }, errorCallback: {
            self.showErrorWithMessage("profile.error-getting-hardware-public-key".localized)
        })
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
    
    func getUrl(route: String) -> String {
        if let url = URL(string: route), let _ = url.scheme {
            return url.absoluteString
        }
        return "http://\(route)"
        
    }
    
    func showErrorWithMessage(_ message: String) {
        self.newMessageBubbleHelper.hideLoadingWheel()
        
        self.newMessageBubbleHelper.showGenericMessageView(
            text: message,
            delay: 6,
            textColor: UIColor.white,
            backColor: UIColor.Sphinx.PrimaryRed,
            backAlpha: 1.0
        )
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

extension CrypterManager : QRCodeScannerDelegate {
    func didScanQRCode(string: String) {
        if let hardwareLink = CrypterManager.HardwareLink.getHardwareLinkFrom(
            query: string
        ) {
            hardwarePostDto.lightningNodeUrl = hardwareLink.mqtt
            hardwarePostDto.bitcoinNetwork = hardwareLink.network
            hardwarePostDto.relay = hardwareLink.relay
            
            startMQTTSetup()
            scannerVC?.dismiss(animated: true)
            scannerVC = nil
        } else {
            self.newMessageBubbleHelper.showGenericMessageView(
                text: "code.not.recognized".localized,
                delay: 6,
                textColor: UIColor.white,
                backColor: UIColor.Sphinx.PrimaryRed,
                backAlpha: 1.0
            )
        }
    }
}


extension Data {
    static func randomBytes(length: Int) -> Data {
        var bytes = Data(count: length)
        _ = bytes.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!) }
        return bytes
    }

    public var bytes: Array<UInt8> {
        return Array(self)
    }

}
