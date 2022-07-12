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

class CrypterManager {
    
    struct HardwarePostDto {
        var ip:String? = nil
        var networkName:String? = nil
        var networkPassword:String? = nil
        var publicKey: String? = nil
        var encryptedSeed: String? = nil
    }
    
    var hardwarePostDto = HardwarePostDto()
    let newMessageBubbleHelper = NewMessageBubbleHelper()
    
    func testHardwareLink(vc: UIViewController) {
        hardwarePostDto = HardwarePostDto()
        
        promptForHardwareIP(vc:vc) {
            self.promptForNetworkName(vc: vc) {
                self.promptForNetworkPassword(vc: vc) {
                    self.testCrypter(vc: vc)
                }
            }
        }
        
    }
    
    func promptForHardwareIP(vc: UIViewController, callback: @escaping () -> ()) {
        AlertHelper.showPromptAlert(
            title: "Hardware IP",
            message: "Please enter hardware IP to start process",
            on: vc,
            confirm: { value in
                if let value = value {
                    
                    if !self.getUrl(route: value).isValidURL {
                        self.showErrorWithMessage("Invalid IP")
                        return
                    }
                    
                    self.hardwarePostDto.ip = value
                    
                    callback()
                }
            },
            cancel: {}
        )
    }
    
    func promptForNetworkName(vc: UIViewController, callback: @escaping () -> ()) {
        AlertHelper.showPromptAlert(
            title: "Network",
            message: "Please enter WiFi network name",
            on: vc,
            confirm: { value in
                if let value = value {
                    self.hardwarePostDto.networkName = value
                    
                    callback()
                }
            },
            cancel: {}
        )
    }
    
    func promptForNetworkPassword(vc: UIViewController, callback: @escaping () -> ()) {
        AlertHelper.showPromptAlert(
            title: "WiFi password",
            message: "Please enter WiFi network password",
            on: vc,
            confirm: { value in
                if let value = value {
                    self.hardwarePostDto.networkPassword = value
                    
                    callback()
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
    
    func testCrypter(vc: UIViewController) {
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
        
        guard let ip = hardwarePostDto.ip else {
            self.showSuccessWithMessage("There was an error. Please try again later")
            return
        }
        
        self.newMessageBubbleHelper.showLoadingWheel()
        
        API.sharedInstance.getHardwarePublicKey(url: "\(getUrl(route: ip))/ecdh", callback: { pubKey in
            
            var sec1: String? = nil
            do {
                sec1 = try deriveSharedSecret(theirPubkey: pubKey, mySecretKey: sk1)
            } catch {
                print(error.localizedDescription)
            }
            
            let seed = self.generateAndPersistWalletMnemonic()
            
            self.copyMnemonicToClipboard(vc: vc) {
                guard let sec1 = sec1 else {
                    self.showSuccessWithMessage("There was an error. Please try again later")
                    return
                }
                
                // encrypt plaintext with sec1
                let nonce = Nonce(length: 8).description.hexEncoded
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
                    url: "\(self.getUrl(route: ip))/config",
                    hardwarePostDto: self.hardwarePostDto,
                    callback: { success in
                        
                    if (success) {
                        self.showSuccessWithMessage("Send seed to hardware successfully")
                    } else {
                        self.showErrorWithMessage("Error sending seed to hardware")
                    }
                })
            }
            
        }, errorCallback: {
            self.showErrorWithMessage("Error getting hardware pub key")
        })
    }
    
    func copyMnemonicToClipboard(vc: UIViewController, callback: @escaping () -> ()) {
        self.newMessageBubbleHelper.hideLoadingWheel()
        
        if let mnemonic = UserData.sharedInstance.getMnemonic() {
            AlertHelper.showAlert(title: "Mnemonic", message: "Your mnemonic phrase will be copied to the clipboard. Save these words securely.", on: vc, completion: {
                ClipboardHelper.copyToClipboard(text: mnemonic, message: "Mnemonic copied to clipboard")
                
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
