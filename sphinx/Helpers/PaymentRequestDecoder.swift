//
//  PaymentRequestDecoder.swift
//  sphinx
//
//  Created by Tomas Timinskas on 26/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation

public class PaymentRequestDecoder {
    
    public static let prefixes = ["lnbc", "lntb", "lnbcrt"]
    
    var paymentRequestString : String?
    var decodedPR : NSDictionary?
    
    private let checksumMarker: Character = "1"
    
    private let bech32CharValues = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
    
    func isZeroAmountInvoice(invoice:String)->Bool{
        return invoice.starts(with: "lnbc1pj7t")
    }
    
    func isPaymentRequest() -> Bool {
        return decodedPR != nil
    }
    
    func getAmount() -> Int? {
        guard let pr = decodedPR else {
            return nil
        }
        
        if let hrp = pr["human_readable_part"] as? NSDictionary {
            if let mSatAmountString = hrp["amount"] as? String {
                if let amountInt = Int(mSatAmountString) {
                    return amountInt / 1000
                }
            }
        }
        return nil
    }
    
    func getDate() -> Date? {
        guard let pr = decodedPR else {
            return nil
        }
        if let data = pr["data"] as? NSDictionary {
            if let date = data["time_stamp"] as? Date {
                return date
            }
        }
        return nil
    }
    
    func getTagWith(type: String) -> NSDictionary? {
        guard let pr = decodedPR else {
            return nil
        }
        
        if let data = pr["data"] as? NSDictionary {
            if let tags = data["tags"] as? [NSDictionary] {
                for tag in tags {
                    if let t = tag["type"] as? String, t == type {
                        return tag
                    }
                }
            }
        }
        return nil
    }
    
    func getExpirationDate() -> Date? {
        guard let pr = decodedPR else {
            return nil
        }
        
        if let data = pr["data"] as? NSDictionary {
            if let date = data["time_stamp"] as? Date {
                var expiry = 3600
                
                if let expiryTag = getTagWith(type: "x") {
                    if let value = expiryTag["value"] as? Int {
                        expiry = value
                    }
                }
                
                return date.addingTimeInterval(TimeInterval(expiry))
            }
        }
        
        return nil
    }
    
    func getMemo() -> String? {
        if let descriptionTag = getTagWith(type: "d") {
            if let memo = descriptionTag["value"] as? String {
                return memo
            }
        }
        
        return nil
    }
    
    func decodePaymentRequest(paymentRequest: String) {
        self.paymentRequestString = paymentRequest
        
        let input = paymentRequest.lowercased().replacingOccurrences(of: "lightning:", with: "")
        if let splitPosition = input.lastIndex(of: checksumMarker) {
            let index = splitPosition.utf16Offset(in: input) - 1
            if index < 0 {
                return
            }
            let humanReadablePart = input.substring(toIndexIncluded: index)
            let startIndex = splitPosition.utf16Offset(in: input) + 1
            let endIndex = input.count - 6
            
            if endIndex < startIndex {
                return
            }
            
            let data = input.substring(fromIndex: startIndex, toIndex: endIndex)
            let checksum = input.substring(fromIndex: input.count - 6, toIndex: input.count)
            
            if (!verifyChecksum(hrp: humanReadablePart, data: bech32ToFiveBitArray(str: "\(data)\(checksum)"))) {
                decodedPR = nil
                return
            }
            
            guard let hdr = decodeHumanReadablePart(humanReadablePart: humanReadablePart),
                  let d = decodeData(data: data, humanReadablePart: humanReadablePart) else {
                return
            }
            
            decodedPR = [
                "human_readable_part": hdr,
                "data": d,
                "checksum": checksum
            ]
            return
        }
        decodedPR = nil
    }
    
    func verifyChecksum(hrp: String, data: [Int]) -> Bool {
        let hrp = expand(str: hrp)
        let all = hrp
        let bool = polymod(values: all)
        return bool
    }
    
    func expand(str: String) -> [Int] {
        var array = [Int]()
        
        for i in 0..<str.length {
            if let asciiCode = UnicodeScalar(String(str[String.Index(utf16Offset: i, in: str)]))?.value {
                let asciiCodeInt = Int(asciiCode)
                array.append(asciiCodeInt >> 5)
            }
        }
        array.append(0)
        for i in 0..<str.length {
            if let asciiCode = UnicodeScalar(String(str[String.Index(utf16Offset: i, in: str)]))?.value {
                let asciiCodeInt = Int(asciiCode)
                array.append(asciiCodeInt & 31)
            }
        }
        return array
    }
    
