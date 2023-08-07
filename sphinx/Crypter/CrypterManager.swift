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

class CrypterManager : NSObject {
    
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
    
    var clientID: String = ""
//    var mqtt5: CocoaMQTT5! = nil
    var mqtt: CocoaMQTT! = nil
    var sequence: UInt16! = nil
    var seed: Data! = nil
    var argsDictionary: [String: AnyObject] = [:]
    var keys: [String] = []
    
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
        
        self.setupSigningDevice()
    }
    
    func start() {
        let mnemonic = Mnemonic.create()
        seed = Mnemonic.createSeed(mnemonic: mnemonic)
        let seed32Bytes = seed.bytes[0..<32]
        
        var keys: Keys? = nil
        do {
            keys = try nodeKeys(net: "regtest", seed: seed32Bytes.hexString)
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
        
        connectToMQTTWith(
            keys: keys,
            and: password
        )
    }
    
    func connectToMQTTWith(
        keys: Keys,
        and password: String
    ) {
        clientID = "CocoaMQTT-" + String(ProcessInfo().processIdentifier)
        mqtt = CocoaMQTT(clientID: clientID, host: "localhost", port: 1883)
//        mqtt5 = CocoaMQTT5(clientID: clientID, host: "localhost", port: 1883)

        let connectProperties = MqttConnectProperties()
//        connectProperties.topicAliasMaximum = 0
//        connectProperties.sessionExpiryInterval = 0
//        connectProperties.receiveMaximum = 100
//        connectProperties.maximumPacketSize = 500
        
//        mqtt.connectProperties = connectProperties
        mqtt.username = keys.pubkey
        mqtt.password = password
//        mqtt.willMessage = CocoaMQTTMessage(topic: "/will", string: "dieout")
        mqtt.allowUntrustCACertificate = true
        
        let success = mqtt.connect()
        
        print("MQTT CONNECTION RESULT: \(success)")
        
        if success {
            mqtt.subscribe([
                ("\(clientID)/\(Topics.VLS)", CocoaMQTTQoS.qos1),
                ("\(clientID)/\(Topics.INIT_1_MSG)", CocoaMQTTQoS.qos1),
                ("\(clientID)/\(Topics.INIT_2_MSG)", CocoaMQTTQoS.qos1),
                ("\(clientID)/\(Topics.LSS_MSG)", CocoaMQTTQoS.qos1)
            ])
//            mqtt.subscribe([
//                MqttSubscription(topic: "\(clientID)/\(Topics.VLS)"),
//                MqttSubscription(topic: "\(clientID)/\(Topics.INIT_1_MSG)"),
//                MqttSubscription(topic: "\(clientID)/\(Topics.INIT_2_MSG)"),
//                MqttSubscription(topic: "\(clientID)/\(Topics.LSS_MSG)")
//            ])
            
            mqtt.didReceiveMessage = { mqtt, message, id in
                print("Message received in topic \(message.topic) with payload \(message.string!)")
                
                self.processMessage(
                    topic: message.topic,
                    payload: message.payload
                )
            }
            
            mqtt.didDisconnect =  { cocaMQTT2, error in
                print("MQTT did disconnect")
            }
            
            mqtt.publish(
                CocoaMQTTMessage(
                    topic: "\(clientID)/\(Topics.HELLO)",
                    payload: []
                )
            )
        }
    }
    
    func processMessage(
        topic: String,
        payload: [UInt8]
    ) {
        let a = argsAndState()
        
        var ret: VlsResponse? = nil
        do {
            ret = try run(
                topic: topic,
                args: a.0,
                state: Data(a.1),
                msg1: Data(payload),
                expectedSequence: sequence
            )
        } catch {
            print(error.localizedDescription)
        }
        
        guard let ret = ret else {
            return
        }
        
        processVlsResult(ret: ret)
        
        if topic.hasSuffix(Topics.VLS.rawValue) {
//            if let cmd = ret.cmd {
//                cmds.update((cs) => [...cs, ret.cmd]);
//            }
            // update expected sequence
            sequence = ret.sequence + 1
        }
    }
    
    func processVlsResult(ret: VlsResponse) {
        let _ = storeMutations(inc: ret.state.bytes)
        publish(topic: ret.topic, payload: ret.bytes.bytes)
    }
    
    func argsAndState() -> (String, [UInt8]) {
        let args = asString(jsonDictionary: makeArgs())
        let sta: [String: [UInt8]] = load_muts()
        
        let state = pack(
            MessagePackValue(asString(jsonDictionary: sta))
        )
        
        return (args, state.bytes)
    }
    
    func makeArgs() -> [String: AnyObject] {
        let seedHexString = seed.bytes[0..<32].hexString
        
        guard let seedBytes = stringToBytes(seedHexString) else {
            return [:]
        }
        
        let defaultPolicy: [String: AnyObject] = [
          "msat_per_interval": 21000000000 as AnyObject,
          "interval": "daily" as AnyObject,
          "htlc_limit_msat": 1000000000 as AnyObject,
        ]
        
        let lssNonce = randomBytes(32).hexString
        
        let args: [String: AnyObject] = [
            "seed": seedBytes as AnyObject,
            "network": "regtest" as AnyObject,
            "policy": defaultPolicy as AnyObject,
            "allowlist": [] as AnyObject,
            "timestamp": UInt32(Date().timeIntervalSince1970) as AnyObject,
            "lss_nonce": lssNonce as AnyObject,
        ]
        
        return args
    }
    
    func load_muts() -> [String: [UInt8]] {
        var state:[String: [UInt8]] = [:]
        
        for key in keys {
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
      for  mut in muts {
          if let key = mut.key.stringValue, let value = mut.value.dataValue?.bytes {
              UserDefaults.standard.set(value, forKey: key)
              UserDefaults.standard.synchronize()
          }
      }
    }
    
    func asString(jsonDictionary: JSONDictionary) -> String {
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted)
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
                payload: []
            )
//            ,
//            properties: MqttPublishProperties()
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
        callback: @escaping ((String, String)) -> ()
    ) {
        let generateMnemonicCallbak: (() -> ()) = {
            self.newMessageBubbleHelper.showLoadingWheel()
            let (mnemonic, seed) = self.generateAndPersistWalletMnemonic()
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
                    
                    let (mnemonic, seed) = self.generateAndPersistWalletMnemonic(
                        mnemonic: fixedWords
                    )
                    callback((mnemonic, seed))
                } else {
                    self.showErrorWithMessage("profile.mnemonic-enter-error".localized)
                }
            }
        )
    }
    
    public func generateAndPersistWalletMnemonic(
        mnemonic: String? = nil
    ) -> (String, String) {
        let mnemonic = mnemonic ?? Mnemonic.create()
        let seed = Mnemonic.createSeed(mnemonic: mnemonic)
        let seed32Bytes = seed.bytes[0..<32]
        
        return (mnemonic, seed32Bytes.hexString)
    }
    
    func testCrypter() {
        let sk1 = Nonce(length: 32).description.hexEncoded

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

//extension CrypterManager : CocoaMQTT5Delegate {
//    func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveMessage message: CocoaMQTT5Message, id: UInt16, publishData: MqttDecodePublish?) {
//        print("DID RECEIVE MESSAGE")
//    }
//}
