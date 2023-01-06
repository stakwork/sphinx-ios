//
//  UserDefaults.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation

extension UserDefaults {
    public enum Keys {
        public static let lastSeenHistoryDate = DefaultKey<Date>("lastSeenHistoryDate")
        public static let lastSeenMessagesDate = DefaultKey<Date>("lastSeenMessagesDate")
        public static let lastSeenContactsDate = DefaultKey<Date>("lastSeenContactsDate")
        public static let channelBalance = DefaultKey<Int>("channelBalance")
        public static let remoteBalance = DefaultKey<Int>("remoteBalance")
        public static let currentIP = DefaultKey<String>("currentIP")
        public static let authToken = DefaultKey<String>("authToken")
        public static let transportKey = DefaultKey<String>("transportKey")
        public static let hmacKey = DefaultKey<String>("hmacKey")
        public static let ownerId = DefaultKey<Int>("ownerId")
        public static let ownerPubKey = DefaultKey<Int>("ownerPubKey")
        public static let inviteString = DefaultKey<String>("inviteString")
        public static let deviceId = DefaultKey<String>("deviceId")
        public static let chatId = DefaultKey<Int>("chatId")
        public static let contactId = DefaultKey<Int>("contactId")
        public static let subscriptionQuery = DefaultKey<String>("subscriptionQuery")
        public static let invoiceQuery = DefaultKey<String>("invoiceQuery")
        public static let tribeQuery = DefaultKey<String>("tribeQuery")
        public static let stakworkPaymentQuery = DefaultKey<String>("stakworkPaymentQuery")
        public static let attachmentsToken = DefaultKey<String>("attachmentsToken")
        public static let inviterNickname = DefaultKey<String>("inviterNickname")
        public static let inviterPubkey = DefaultKey<String>("inviterPubkey")
        public static let inviterRouteHint = DefaultKey<String>("inviterRouteHint")
        public static let inviteAction = DefaultKey<String>("inviteAction")
        public static let nodePassword = DefaultKey<String>("nodePassword")
        public static let welcomeMessage = DefaultKey<String>("welcomeMessage")
        public static let signupStep = DefaultKey<Int>("signupStep")
        public static let messagesFetchPage = DefaultKey<Int>("messagesFetchPage")
        public static let paymentProcessedInvites = DefaultKey<[String]>("paymentProcessedInvites")
        public static let challengeQuery = DefaultKey<String>("challengeQuery")
        public static let redeemSatsQuery = DefaultKey<String>("redeemSatsQuery")
        public static let authQuery = DefaultKey<String>("authQuery")
        public static let personQuery = DefaultKey<String>("personQuery")
        public static let saveQuery = DefaultKey<String>("saveQuery")
        
        public static let previousIP = DefaultKey<String>("previousIP")
        
        public static let defaultPIN = DefaultKey<String>("currentPin")
        public static let privacyPIN = DefaultKey<String>("privacyPIN")
        public static let currentSessionPin = DefaultKey<String>("currentSessionPin")
        public static let lastPinDate = DefaultKey<Date>("lastPinDate")
        public static let pinHours = DefaultKey<Int>("pinHours")
        public static let privacyPinHours = DefaultKey<Int>("privacyPinHours")
        
        public static let inviteServerURL = DefaultKey<String>("inviteServerURL")
        public static let fileServerURL = DefaultKey<String>("fileServerURL")
        public static let meetingServerURL = DefaultKey<String>("meetingServerURL")
        public static let meetingPmtAmount = DefaultKey<Int>("meetingPmtAmount")
        
        public static let appAppearence = DefaultKey<Int>("appAppearence")
        public static let messagesSize = DefaultKey<Int>("messagesSize")
        public static let webViewsHeight = DefaultKey<Int>("webViewsHeight")
        
        public static let setupSigningDevice = DefaultKey<Bool>("setupSigningDevice")
        public static let shouldTrackActions = DefaultKey<Bool>("shouldTrackActions")
    }
    
    class func resetUserDefaults() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
    }
    
    func object<T: Codable>(_ type: T.Type, with key: String, usingDecoder decoder: JSONDecoder = JSONDecoder()) -> T? {
        guard let data = self.value(forKey: key) as? Data else { return nil }
        return try? decoder.decode(type.self, from: data)
    }

    func set<T: Codable>(object: T, forKey key: String, usingEncoder encoder: JSONEncoder = JSONEncoder()) {
        let data = try? encoder.encode(object)
        self.set(data, forKey: key)
    }
}

public class DefaultKey<T> {
    private let name: String
    
    init(_ name: String) {
        self.name = name
    }
    
    func get<T>() -> T? {
        return UserDefaults.standard.value(forKey: name) as? T
    }
    
    func getObject<T: Codable>() -> T? {
        return UserDefaults.standard.object(T.self, with: name)
    }
    
    func get<T>(defaultValue: T) -> T {
        return (UserDefaults.standard.value(forKey: name) as? T) ?? defaultValue
    }
    
    func set<T>(_ value: T?) {
        if let value = value {
            UserDefaults.standard.setValue(value, forKey: name)
            UserDefaults.standard.synchronize()
        } else {
            removeValue()
        }
    }
    
    func setObject<T: Codable>(_ object: T?) {
        if let object = object {
            UserDefaults.standard.set(object: object, forKey: name)
            UserDefaults.standard.synchronize()
        } else {
            removeValue()
        }
    }
    
    public func removeValue() {
        UserDefaults.standard.removeObject(forKey: name)
        UserDefaults.standard.synchronize()
    }
}
