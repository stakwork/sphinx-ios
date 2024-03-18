//
//  KeychainManager.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import KeychainAccess

class KeychainManager {
    
    class var sharedInstance : KeychainManager {
        struct Static {
            static let instance = KeychainManager()
        }
        return Static.instance
    }
    
    public static let kKeychainGroup = "8297M44YTW.sphinxV2SharedItems"
    
    enum KeychainKeys : String {
        case pubKeys = "pub_keys"
        case ip = "relay_ip"
        case authToken = "relay_auth_token"
        case transportKey = "relay_transport_key"
        case hmacKey = "hmac_key"
        case pin = "app_pin"
        case privacyPin = "privacy_pin"
        case currentPin = "app_current_pin_ios"
        case privateKey = "encryption_private_key"
        case publicKey = "encryption_public_key"
        case walletMnemonic = "wallet_mnemonic"
        case balance_msats = "balance_msats"
    }
    
    let keychain = Keychain(service: "sphinx-app", accessGroup: KeychainManager.kKeychainGroup).synchronizable(true)
    
    func getComposedKey(for key: String) -> String? {
        if let pubKey = UserData.sharedInstance.getUserPubKey() {
            return getComposedKey(for: key, with: pubKey)
        }
        return nil
    }
    
    func getComposedKey(for key: String, with pubKey: String) -> String {
        return "\(pubKey)-\(key)"
    }
    
    func getValueFor(key: String) -> String? {
        if let key = getComposedKey(for: key) {
            return getValueFor(composedKey: key)
        }
        return nil
    }
    
    func getValueFor(composedKey: String) -> String? {
        do {
            let value = try keychain.get(composedKey)
            return value
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func getPublicKey() -> String? {
        return getValueFor(key: KeychainKeys.publicKey.rawValue)
    }
    
    func getPrivateKey() -> String? {
        return getValueFor(key: KeychainKeys.privateKey.rawValue)
    }
    
    func getPubKeys() -> [String] {
        do {
            let keys = try keychain.get(KeychainManager.KeychainKeys.pubKeys.rawValue)
            if let keys = keys, !keys.isEmpty {
                return keys.components(separatedBy: "-")
            }
        } catch let error {
            print(error.localizedDescription)
            return []
        }
        return []
    }
    
    func getAllValuesFor(pubKey: String) -> [String]? {
        let ipComposedKey = getComposedKey(for: KeychainKeys.ip.rawValue, with: pubKey)
        let tokenComposedKey = getComposedKey(for: KeychainKeys.authToken.rawValue, with: pubKey)
        let pinComposedKey = getComposedKey(for: KeychainKeys.pin.rawValue, with: pubKey)
        let privateKeyComposedKey = getComposedKey(for: KeychainKeys.privateKey.rawValue, with: pubKey)
        let publicKeyComposedKey = getComposedKey(for: KeychainKeys.publicKey.rawValue, with: pubKey)
        
        guard let ip = getValueFor(composedKey: ipComposedKey), !ip.isEmpty else {
            return nil
        }
        
        guard let token = getValueFor(composedKey: tokenComposedKey), !token.isEmpty else {
            return nil
        }
        
        guard let pin = getValueFor(composedKey: pinComposedKey), !pin.isEmpty else {
            return nil
        }
        
        guard let privateKey = getValueFor(composedKey: privateKeyComposedKey), !privateKey.isEmpty else {
            return nil
        }
        
        guard let publicKey = getValueFor(composedKey: publicKeyComposedKey), !publicKey.isEmpty else {
            return nil
        }
        
        return [ip, token, pin, privateKey, publicKey]
    }
    
    func save(value: String, forKey key: String) -> Bool {
        if let key = getComposedKey(for: key) {
            return save(value: value, forComposedKey: key)
        }
        return false
    }
    
    func save(value: String, forComposedKey key: String) -> Bool {
        do {
            try keychain.set(value, key: key)
            return true
        } catch let error {
            print(error.localizedDescription)
            return false
        }
    }
    
    func save(privateKey: String) -> Bool {
        return save(value: privateKey, forKey: KeychainKeys.privateKey.rawValue)
    }
    
    func save(publicKey: String) -> Bool {
        return save(value: publicKey, forKey: KeychainKeys.publicKey.rawValue)
    }
    
    func savePubKeys(value: String) -> Bool {
        do {
            try keychain.set(value, key: KeychainManager.KeychainKeys.pubKeys.rawValue)
            return true
        } catch let error {
            print(error.localizedDescription)
            return false
        }
    }
    
    func saveNewNodeFor(pubKey: String) {
        var pubKeys = getPubKeys()
        if pubKeys.count == 0 {
            let _ = savePubKeys(value: pubKey)
        } else {
            if !pubKeys.contains(pubKey) {
                pubKeys.append(pubKey)
            }
            let _ = savePubKeys(value: pubKeys.joined(separator: "-"))
        }
    }
    
    func deleteValueFor(key: String) -> Bool {
        if let key = getComposedKey(for: key) {
            return deleteValueFor(composedKey: key)
        }
        return false
    }
    
    func deleteValueFor(composedKey: String) -> Bool {
        do {
            try keychain.remove(composedKey)
            return true
        } catch let error {
            print(error.localizedDescription)
            return false
        }
    }
    
    func resetKeychainNodeWith(ip: String) {
        for pubKey in getPubKeys() {
            let ipComposedKey = getComposedKey(for: KeychainKeys.ip.rawValue, with: pubKey)
            
            if let storedIP = getValueFor(composedKey: ipComposedKey), !storedIP.isEmpty {
                if storedIP == ip {
                    resetAllFor(pubKey: pubKey)
                }
            }
        }
    }
    
    func resetAllFor(pubKey: String) {
        let ipComposedKey = getComposedKey(for: KeychainKeys.ip.rawValue, with: pubKey)
        let tokenComposedKey = getComposedKey(for: KeychainKeys.authToken.rawValue, with: pubKey)
        let transportKeyComposedKey = getComposedKey(for: KeychainKeys.transportKey.rawValue, with: pubKey)
        let hmacKeyComposedKey = getComposedKey(for: KeychainKeys.hmacKey.rawValue, with: pubKey)
        let pinComposedKey = getComposedKey(for: KeychainKeys.pin.rawValue, with: pubKey)
        let privateKeyComposedKey = getComposedKey(for: KeychainKeys.privateKey.rawValue, with: pubKey)
        let publicKeyComposedKey = getComposedKey(for: KeychainKeys.publicKey.rawValue, with: pubKey)

        let _ = deleteValueFor(composedKey: ipComposedKey)
        let _ = deleteValueFor(composedKey: tokenComposedKey)
        let _ = deleteValueFor(composedKey: transportKeyComposedKey)
        let _ = deleteValueFor(composedKey: hmacKeyComposedKey)
        let _ = deleteValueFor(composedKey: pinComposedKey)
        let _ = deleteValueFor(composedKey: privateKeyComposedKey)
        let _ = deleteValueFor(composedKey: publicKeyComposedKey)
        
        var pubKeys = getPubKeys()
        
        if let indexOf = pubKeys.index(of: pubKey) {
            pubKeys.remove(at: indexOf)
            let _ = savePubKeys(value: pubKeys.joined(separator: "-"))
        }
    }
}
