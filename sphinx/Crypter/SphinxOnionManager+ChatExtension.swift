//
//  SphinxOnionManager+ChatExtension.swift
//  sphinx
//
//  Created by James Carucci on 12/4/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import CocoaMQTT

extension SphinxOnionManager{
    func sendMessage(to contact: UserContact, content:String)->SphinxMsgError?{
//        guard let mnemonic = UserData.sharedInstance.getMnemonic(),
//              let seed = getAccountSeed(mnemonic: mnemonic),
//              let myOkKey = getAccountOnlyKeysendPubkey(seed: seed) else {
//            return SphinxMsgError.credentialsError
//        }
//        guard let recipPubkey = contact.publicKey, // OK key
//              let recipRouteHint = contact.contactRouteHint,
//              recipRouteHint.split(separator: "_").count == 2 else {
//            return SphinxMsgError.contactDataError
//        }
//
//        guard let selfContact = UserContact.getSelfContact(),
//              let selfRouteHint = selfContact.routeHint else {
//            return SphinxMsgError.credentialsError
//        }
//
//
//        let time = getTimestampInMilliseconds()
//
//        let senderInfo : [String:String] = [
//            "pubkey": myOkKey,
//            "routeHint": selfRouteHint,
//            "contactPubkey": recipContact.childPubKey,
////            "contactRouteHint": "020947fda2d645f7233b74f02ad6bd9c97d11420f85217680c9e27d1ca5d4413c1_0343f9e2945b232c5c0e7833acef052d10acf80d1e8a168d86ccb588e63cd962cd_529771090639978497",
//            "alias": (selfContact.nickname ?? "anon"),
//            "photo_url": ""
//        ]
//
//
//        guard let (contentJSONString,hopsJSONString) = constructKeyExchangeJSONString(isInitiatorMe: isInitiatorMe, recipPubkey: recipPubkey, recipRouteHint: recipRouteHint,myOkKey: myOkKey, selfRouteHint: selfRouteHint, selfContact: selfContact, recipContact: contact) else{
//            return SphinxMsgError.encodingError
//        }
//
//
//
//        do {
//            let onion = try! createOnionMsg(seed: seed, idx: UInt32(0), time: time, network: network, hops: hopsJSONString, json: contentJSONString)
//            //let onion = try! createOnion(seed: seed, idx: UInt32(0), time: time, network: network, hops: hopsJSONString, payload: finalData)
//            var onionAsArray = [UInt8](repeating: 0, count: onion.count)
//
//            // Use withUnsafeBytes to copy the Data into the UInt8 array
//            onion.withUnsafeBytes { bufferPointer in
//                guard let baseAddress = bufferPointer.baseAddress else {
//                    fatalError("Failed to get the base address")
//                }
//                memcpy(&onionAsArray, baseAddress, onion.count)
//                self.mqtt.publish(
//                    CocoaMQTTMessage(
//                        topic: "\(myOkKey)/0/req/send",
//                        payload: onionAsArray
//                    )
//                )
//            }
//
//        } catch {
//            return SphinxMsgError.encodingError
//        }
//
//        return nil
        
        return nil
    }
}
