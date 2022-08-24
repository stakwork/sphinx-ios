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
    
    struct HardwarePostDto {
        var lightningNodePort:String? = nil
        var lightningNodeIP:String? = nil
        var networkName:String? = nil
        var networkPassword:String? = nil
        var publicKey: String? = nil
        var encryptedSeed: String? = nil
    }
    
    var vc: UIViewController! = nil
    var endCallback: () -> Void = {}
    
    var hardwarePostDto = HardwarePostDto()
    let newMessageBubbleHelper = NewMessageBubbleHelper()
    
//    let url = "http://192.168.71.1"
    let url = "http://192.168.0.25:8000"
    
    func setupSigningDevice(
        vc: UIViewController,
        callback: @escaping () -> ()
    ) {
        self.vc = vc
        self.endCallback = callback
        
        self.hardwarePostDto = HardwarePostDto()
        self.setupSigningDevice()
    }
    
    func setupSigningDevice() {
        self.promptForNetworkName() { networkName in
            self.promptForNetworkPassword(networkName) {
                self.promptForHardwareIP() {
                    self.promptForHardwarePort {
                        self.testCrypter()
                    }
                }
            }
        }
    }
    
    func promptForHardwareIP(callback: @escaping () -> ()) {
        promptFor(
            "Lightning node IP",
            message: "Enter the IP of your lightning node",
            errorMessage: "Invalid IP",
            callback: { value in
                self.hardwarePostDto.lightningNodeIP = value
                callback()
            }
        )
    }
    
    func promptForHardwarePort(callback: @escaping () -> ()) {
        promptFor(
            "Lightning node Port",
            message: "Enter the Port number of your lightning node",
            errorMessage: "Invalid IP",
            textFieldText: "1883",
            callback: { value in
                self.hardwarePostDto.lightningNodePort = value
                callback()
            }
        )
    }
    
    func promptForNetworkName(
        callback: @escaping (String) -> ()
    ) {
        promptFor(
            "WiFi network",
            message: "Please specify your WiFi network",
            errorMessage: "Invalid WiFi name",
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
            "WiFi password",
            message: "Enter the WiFi password for \(networkName)",
            errorMessage: "Invalid WiFi password",
            secureEntry: true,
            callback: { value in
                self.hardwarePostDto.networkPassword = value
                callback()
            }
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
        let mnemonic = UserData.sharedInstance.getMnemonic() ?? Mnemonic.create()
        UserData.sharedInstance.save(walletMnemonic: mnemonic)
        
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
        
        guard let _ = hardwarePostDto.lightningNodeIP, let _ = hardwarePostDto.lightningNodePort else {
            self.showSuccessWithMessage("There was an error. Please try again later")
            return
        }
        
        self.newMessageBubbleHelper.showLoadingWheel()
        
        API.sharedInstance.getHardwarePublicKey(url: "\(url)/ecdh", callback: { pubKey in
            
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
                    url: "\(self.url)/config",
                    hardwarePostDto: self.hardwarePostDto,
                    callback: { success in
                        
                    if (success) {
                        UserDefaults.Keys.setupSigningDevice.set(true)
                        
                        self.showSuccessWithMessage("Seed sent to hardware successfully")
                    } else {
                        self.showErrorWithMessage("Error sending seed to hardware")
                    }
                        
                    self.endCallback()
                })
            }
            
        }, errorCallback: {
            self.showErrorWithMessage("Error getting hardware public key")
        })
    }
    
    func showMnemonicToUser(callback: @escaping () -> ()) {
        self.newMessageBubbleHelper.hideLoadingWheel()
        
        if let mnemonic = UserData.sharedInstance.getMnemonic() {
            AlertHelper.showAlert(title: "Store your Mnemonic securely", message: mnemonic, on: vc, completion: {
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
