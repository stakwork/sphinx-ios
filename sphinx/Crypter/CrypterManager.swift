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
    var mqtt5: CocoaMQTT5! = nil
    var sequence: Int! = nil
    var argsDictionary: [String: AnyObject] = [:]
    
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
        let seed = Mnemonic.createSeed(mnemonic: mnemonic)
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
        mqtt5 = CocoaMQTT5(clientID: clientID, host: "localhost", port: 1883)

        let connectProperties = MqttConnectProperties()
        connectProperties.topicAliasMaximum = 0
        connectProperties.sessionExpiryInterval = 0
        connectProperties.receiveMaximum = 100
        connectProperties.maximumPacketSize = 500
        
        mqtt5.connectProperties = connectProperties
        mqtt5.username = keys.pubkey
        mqtt5.password = password
        mqtt5.willMessage = CocoaMQTT5Message(topic: "/will", string: "dieout")
        
        let success = mqtt5.connect()
        
        print("MQTT CONNECTION RESULT: \(success)")
        
        if success {
            mqtt5.subscribe([
                MqttSubscription(topic: "\(clientID)/\(Topics.VLS)"),
                MqttSubscription(topic: "\(clientID)/\(Topics.INIT_1_MSG)"),
                MqttSubscription(topic: "\(clientID)/\(Topics.INIT_2_MSG)"),
                MqttSubscription(topic: "\(clientID)/\(Topics.LSS_MSG)")
            ])
            
            mqtt5.didReceiveMessage = { mqtt, message, id, _ in
                print("Message received in topic \(message.topic) with payload \(message.string!)")
                
                self.processMessage(
                    topic: message.topic,
                    payload: message.payload
                )
            }
            
            mqtt5.didDisconnect =  { cocaMQTT2, error in
                
            }
            
            mqtt5.publish(
                CocoaMQTT5Message(
                    topic: "\(clientID)/\(Topics.HELLO)",
                    payload: []
                ),
                properties: MqttPublishProperties()
            )
        }
    }
    
    func processMessage(topic: String, payload: [UInt8]) {
//        var a = argsAndState()
    }
    
//    func argsAndState() -> [String: [Byte]] {
//      const args = stringifyArgs(makeArgs());
//      const sta: State = await load_muts();
//      const state = msgpack.encode(sta);
//      return { args, state };
//    }
    
    func setupSigningDevice() {
        let packed = Data([147, 146, 164, 97, 97, 97, 97, 146, 15, 196, 3, 255, 255, 255, 146, 164, 98, 98, 98, 98, 146, 15, 196, 3, 255, 255, 255, 146, 164, 99, 99, 99, 99, 146, 15, 196, 3, 255, 255, 255])
        
        let unpacked = try? unpack(packed)
        let unpackedValue = (unpacked?.value as? MessagePackValue)?.arrayValue![0].arrayValue![1].arrayValue![0]
        
        print(unpacked?.value)
        
//        array(
//            [
//                array(
//                    [string(aaaa), array([uint(15), array([uint(255), uint(255), uint(255)])])]
//                ),
//                array(
//                    [string(bbbb), array([uint(15), array([uint(255), uint(255), uint(255)])])]
//                ),
//                array(
//                    [string(cccc), array([uint(15), array([uint(255), uint(255), uint(255)])])]
//                )
//            ]
//        )
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
