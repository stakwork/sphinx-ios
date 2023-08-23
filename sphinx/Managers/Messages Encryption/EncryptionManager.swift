//
//  EncryptionManager.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/12/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation
import SwiftyRSA

class EncryptionManager {
    
    let KEY_SIZE = 2048
    let SMALL_KEY_SIZE = 256
    let PUBLIC_KEY = "public.com.gl.sphinx"
    let PRIVATE_KEY = "private.com.gl.sphinx"
    
    class var sharedInstance : EncryptionManager {
        struct Static {
            static let instance = EncryptionManager()
        }
        return Static.instance
    }
    
    let userData = UserData.sharedInstance
    
    var myPrivateKey : PrivateKey?
    
    var ownPrivateKey: SecKey? {
        get {
            return retrieveKey(keyClass: kSecAttrKeyClassPrivate, tag: PRIVATE_KEY)
        }
        set {
            saveKey(key: newValue, keyClass: kSecAttrKeyClassPrivate, tag: PRIVATE_KEY)
        }
    }

    var ownPublicKey: SecKey? {
        get {
            return retrieveKey(keyClass: kSecAttrKeyClassPublic, tag: PUBLIC_KEY)
        }
        set {
            saveKey(key: newValue, keyClass: kSecAttrKeyClassPublic, tag: PUBLIC_KEY)
        }
    }
    
    func deleteKey(keyClass: CFString, tag: String) -> Bool {
        let query: [String: Any] = [
            String(kSecClass)              : kSecClassKey,
            String(kSecAttrKeyClass)       : keyClass,
            String(kSecAttrKeyType)        : kSecAttrKeyTypeRSA,
            String(kSecReturnRef)          : true as Any,
            String(kSecAttrApplicationTag) : tag,
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            return false
        }
        return true
   }
    
    func saveKey(key: SecKey?, keyClass: CFString, tag: String) {
        if let key = key {
            let attribute = [
                String(kSecClass)              : kSecClassKey,
                String(kSecAttrKeyClass)       : keyClass,
                String(kSecAttrKeyType)        : kSecAttrKeyTypeRSA,
                String(kSecValueRef)           : key,
                String(kSecReturnPersistentRef): true,
                String(kSecAttrApplicationTag) : tag,
                String(kSecAttrLabel)          : tag,
                ] as [String : Any]

            let status = SecItemAdd(attribute as CFDictionary, nil)

            if status != noErr {
                return
            }
        }
    }

