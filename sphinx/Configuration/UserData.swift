//
//  Library
//
//  Created by Tomas Timinskas on 08/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation

class UserData {
    
    class var sharedInstance : UserData {
        struct Static {
            static let instance = UserData()
        }
        return Static.instance
    }
    
    let keychainManager = KeychainManager.sharedInstance
    let onionConnector = SphinxOnionConnector.sharedInstance
    
    func isUserLogged() -> Bool {
        return (getAppPin() != "" && getNodeIP() != "" && getAuthToken() != "" && SignupHelper.isLogged())
    }
    
    func getPINHours() -> Int {
        if GroupsPinManager.sharedInstance.isStandardPIN {
            return UserDefaults.Keys.pinHours.get(defaultValue: 12)
        } else {
            return UserDefaults.Keys.privacyPinHours.get(defaultValue: 12)
        }
    }
    
    func setPINHours(hours: Int) {
        if GroupsPinManager.sharedInstance.isStandardPIN {
            UserDefaults.Keys.pinHours.set(hours)
        } else {
            UserDefaults.Keys.privacyPinHours.set(hours)
        }
    }
    
    func getUserId() -> Int {
        if let ownerId = UserDefaults.Keys.ownerId.get(defaultValue: -1), ownerId >= 0 {
            return ownerId
        }
        let ownerId = UserContact.getOwner()?.id ?? -1
        UserDefaults.Keys.ownerId.set(ownerId)
        
        return ownerId
    }
    
    func getUserPubKey() -> String? {
        if let ownerPubKey = UserDefaults.Keys.ownerPubKey.get(defaultValue: ""), !ownerPubKey.isEmpty {
            return ownerPubKey
        }
        let ownerPubKey = UserContact.getOwner()?.publicKey ?? nil
        UserDefaults.Keys.ownerPubKey.set(ownerPubKey)
        
        return ownerPubKey
    }
    
    func save(ip: String, token: String, andPin pin: String) {
        save(ip: ip)
        save(authToken: token)
        save(pin: pin)
        save(currentSessionPin: pin)
    }
    
    func save(pin: String) {
        saveValueFor(value: pin, for: KeychainManager.KeychainKeys.pin, userDefaultKey: UserDefaults.Keys.defaultPIN)
    }
    
    func save(privacyPin: String) {
        saveValueFor(value: privacyPin, for: KeychainManager.KeychainKeys.privacyPin, userDefaultKey: UserDefaults.Keys.privacyPIN)
    }
    
    func save(currentSessionPin: String) {
        saveValueFor(value: currentSessionPin, for: KeychainManager.KeychainKeys.currentPin, userDefaultKey: UserDefaults.Keys.currentSessionPin)
    }
    
    func save(ip: String) {
        let previousIP = getNodeIP()
        if !previousIP.isEmpty {
            UserDefaults.Keys.previousIP.set(previousIP)
        }
        onionConnector.nodeIp = ip
        saveValueFor(value: ip, for: KeychainManager.KeychainKeys.ip, userDefaultKey: UserDefaults.Keys.currentIP)
    }
    
    func revertIP() {
        if let previuosIP: String = UserDefaults.Keys.previousIP.get() {
            onionConnector.nodeIp = previuosIP
            saveValueFor(value: previuosIP, for: KeychainManager.KeychainKeys.ip, userDefaultKey: UserDefaults.Keys.currentIP)
        }
    }
    
    func save(authToken: String) {
        saveValueFor(value: authToken, for: KeychainManager.KeychainKeys.authToken, userDefaultKey: UserDefaults.Keys.authToken)
    }
    
    func save(password: String) {
        UserDefaults.Keys.nodePassword.set(password)
    }
    
    func saveValueFor(value: String, for keychainKey: KeychainManager.KeychainKeys, userDefaultKey: DefaultKey<String>? = nil) {
        if !keychainManager.save(value: value, forKey: keychainKey.rawValue) {
            userDefaultKey?.set(value)
        }
    }
    
