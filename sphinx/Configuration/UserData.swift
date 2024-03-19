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
    
    public static let kMaximumPINHoursValue: Int = 25
    public static let kMinimumMemoryFootprintGB : Int = 0
    public static var kMaximumMemoryFootprintGB : Int = {
        if let max = getTotalDiskStorage(){
            return Int(Double(max)/1e9)
        }
        else{
            return 100
        }
    }()
    
    static func getTotalDiskStorage() -> UInt64? {
        do {
            let resourceURL = URL(fileURLWithPath: "/")
            let resourceValues = try resourceURL.resourceValues(forKeys: [.volumeTotalCapacityKey])
            if let totalCapacity = resourceValues.volumeTotalCapacity {
                return UInt64(totalCapacity)
            }
        } catch {
            print("Error: \(error)")
        }
        return nil
    }
    
    func isUserLogged() -> Bool {
        if(getMnemonic() != nil &&
           getAppPin() != ""){ //v2
            return SignupHelper.isLogged()
        }
        return getAppPin() != "" &&
               getNodeIP() != "" &&
               getAuthToken() != "" &&
               SignupHelper.isLogged()
    }
    
    func getAuthenticationHeader(
        token: String? = nil,
        transportKey: String? = nil
    ) -> [String: String] {
        
        let t = token ?? getAuthToken()
        
        if t.isEmpty {
            return [:]
        }
        
        if let transportK = transportKey ?? getTransportKey(),
           let transportEncryptionKey = EncryptionManager.sharedInstance.getPublicKeyFromBase64String(base64String: transportK) {
            
            let timestamp = NSDate().timeIntervalSince1970
            let time = Int(ceil(timestamp))
            let tokenAndTime = "\(t)|\(time)"
            
            if let encryptedToken = EncryptionManager.sharedInstance.encryptToken(token: tokenAndTime, key: transportEncryptionKey) {
                return ["x-transport-token": encryptedToken]
            }
            
        }
        return ["X-User-Token": t]
    }
    
    func getHMACHeader(
        url: URL,
        method: String,
        bodyData: Data?
    ) -> [String: String] {
        
        let path = url.pathWithParams
        var signingString = "\(method)|\(path)|"
        
        if let bodyData = bodyData {
            
            if let bodyJsonString = String(
                data: bodyData,
                encoding: .utf8
            ) {
                signingString = "\(signingString)\(bodyJsonString)"
            }
            
        }
        
        if let HMACKey = getHmacKey() {
            return [
                "x-hmac": signingString.hmac(algorithm: .SHA256, key: HMACKey)
            ]
        }
        
        return [:]
    }
    
    func getAndSaveTransportKey(
        forceGet: Bool = false,
        completion: ((String?) ->())? = nil
    ) {
        if let transportKey = getTransportKey(), !transportKey.isEmpty && !forceGet {
            completion?(transportKey)
            return
        }
        
        fetchAndSaveTransportKey(completion: completion)
    }
    
    func fetchAndSaveTransportKey(
        completion: ((String?) ->())? = nil
    ) {
        API.sharedInstance.getTransportKey(callback: { transportKey in
            self.save(transportKey: transportKey)
            completion?(transportKey)
        }, errorCallback: {
            completion?(nil)
        })
    }
    
    func getAndSaveHMACKey(
        forceGet: Bool = false,
        completion: (() -> ())? = nil,
        noKeyCompletion: (() -> ())? = nil
    ) {
        if let hmacKey = getHmacKey(), !hmacKey.isEmpty && !forceGet {
            completion?()
            return
        }
        
        deleteHmacKey()
        
        API.sharedInstance.getHMACKey(callback: { hmacKey in
            let (decrypted, decryptedHMACKey) = EncryptionManager.sharedInstance.decryptMessage(message: hmacKey)
            if decrypted {
                self.save(hmacKey: decryptedHMACKey)
                completion?()
            }
        }, errorCallback: {
            noKeyCompletion?()
        })
    }
    
    func getOrCreateHMACKey(
        forceGet: Bool = false,
        completion: (() -> ())? = nil
    ) {
        if let hmacKey = getHmacKey(), !hmacKey.isEmpty && !forceGet {
            completion?()
            return
        }
        
        getAndSaveHMACKey(
            forceGet: forceGet,
            completion: completion,
            noKeyCompletion: {
                self.createHMACKey(completion: completion)
            }
        )
    }
    
    func createHMACKey(
        completion: (() -> ())? = nil
    ) {
        let HMACKey = EncryptionManager.randomString(length: 20)
        
        var parameters = [String : AnyObject]()
        
        if let transportK = self.getTransportKey(),
           let transportEncryptionKey = EncryptionManager.sharedInstance.getPublicKeyFromBase64String(base64String: transportK) {
            
            if let encryptedHMACKey = EncryptionManager.sharedInstance.encryptToken(token: HMACKey, key: transportEncryptionKey) {
                parameters["encrypted_key"] = encryptedHMACKey as AnyObject?
            } else {
                completion?()
                return
            }
        }
        
        API.sharedInstance.addHMACKey(
            params: parameters,
            callback: { _ in
                self.save(hmacKey: HMACKey)
                completion?()
            },
            errorCallback: {
                completion?()
            }
        )
    }
    
    func generateToken(
        token: String,
        pubkey: String,
        password: String? = nil,
        completion: @escaping () -> (),
        errorCompletion: @escaping () -> ()
    ) {
        getAndSaveTransportKey(completion: { transportKey in
            if let transportKey = transportKey {
                    
                let authenticatedHeader = self.getAuthenticationHeader(
                    token: token,
                    transportKey: transportKey
                )
                
                API.sharedInstance.generateToken(
                    pubkey: pubkey,
                    password: password,
                    additionalHeaders: authenticatedHeader,
                    callback: { [weak self] success in
                        guard let self = self else { return }
                    
                        if success {
                            self.saveTokenAndContinue(
                                token: token,
                                transportKey: transportKey,
                                completion: completion
                            )
                        } else {
                            errorCompletion()
                        }
                    },
                    errorCallback: {
                        errorCompletion()
                    }
                )
            } else {
                API.sharedInstance.generateTokenUnauthenticated(
                    token: token,
                    pubkey: pubkey,
                    password: password,
                    callback: { [weak self] success in
                        guard let self = self else { return }
                        
                        if success {
                            self.saveTokenAndContinue(
                                token: token,
                                transportKey: transportKey,
                                completion: completion
                            )
                        } else {
                            errorCompletion()
                        }
                    }, errorCallback: {
                        errorCompletion()
                    })
            }
        })
    }
    
    func continueWithToken(
        token: String,
        completion: @escaping () -> (),
        errorCompletion: @escaping () -> ()
    ) {
        getAndSaveTransportKey(completion: { transportKey in
            if let transportKey = transportKey {
                self.saveTokenAndContinue(
                    token: token,
                    transportKey: transportKey,
                    completion: completion)
            } else {
                errorCompletion()
            }
        })
        
    }
    
    func saveTokenAndContinue(
        token: String,
        transportKey: String?,
        completion: @escaping () -> ()
    ) {
        self.save(authToken: token)
        
        if let transportKey = transportKey {
            self.save(transportKey: transportKey)
            
            self.createHMACKey() {
                completion()
            }
            return
        }
        
        completion()
    }
    
    func getPINNeverOverride() -> Bool {
        if GroupsPinManager.sharedInstance.isStandardPIN {
            return UserDefaults.Keys.pinHours.get(
                defaultValue: UserData.kMaximumPINHoursValue
            ) == UserData.kMaximumPINHoursValue
        } else {
            return UserDefaults.Keys.privacyPinHours.get(
                defaultValue: UserData.kMaximumPINHoursValue
            ) == UserData.kMaximumPINHoursValue
        }
    }
    
    func getPINHours() -> Int {
        if GroupsPinManager.sharedInstance.isStandardPIN {
            return UserDefaults.Keys.pinHours.get(defaultValue: UserData.kMaximumPINHoursValue)
        } else {
            return UserDefaults.Keys.privacyPinHours.get(defaultValue: UserData.kMaximumPINHoursValue)
        }
    }
    
    func setPINHours(hours: Int) {
        if GroupsPinManager.sharedInstance.isStandardPIN {
            UserDefaults.Keys.pinHours.set(hours)
        } else {
            UserDefaults.Keys.privacyPinHours.set(hours)
        }
    }
    
    func getMaxMemoryGB() -> Int {
        let result = UserDefaults.Keys.maxMemory.get(defaultValue: UserData.kMaximumMemoryFootprintGB)
        return result
    }
    
    func setMaxMemory(GB: Int) {
        UserDefaults.Keys.maxMemory.set(GB)
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
    
    func save(
        ip: String,
        token: String,
        pin: String
    ) {
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
        saveValueFor(value: ip, for: KeychainManager.KeychainKeys.ip, userDefaultKey: UserDefaults.Keys.currentIP)
    }
    
    func revertIP() {
        if let previuosIP: String = UserDefaults.Keys.previousIP.get() {
            saveValueFor(value: previuosIP, for: KeychainManager.KeychainKeys.ip, userDefaultKey: UserDefaults.Keys.currentIP)
        }
    }
    
    func save(authToken: String) {
        saveValueFor(value: authToken, for: KeychainManager.KeychainKeys.authToken, userDefaultKey: UserDefaults.Keys.authToken)
    }
    
    func save(transportKey: String) {
        saveValueFor(value: transportKey, for: KeychainManager.KeychainKeys.transportKey, userDefaultKey: UserDefaults.Keys.transportKey)
    }
    
    func save(hmacKey: String) {
        saveValueFor(value: hmacKey, for: KeychainManager.KeychainKeys.hmacKey, userDefaultKey: UserDefaults.Keys.hmacKey)
    }
    
    func deleteHmacKey() {
        let _ = keychainManager.deleteValueFor(key: KeychainManager.KeychainKeys.hmacKey.rawValue)
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
        return nodeIp
    }
    
    func getAuthToken() -> String {
        return getValueFor(keychainKey: KeychainManager.KeychainKeys.authToken, userDefaultKey: UserDefaults.Keys.authToken)
    }
    
    func getTransportKey() -> String? {
        let transportKey = getValueFor(keychainKey: KeychainManager.KeychainKeys.transportKey, userDefaultKey: UserDefaults.Keys.transportKey)
        if !transportKey.isEmpty {
            return transportKey
        }
        return nil
    }
    
    func getHmacKey() -> String? {
        let hmacKey = getValueFor(keychainKey: KeychainManager.KeychainKeys.hmacKey, userDefaultKey: UserDefaults.Keys.hmacKey)
        if !hmacKey.isEmpty {
            return hmacKey
        }
        return nil
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
    
    func save(walletMnemonic: String) {
        let _ = keychainManager.save(value: walletMnemonic, forComposedKey: KeychainManager.KeychainKeys.walletMnemonic.rawValue)
    }
    
    func getMnemonic() -> String? {
        if let value = keychainManager.getValueFor(composedKey: KeychainManager.KeychainKeys.walletMnemonic.rawValue), !value.isEmpty {
            return value
        }
        return nil
    }
    
    func save(balance: UInt64){
        let _ = keychainManager.save(value: String(balance), forComposedKey: KeychainManager.KeychainKeys.balance_msats.rawValue)
    }
    
    func getBalanceSats() -> Int?{
        if let value = keychainManager.getValueFor(composedKey: KeychainManager.KeychainKeys.balance_msats.rawValue), !value.isEmpty,
         let intValue = Int(value){
            return intValue/1000 //convert to sats
        }
        return nil
    }
    
    func setLastMessageIndex(index:Int){
        UserDefaults.Keys.lastV2MessageIndex.set(index)
    }
    
    func getLastMessageIndex() -> Int? {
        return UserDefaults.Keys.lastV2MessageIndex.get()
    }
    
    //Clear User Data
    func clearData() {
        SphinxSocketManager.sharedInstance.disconnectWebsocket()
        EncryptionManager.sharedInstance.deleteOldKeys()
        CoreDataManager.sharedManager.clearCoreDataStore()
        clearMnemonic()
        UserDefaults.resetUserDefaults()
    }
    
    func clearMnemonic() {
        let _ = keychainManager.deleteValueFor(composedKey: KeychainManager.KeychainKeys.walletMnemonic.rawValue)
    }
}
