//
//  CrypterManager.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/07/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import UIKit
import HDWalletKit
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
        
        init(
            mqtt: String,
            network: String
        ) {
            self.mqtt = mqtt
            self.network = network
        }
        
        static func getHardwareLinkFrom(query: String) -> HardwareLink? {
            guard let mqtt = query.getLinkComponentWith(key: "mqtt"), mqtt.isNotEmpty else {
                return nil
            }
            
            guard let network = query.getLinkComponentWith(key: "network"), network.isNotEmpty else {
                return nil
            }
            
            return HardwareLink(
                mqtt: mqtt,
                network: network
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
    }
    
    var vc: UIViewController! = nil
    var endCallback: () -> Void = {}
    
    var hardwarePostDto = HardwarePostDto()
    let newMessageBubbleHelper = NewMessageBubbleHelper()
    var didDisconnect = false
    
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
    
    var seed: Data! = nil
    var mqtt: CocoaMQTT! = nil
    
    override init() {
        super.init()
        
        clear()
    }
    
    func setupSigningDevice(
        vc: UIViewController,
        hardwareLink: HardwareLink? = nil,
        callback: @escaping () -> ()
    ) {
        self.vc = vc
        self.endCallback = callback
        self.hardwarePostDto = HardwarePostDto()
        
        if let hardwareLink = hardwareLink {
            hardwarePostDto.lightningNodeUrl = hardwareLink.mqtt
            hardwarePostDto.bitcoinNetwork = hardwareLink.network
        }
        
        chooseConnectionType()
    }
    
    func chooseConnectionType() {
        let setupHardwareCallback: (() -> ()) = {
            self.setupSigningDevice()
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
    
    func showQRScanner() {
        guard let vc = self.vc else {
            return
        }
        
        let viewController = NewQRScannerViewController.instantiate(
            currentMode: NewQRScannerViewController.Mode.ScanAndDismiss
        )
        viewController.delegate = self
        vc.present(viewController, animated: true)
    }
    
    func resetMQTTConnection() {
        if mqtt?.connState != .connected && mqtt?.connState != .connecting {
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
        
        showSuccessWithMessage("MQTT disconnected")
        
        DelayPerformedHelper.performAfterDelay(seconds: 2, completion: {
            self.didDisconnect = false
        })
    }
    
    func startMQTTSetup() {
        if mqtt?.connState == .connected || mqtt?.connState == .connecting {
            showSuccessWithMessage("MQTT already connected or connecting")
            return
        }
        
        let host = hardwarePostDto.lightningNodeUrl ?? UserDefaults.Keys.phoneSignerHost.get()
        let network = hardwarePostDto.bitcoinNetwork ?? UserDefaults.Keys.phoneSignerNetwork.get()
        
        guard let host = host, let network = network else {
            showQRScanner()
            return
        }
        
        chooseImportOrGenerateSeed(network: network, host: host)
    }
    
    func chooseImportOrGenerateSeed(network:String,host:String){
        let requestEnteredMneumonicCallback: (() -> ()) = {
            self.importSeedPhrase(network: network, host: host)
        }
        
        let generateSeedCallback: (() -> ()) = {
            self.performWalletFinalization(network: network, host: host)
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
    
    func importSeedPhrase(network:String,host:String){
        print("importing seed phrase")
        if let vc = self.vc as? ProfileViewController{
            print("ProfileViewController")
            vc.showImportSeedView(network:network,host:host)
        }
    }
    
    func validateSeed(words:[String])->(SeedValidationError?,String?){
        if(words.count != 12 && words.count != 24){
            return (SeedValidationError.incorrectWordNumber,nil)
        }
        if let languageList = findListForWord(words[0]){
            for i in 1..<words.count{
                if languageList.words.contains(words[i]) == false{
                    return (SeedValidationError.invalidWord,"\(i + 1) - \(words[i])")
                }
            }
        }
        else{
            return (SeedValidationError.invalidWord,"1 -\(words[0])")
        }
        
        return (nil,nil)
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
        network:String,
        host:String,
        enteredMnemonic:String?=nil
    ){
        let (mnemonic, seed) = getOrCreateWalletMnemonic(enteredMnemonic: enteredMnemonic)
        
        self.showMnemonicToUser(mnemonic: mnemonic) {
            var keys: Keys? = nil
            do {
                keys = try nodeKeys(net: network, seed: seed.hexString)
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
                keys: keys,
                and: password
            )
        }
    }
    
    
    
    func connectToMQTTWith(
        host: String,
        network: String,
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
        
        showSuccessWithMessage("Connecting to MQTT")

        let success = mqtt.connect()

        if success {
            UserDefaults.Keys.setupPhoneSigner.set(true)
            UserDefaults.Keys.phoneSignerHost.set(host)
            UserDefaults.Keys.phoneSignerNetwork.set(network)
            
            mqtt.didReceiveMessage = { mqtt, message, id in
                print("Message received in topic \(message.topic) with payload \(message.payload)")
                
                self.processMessage(
                    topic: message.topic.replacingOccurrences(of: "\(self.clientID)/", with: ""),
                    payload: message.payload,
                    network:network
                )
            }

            mqtt.didDisconnect =  { cocaMQTT2, error in
                self.showErrorWithMessage("MQTT disconnected. Trying to reconnect...")
                
                self.mqtt.didDisconnect = { _, _ in }
                self.sequence = nil
                
                DelayPerformedHelper.performAfterDelay(seconds: 2, completion: {
                    guard let _ = self.mqtt else {
                        return
                    }
                    
                    self.connectToMQTTWith(
                        host: host,
                        network: network,
                        keys: keys,
                        and: password
                    )
                })
            }
            
            mqtt.didConnectAck = { _, _ in
                self.showSuccessWithMessage("MQTT connected")
                
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
            print("catch statement in processMessage with error: \(error)")
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
        let seedHexString = seed.hexString
        print("makeArgs network:\(network)")
        
        guard let seedBytes = stringToBytes(seedHexString) else {
            return [:]
        }
        
        guard let lssN = stringToBytes(lssNonce) else {
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
            "lss_nonce": lssN as NSArray
        ]
        
        return args
    }
    
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
    func setupSigningDevice() {
        self.checkNetwork {
            self.promptForNetworkName() { networkName in
                self.promptForNetworkPassword(networkName) {
                    self.promptForHardwareUrl() {
                        self.promptForBitcoinNetwork {
                            self.testCrypter()
                        }
                    }
                }
            }
        }
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
        callback: @escaping ((String, Data)) -> ()
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
        callback: @escaping ((String, Data)) -> ()
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
    
    public func getOrCreateWalletMnemonic(
        enteredMnemonic: String? = nil
    ) -> (String, Data) {
        let mnemonic = enteredMnemonic ?? UserDefaults.Keys.mnemonic.get() ?? Mnemonic.create()
        let seed = Mnemonic.createSeed(mnemonic: mnemonic)
        let seed32Bytes = Data(seed.bytes[0..<32])

        self.seed = seed32Bytes
        UserDefaults.Keys.mnemonic.set(mnemonic)
        
        return (mnemonic, seed32Bytes)
    }
    
    func getStoredMnemonicAndSeed() -> (String, Data)? {
        if let mnemonic: String = UserDefaults.Keys.mnemonic.get() {
            let seed = Mnemonic.createSeed(mnemonic: mnemonic)
            let seed32Bytes = Data(seed.bytes[0..<32])
            
            self.seed = seed32Bytes
            
            return (mnemonic, seed32Bytes)
        }
        
        return nil
    }
    
    func testCrypter() {
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
                        cipher = try encrypt(plaintext: seed.hexString, secret: sec1, nonce: nonce)
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
                        } else {
                            self.showErrorWithMessage("profile.error-sending-seed".localized)
                        }

                        self.endCallback()
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
        if let pvc = vc as? ProfileViewController{
            pvc.didTapCancelImportSeed()
        }
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
            
            startMQTTSetup()
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