    func polymod(values: [Int]) -> Bool {
        let GEN = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3]
        var chk = 1
        for value in values {
            let b = (chk >> 25)
            chk = (chk & 0x1ffffff) << 5 ^ value
            for i in 0..<5 {
                if (((b >> i) & 1) == 1) {
                    chk ^= GEN[i]
                } else {
                    chk ^= 0
                }
            }
        }
        return Bool(truncating: NSNumber(value:chk))
    }
    
    func decodeHumanReadablePart(humanReadablePart: String) -> NSDictionary? {
        var prefix: String = ""
        
        for pref in PaymentRequestDecoder.prefixes {
            let p = humanReadablePart.substring(fromIndex: 0, toIndex: pref.count)
            if (p == pref) {
                prefix = pref
            }
        }
        
        if (prefix == "") {
            return nil
        }
        
        let amountString = humanReadablePart.substring(fromIndex: prefix.count, toIndex: humanReadablePart.count)
        if let amount = decodeAmount(str: String(amountString)) {
            return [
                "prefix" : prefix,
                "amount" : amount
            ]
        }
        
        return nil
    }
    
    func decodeData(data: String, humanReadablePart: String) -> NSDictionary? {
        let date32 = data.substring(fromIndex: 0, toIndex: 7)
        let dateEpoch = epochToDate(int: bech32ToInt(str: String(date32)))
        let signature = data.substring(fromIndex: data.count - 104, toIndex: data.count)
        let tagData = data.substring(fromIndex: 7, toIndex: data.count - 104)
        
        let decodedTags = decodeTags(tagData: String(tagData))
        var value = bech32ToFiveBitArray(str: "\(date32)\(tagData)")
        value = fiveBitArrayTo8BitArray(int5Array: value, includeOverflow: true)
        let first = textToHexString(text: humanReadablePart)
        let second = byteArrayToHexString(byteArray: value)
        let valueString = "\(first)\(second)"

          return [
            "time_stamp": dateEpoch,
            "tags": decodedTags,
            "signature": decodeSignature(signature: String(signature)),
            "signing_data": valueString
        ]
    }
    
    func decodeTags(tagData: String) -> [NSDictionary] {
        let tags = extractTags(str: tagData)
        
        var decodedTags = [NSDictionary]()
        
        for tag in tags {
            if let type = tag["type"], let length = tag["length"], let lengthInt = Int(length), let data = tag["data"] {
                decodedTags.append(decodeTag(type: type, length: lengthInt, data: data))
            }
        }
        
        return decodedTags
    }
    
    func decodeSignature(signature: String) -> NSDictionary {
        let data = fiveBitArrayTo8BitArray(int5Array: bech32ToFiveBitArray(str: signature), includeOverflow: false)
        let recoveryFlag = data[data.count - 1]
        let r = byteArrayToHexString(byteArray: Array(data[..<32]))
        let s = byteArrayToHexString(byteArray: Array(data[32..<data.count - 1]))
        
        return [
            "r": r,
            "s": s,
            "recovery_flag": recoveryFlag
        ]
    }

    func extractTags(str: String) -> [[String: String]] {
        var tags = [[String: String]]()
        var string = str
        
        while (string.length > 0) {
            let typeString = string.charAt(index: 0)
            let substring = string.substring(fromIndex: 1, toIndex: 3)
            let dataLength = bech32ToInt(str: String(substring))
            let data = string.substring(fromIndex: 3, toIndex: dataLength + 3)
            
            
            
            tags.append([
                "type": String(typeString),
                "length": "\(dataLength)",
                "data": String(data)
            ])

            if 3 + dataLength <= string.count {
                string = string.substring(fromIndex: 3 + dataLength, toIndex: string.count)
            } else {
                string = ""
            }
        }
        
        return tags
    }
    
    func decodeTag(type: String, length: Int, data: String) -> NSDictionary {
        switch (type) {
            case "p":
                if (length != 52) {
                    break
                }
                
                return [
                    "type": type,
                    "length": "\(length)",
                    "description": "payment_hash",
                    "value": byteArrayToHexString(byteArray: fiveBitArrayTo8BitArray(int5Array: bech32ToFiveBitArray(str: data), includeOverflow: false))
                ]
            case "d":
                return [
                    "type": type,
                    "length": "\(length)",
                    "description": "description",
                    "value": bech32ToUTF8String(str: data)
                ]
            case "n":
                if (length != 53) {
                    break
                }
                return [
                    "type": type,
                    "length": "\(length)",
                    "description": "payee_public_key",
                    "value": byteArrayToHexString(byteArray: fiveBitArrayTo8BitArray(int5Array: bech32ToFiveBitArray(str: data), includeOverflow: false))
                ]
            case "h":
                if (length != 52) {
                    break
                }
                return [
                    "type": type,
                    "length": "\(length)",
                    "description": "description_hash",
                    "value": data
                ]
            case "x":
                return [
                    "type": type,
                    "length": "\(length)",
                    "description": "expiry",
                    "value": bech32ToInt(str: data)
                ]
            case "c":
                return [
                    "type": type,
                    "length": "\(length)",
                    "description": "min_final_cltv_expiry",
                    "value": bech32ToInt(str: data)
                ]
            case "f":
                let versionString = data.charAt(index: 0)
                let version = bech32ToFiveBitArray(str: String(versionString))[0]
                if (version < 0 || version > 18) {
                    break
                }
                
                let fallbackAddress = data.substring(fromIndex: 1, toIndex: data.count)
                
                let versionDictionary: NSDictionary = [
                    "version": version,
                    "fallback_address": fallbackAddress
                ]
                
                return [
                    "type": type,
                    "length": "\(length)",
                    "description": "fallback_address",
                    "value": versionDictionary
                ]
            case "r":
                let rData = fiveBitArrayTo8BitArray(int5Array: bech32ToFiveBitArray(str: data), includeOverflow: false)
                let pubkey = Array(rData[0..<33])
                let shortChannelId = Array(rData[33..<41])
                let feeBaseMsat = Array(rData[41..<45])
                let feeProportionalMillionths = Array(rData[45..<49])
                let cltvExpiryDelta = Array(rData[49..<51])
                
                let valueDictionary: NSDictionary = [
                    "public_key": byteArrayToHexString(byteArray: pubkey),
                    "short_channel_id": byteArrayToHexString(byteArray: shortChannelId),
                    "fee_base_msat": byteArrayToInt(byteArray: feeBaseMsat),
                    "fee_proportional_millionths": byteArrayToInt(byteArray: feeProportionalMillionths),
                    "cltv_expiry_delta": byteArrayToInt(byteArray: cltvExpiryDelta)
                ]

                return [
                    "type": type,
                    "length": length,
                    "description": "routing_information",
                    "value": valueDictionary
                ]
            default:
                return [:]
        }
        return [:]
    }
    
    func bech32ToInt(str: String) -> Int {
        var sum = 0;
        for i in 0..<str.count {
            sum = sum * 32
            let charAtIndex = str.charAt(index: i)
            if let indexOf = bech32CharValues.index(of: charAtIndex) {
                let i = indexOf.utf16Offset(in: bech32CharValues)
                sum = sum + i
            }
        }
        return sum
    }
    
    func bech32ToFiveBitArray(str: String) -> [Int] {
        var array = [Int]()
        for i in 0..<str.count {
            let charAtIndex = str.charAt(index: i)
            if let indexOf = bech32CharValues.index(of: charAtIndex) {
                let i = indexOf.utf16Offset(in: bech32CharValues)
                array.append(i)
            }
        }
        return array
    }
    
    func byteArrayToInt(byteArray: [Int]) -> Int {
        var value = 0
        for i in 0..<byteArray.count {
            value = (value << 8) + byteArray[i]
        }
        return value
    }
    
    func fiveBitArrayTo8BitArray(int5Array: [Int], includeOverflow: Bool) -> [Int] {
        var count = 0
        var buffer = 0
        var byteArray = [Int]()
        
        for value in int5Array {
            buffer = (buffer << 5) + value
            count += 5
            if (count >= 8) {
                byteArray.append(buffer >> (count - 8) & 255)
                count -= 8
            }
        }
        
        if (includeOverflow && count > 0) {
            byteArray.append(buffer << (8 - count) & 255);
        }
        return byteArray
    }
    
    func bech32ToUTF8String(str: String) -> String {
        let int5Array = bech32ToFiveBitArray(str: str)
        let byteArray = fiveBitArrayTo8BitArray(int5Array: int5Array, includeOverflow: false)

        var utf8String = ""
        for i in 0..<byteArray.count {
            let string = "0\(String(format:"%02X", byteArray[i]))"
            let substring = string.substring(fromIndex: string.count - 2, toIndex: string.count)
            utf8String = "\(utf8String)%\(substring)"
        }
        
        if let uri = utf8String.decodeUrl() {
            return uri
        }
        return ""
    }
    
    func byteArrayToHexString(byteArray: [Int]) -> String {
        let string = byteArray.map { byte -> String in
            let b = (byte & 0xFF)
            let bString = "0\(String(format:"%02X", b))"
            let bSubstring = bString.substring(fromIndex: bString.count - 2, toIndex: bString.count)
            
            return "\(bSubstring)"
        }
        
        return string.joined(separator: "").lowercased()
    }
    
    func textToHexString(text: String) -> String {
        let data = Data(text.utf8)
        let hexString = data.map{ String(format:"%02x", $0) }.joined()
        return hexString
    }
    
    func epochToDate(int: Int) -> Date {
        let date = Date(timeIntervalSince1970: TimeInterval(int))
        return date
    }
    
    func decodeAmount(str: String) -> String? {
        if str.isEmpty {
            return nil
        }
        
        let multiplier = str.charAt(index: str.count - 1)
        let amount = str.substring(fromIndex: 0, toIndex: str.count - 1)
        let firstAmountChar = str.charAt(index: 0)
        
        if (String(firstAmountChar) == "0") {
            return "error"
        }
        
        if let amountInt = Int(amount) {
            if (amountInt < 0) {
                return "error"
            }
            
            switch (String(multiplier)) {
                case "":
                    return "Any amount"
                case "p":
                    return "\(amountInt / 10)"
                case "n":
                    return "\(amountInt * 100)"
                case "u":
                    return "\(amountInt * 100000)"
                case "m":
                    return "\(amountInt * 100000000)"
                default:
                    return "error"
            }
        }
        return "error"
    }
}