    func save(privateKey: String, andPublicKey publicKey: String) -> Bool {
        let privateKeySuccess = keychainManager.save(privateKey: privateKey)
        let publicKeySuccess = keychainManager.save(publicKey: publicKey)
        
        return privateKeySuccess && publicKeySuccess
    }
    
    func getAppPin() -> String? {
        return getValueFor(keychainKey: KeychainManager.KeychainKeys.pin, userDefaultKey: UserDefaults.Keys.defaultPIN)
    }
    
    func getPrivacyPin() -> String? {
        return getValueFor(keychainKey: KeychainManager.KeychainKeys.privacyPin, userDefaultKey: UserDefaults.Keys.privacyPIN)
    }
    
    func getCurrentSessionPin() -> String {
        return getValueFor(keychainKey: KeychainManager.KeychainKeys.currentPin, userDefaultKey: UserDefaults.Keys.currentSessionPin)
    }
    
    func getNodeIP() -> String {
        let nodeIp = getValueFor(keychainKey: KeychainManager.KeychainKeys.ip, userDefaultKey: UserDefaults.Keys.currentIP)
        onionConnector.nodeIp = nodeIp
        return nodeIp
    }
    
    func getAuthToken() -> String {
        return getValueFor(keychainKey: KeychainManager.KeychainKeys.authToken, userDefaultKey: UserDefaults.Keys.authToken)
    }
    
    func getEncryptionKeys() -> (String?, String?) {
        return (keychainManager.getPrivateKey(), keychainManager.getPublicKey())
    }
    
    func getPassword() -> String {
        UserDefaults.Keys.nodePassword.get(defaultValue: "")
    }
    
    func getValueFor(keychainKey: KeychainManager.KeychainKeys, userDefaultKey: DefaultKey<String>? = nil) -> String {
        if let value = userDefaultKey?.get(defaultValue: ""), !value.isEmpty {
            if keychainManager.save(value: value, forKey: keychainKey.rawValue) {
                userDefaultKey?.removeValue()
            }
            return value
        }
        
        if let value = keychainManager.getValueFor(key: keychainKey.rawValue), !value.isEmpty {
            return value
        }
        
        return ""
    }
    
    func exportKeysJSON(pin: String) -> String? {
        let (privateKey, publicKey) = getEncryptionKeys()
        let ip = getNodeIP()
        let authToken = getAuthToken()
        
        guard let privateK = privateKey, let publicK = publicKey, !ip.isEmpty, !authToken.isEmpty else {
            return nil
        }
        
        let keysArray = [privateK, publicK, ip, authToken]
        return SymmetricEncryptionManager.sharedInstance.encryptRestoreKeys(keys: keysArray, pin: pin)
    }
    
    //Keychain
    func getPubKeysForRestore() -> [String] {
        let pubKeys = keychainManager.getPubKeys()
        var validPubKeys = [String]()
        
        for pk in pubKeys {
            if let storedPubKeys = keychainManager.getAllValuesFor(pubKey: pk), storedPubKeys.count == 5 {
                validPubKeys.append(pk)
            }
        }
        return validPubKeys
    }
    
    func getAllValuesFor(pubKey: String) -> [String]? {
        return keychainManager.getAllValuesFor(pubKey: pubKey)
    }
    
    func resetAllFor(pubKey: String) {
        keychainManager.resetAllFor(pubKey: pubKey)
    }
    
    func resetKeychainNodeWith(ip: String) {
        keychainManager.resetKeychainNodeWith(ip: ip)
    }
    
    func isRestoreAvailable() -> Bool {
        return getPubKeysForRestore().count > 0
    }
    
    func saveNewNodeOnKeychain() {
        if let ownerPK = getUserPubKey() {
            keychainManager.saveNewNodeFor(pubKey: ownerPK)
            forcePINSyncOnKeychain()
        }
    }
    
    func forcePINSyncOnKeychain() {
        let _ = getAppPin()
    }
    
    //Clear User Data
    func clearData() {
        SphinxSocketManager.sharedInstance.disconnectWebsocket()
        EncryptionManager.sharedInstance.deleteOldKeys()
        CoreDataManager.sharedManager.clearCoreDataStore()
        UserDefaults.resetUserDefaults()
    }
}