    func retrieveKey(keyClass: CFString, tag: String) -> SecKey? {
        let query: [String: Any] = [
            String(kSecClass)              : kSecClassKey,
            String(kSecAttrKeyClass)       : keyClass,
            String(kSecAttrKeyType)        : kSecAttrKeyTypeRSA,
            String(kSecReturnRef)          : true as Any,
            String(kSecAttrApplicationTag) : tag,
        ]

        var result : AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            return result as! SecKey?
        }
        return nil
    }
    
    func deleteOldKeys() {
        let _ = deleteKey(keyClass: kSecAttrKeyClassPublic, tag: PUBLIC_KEY)
        let _ = deleteKey(keyClass: kSecAttrKeyClassPrivate, tag: PRIVATE_KEY)
    }
    
    func getOrCreateKeys(completion: (() -> ())? = nil) -> (PrivateKey?, PublicKey?) {
        let (privateKey, publicKey) = getKeysFromReferences()

        if let privateKey = privateKey, let publicKey = publicKey {
            saveKeysOnKeychain()
            sendPublicKeyToServer(completion: completion)
            return (privateKey, publicKey)
        }
        
        if let owner = UserContact.getOwner(), let contactKey = owner.contactKey, !contactKey.isEmpty {
            let keychainRestoredKeys = restoreFromKeychain()
            
            if let privateKey = keychainRestoredKeys.0, let publicKey = keychainRestoredKeys.1 {
                
                ownPublicKey = publicKey.reference
                ownPrivateKey = privateKey.reference
                
                completion?()
                
                return (privateKey, publicKey)
            }
        }
        
        var keyPair : (privateKey: PrivateKey, publicKey: PublicKey)?
        
        do {
            keyPair = try SwiftyRSA.generateRSAKeyPair(sizeInBits: KEY_SIZE)
            
            ownPublicKey = keyPair?.publicKey.reference
            ownPrivateKey = keyPair?.privateKey.reference
        } catch {
            return (nil, nil)
        }
        
        saveKeysOnKeychain()
        sendPublicKeyToServer(completion: completion)
        
        return (keyPair?.privateKey, keyPair?.publicKey)
    }
    
    func restoreFromKeychain() -> (PrivateKey?, PublicKey?) {
        let (privKeyString, pubKeyString) = userData.getEncryptionKeys()
        if let privKeyString = privKeyString, let pubKeyString = pubKeyString, !privKeyString.isEmpty && !pubKeyString.isEmpty {
            if let privateKey = getPrivateKeyFromBase64String(base64String: privKeyString), let publicKey = getPublicKeyFromBase64String(base64String: pubKeyString) {
                return (privateKey, publicKey)
            }
        }
        return (nil, nil)
    }
    
    func saveKeysOnKeychain() {
        if let publicKey = getOwnPublicKey(), let base64PublicKey = getBase64String(key: publicKey),
            let privateKey = getOwnPrivateKey(), let base64PrivateKey = getBase64String(key: privateKey) {
            let _  = userData.save(privateKey: base64PrivateKey, andPublicKey: base64PublicKey)
        }
    }
    
    func sendPublicKeyToServer(completion: (() -> ())? = nil) {
        if let publicKey = getOwnPublicKey(),
            let base64PublicKey = getBase64String(key: publicKey),
            let owner = UserContact.getOwner() {
            if let _ = owner.contactKey {
                return
            }
            
            UserContactsHelper.updateContact(contact: owner, contactKey: base64PublicKey, callback: { _ in
                completion?()
            })
        }
    }
    
    func getPublicKeyFromBase64String(base64String: String) -> PublicKey? {
        do {
            let userKey = try PublicKey(base64Encoded: base64String)
            return userKey
        } catch {
            return nil
        }
    }
    
    func getPrivateKeyFromBase64String(base64String: String) -> PrivateKey? {
        do {
            let userKey = try PrivateKey(base64Encoded: base64String)
            return userKey
        } catch {
            return nil
        }
    }
    
    func getKeysFromReferences() -> (PrivateKey?, PublicKey?) {
        if let privateKey = getOwnPrivateKey(), let publicKey = getOwnPublicKey() {
            return (privateKey, publicKey)
        }
        return (nil, nil)
    }
    
    func getOwnPrivateKey() -> PrivateKey? {
        if let myPrivateKey = myPrivateKey {
            return myPrivateKey
        }
        
        guard let privateKeyReference = ownPrivateKey else {
            return getOwnPrivateKeyFromKeychain()
        }

        var privateKey : PrivateKey?
        
        do {
            privateKey = try PrivateKey(reference: privateKeyReference)
        } catch let error {
            print(error)
        }

        myPrivateKey = privateKey
        
        if let privateKey = privateKey {
            return privateKey
        }

        return nil
    }
    
    func getOwnPrivateKeyFromKeychain() -> PrivateKey? {
        guard let privateKeyString = userData.getEncryptionKeys().0, !privateKeyString.isEmpty else {
            return nil
        }
        
        var privateKey : PrivateKey?

        do {
            privateKey = try PrivateKey(base64Encoded: privateKeyString)
        } catch let error {
            print(error)
        }

        if let privateKey = privateKey {
            return privateKey
        }
        
        return nil
    }
    
    func getOwnPublicKey() -> PublicKey? {
        guard let publicKeyReference = self.ownPublicKey else {
            return nil
        }
        
        var publicKey : PublicKey?

        do {
            publicKey = try PublicKey(reference: publicKeyReference)
        } catch let error {
            print(error)
        }

        if let publicKey = publicKey {
            return publicKey
        }
        
        return nil
    }
    
    func getBase64String(key: Key?) -> String? {
        guard let key = key else {
            return nil
        }
        
        do {
            let keyString = try key.base64String()
            return keyString
        } catch {
            return nil
        }
    }
    
    //Export Keys
    func getKeysStringForExport() -> (String?, String?) {
        if let publicKey = getOwnPublicKey(), let base64PublicKey = getBase64String(key: publicKey),
           let privateKey = getOwnPrivateKey(), let base64PrivateKey = getBase64String(key: privateKey) {
            return (base64PrivateKey, base64PublicKey)
        }
        return (nil, nil)
    }
    
    //ImportKeys
    func insertKeys(privateKey: String, publicKey: String) -> Bool {
        if let privatek = getPrivateKeyFromBase64String(base64String: privateKey),
            let publicK = getPublicKeyFromBase64String(base64String: publicKey) {
            
            ownPrivateKey = privatek.reference
            ownPublicKey = publicK.reference
            saveKeysOnKeychain()
            
            return true
        }
        return false
    }
    
    //Encrypting messages
    func encryptMessageForOwner(message: String) -> String {
        if let owner = UserContact.getOwner() {
            return encryptMessage(message: message, for: owner).1
        }
        return message
    }
    
    func encryptMessage(message: String, for contact: UserContact) -> (Bool, String) {
        guard let contactKey = contact.contactKey, let key = getPublicKeyFromBase64String(base64String: contactKey) else {
            return (false, message)
        }
        
        do {
            let clear = try ClearMessage(string: message, using: .utf8)
            let encrypted = try clear.encrypted(with: key, padding: .PKCS1)
            return (true, encrypted.base64String)
        } catch {
            return (false, message)
        }
    }
    
    func decryptMessage(message: String) -> (Bool, String) {
        if message == "" {
            return (true, message)
        }
        
        guard let ownPrivateKey = getOwnPrivateKey() else {
            return (false, message)
        }
        
        return decryptMessage(message: message, key: ownPrivateKey)
    }
    
    func encryptMessage(message: String, groupKey: String) -> (Bool, String) {
        guard let key = getPublicKeyFromBase64String(base64String: groupKey) else {
            return (false, message)
        }
        
        do {
            let clear = try ClearMessage(string: message, using: .utf8)
            let encrypted = try clear.encrypted(with: key, padding: .PKCS1)
            return (true, encrypted.base64String)
        } catch {
            return (false, message)
        }
    }
    
    func encryptMessage(message: String, key: PublicKey) -> String {
        do {
            let clear = try ClearMessage(string: message, using: .utf8)
            let encrypted = try clear.encrypted(with: key, padding: .PKCS1)
            return encrypted.base64String
        } catch {
            return message
        }
    }
    
    func encryptToken(token: String, key: PublicKey) -> String? {
        do {
            let clear = try ClearMessage(string: token, using: .utf8)
            let encrypted = try clear.encrypted(with: key, padding: .PKCS1)
            return encrypted.base64String
        } catch {
            return nil
        }
    }
    
    func decryptMessage(message: String, key: PrivateKey) -> (Bool, String) {
        do {
            let encrypted = try EncryptedMessage(base64Encoded: message)
            let clear = try encrypted.decrypted(with: key, padding: .PKCS1)
            let string = try clear.string(encoding: .utf8)
            return (true, string)
        } catch {
            return (false, message)
        }
    }
    
    public static func randomString(length: Int) -> String {
        let uuidString = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        
        return String(
            Data(uuidString.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .prefix(length)
        )
    }
}
