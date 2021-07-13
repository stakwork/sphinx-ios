//
//  SymmetricEncryptionManager.swift
//  sphinx
//
//  Created by Tomas Timinskas on 10/02/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import RNCryptor

class SymmetricEncryptionManager {

    class var sharedInstance : SymmetricEncryptionManager {
        struct Static {
            static let instance = SymmetricEncryptionManager()
        }
        return Static.instance
    }
    
    func encryptString(text: String, key: String) -> String? {
        if let data = text.data(using: .utf8) {
            let encryptedData = RNCryptor.encrypt(data: data, withPassword: key)
            return encryptedData.base64EncodedString()
        }
        return nil
    }
    
    func decryptString(text: String, key: String) -> String? {
        var decryptedData : Data? = nil
        
        if let data = Data(base64Encoded: text) {
            do {
                decryptedData = try RNCryptor.decrypt(data: data, withPassword: key)
            } catch {
                print(error)
            }
            
            if let decryptedData = decryptedData {
                return String(decoding: decryptedData, as: UTF8.self)
            }
        }
        return nil
    }
    
    func encryptImage(image: UIImage?) -> (String, Data?) {
        guard let imgData = image?.jpegData(compressionQuality: 0.5) else {
            return ("", nil)
        }
             
        return encryptData(data: imgData)
    }
    
    func decryptImage(data: Data?, key: String) -> UIImage? {
        if let decryptedData = decryptData(data: data, key: key) {
            let decryptedImage = UIImage(data: decryptedData)
            return decryptedImage
        }
        return nil
    }
    
    func encryptData(data: Data) -> (String, Data?) {
        let key = EncryptionManager.randomString(length: 32)
        let encryptedData = RNCryptor.encrypt(data: data, withPassword: key)
        return (key, encryptedData)
    }
    
    func decryptData(data: Data?, key: String) -> Data? {
        var decryptedData : Data? = nil
        if let data = data {
            do {
                decryptedData = try RNCryptor.decrypt(data: data, withPassword: key)
            } catch {
                print(error)
            }
            
            if let decryptedData = decryptedData {
                return decryptedData
            }
        }
        
        return nil
    }
    
    func encryptRestoreKeys(keys: [String], pin: String) -> String? {
        if keys.count < 4 {
            return nil
        }
        
        let keysString = "\(keys[0])::\(keys[1])::\(keys[2])::\(keys[3])"
        
        if let encryptedKeys = encryptString(text: keysString, key: pin) {
            let jsonString = "keys::\(encryptedKeys)".base64Encoded
            return jsonString
        }

        return nil
    }
    
    func decryptRestoreKeys(encryptedKeys: String, pin: String) -> [String]? {
        if let decodedKeys = decryptString(text: encryptedKeys, key: pin) {
            let keys = decodedKeys.components(separatedBy: "::")
            if keys.count == 4 {
                return keys
            }
        }
        return nil
    }
}
