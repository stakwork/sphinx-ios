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

class CrypterManager : NSObject {
    
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
    
    public func generateAndPersistWalletMnemonic() -> String {
//        let mnemonic = UserData.sharedInstance.getMnemonic() ?? Mnemonic.create()
//        UserData.sharedInstance.save(walletMnemonic: mnemonic)
        
        let mnemonic = Mnemonic.create()
        
        let seed = Mnemonic.createSeed(mnemonic: mnemonic)
        let seed32Bytes = seed.bytes[0..<32]
        
        return seed32Bytes.hexString
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
            
            let seed = self.generateAndPersistWalletMnemonic()
            
            self.showMnemonicToUser() {
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
        }, errorCallback: {
            self.showErrorWithMessage("profile.error-getting-hardware-public-key".localized)
        })
    }
    
    func showMnemonicToUser(callback: @escaping () -> ()) {
        self.newMessageBubbleHelper.hideLoadingWheel()
        
        if let mnemonic = UserData.sharedInstance.getMnemonic() {
            let copyAction = UIAlertAction(title: "Copy", style: .default, handler: { _ in
                ClipboardHelper.copyToClipboard(text: mnemonic, message: "profile.mnemonic-copied".localized)
                callback()
            })
            AlertHelper.showAlert(title: "profile.store-mnemonic".localized, message: mnemonic, on: vc, additionAlertAction: copyAction, completion: {
                callback()
            })
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
