//
//  String.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

extension String {
    
    var localized: String {
        get {
            return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
        }
    }
    
    var withoutBreaklines: String {
        get {
            return self.replacingOccurrences(of: "\n", with: " ")
        }
    }
    
    var nsRange : NSRange {
        return NSRange(self.startIndex..., in: self)
    }

    
    var length: Int {
      return count
    }

    subscript (i: Int) -> String {
      return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
      return self[fromIndex ..< length]
    }

    func substring(toIndex: Int) -> String {
      return self[0 ..< toIndex]
    }
    
    func charAt(index: Int) -> Character {
        let i = String.Index(utf16Offset: index, in: self)
        return self[i]
    }
    
    func substring(fromIndex: Int, toIndex: Int) -> String {
      return self[fromIndex ..< toIndex]
    }

    func substring(toIndexIncluded: Int) -> String {
        let end = String.Index(utf16Offset: toIndexIncluded, in: self)
        return String(self[...end])
    }
    
    func substring(fromIndex: Int, toIndexIncluded: Int) -> String {
      return self[fromIndex ..< toIndexIncluded]
    }
    
    func substringAfterLastOccurenceOf(_ char: Character) -> String? {
        if let lastIndex = self.lastIndex(of: char) {
            let index: Int = self.distance(from: self.startIndex, to: lastIndex) + 1
            return substring(fromIndex: index)
        }
        return nil
    }

    subscript (r: Range<Int>) -> String {
      let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                          upper: min(length, max(0, r.upperBound))))
      let start = index(startIndex, offsetBy: range.lowerBound)
      let end = index(start, offsetBy: range.upperBound - range.lowerBound)
      return String(self[start ..< end])
    }
    
    func starts(with prefixes: [String]) -> Bool {
        for prefix in prefixes where starts(with: prefix) {
            return true
        }
        return false
    }
    
    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
    
    func fixInvoiceString() -> String {
        var fixedInvoice = self
        
        let prefixes = PaymentRequestDecoder.prefixes
        for prefix in prefixes {
            if self.contains(prefix) {
                if let index = self.range(of: prefix)?.lowerBound {
                    let indexInt = index.utf16Offset(in: self)
                    fixedInvoice = self.substring(fromIndex: indexInt, toIndex: self.length)
                }
            }
        }
        return fixedInvoice
    }
    
    var fixedRestoreCode : String {
        get {
            let codeWithoutSpaces = self.replacingOccurrences(of: "\\n", with: "")
                                        .replacingOccurrences(of: "\\r", with: "")
                                        .replacingOccurrences(of: "\\s", with: "")
                                        .replacingOccurrences(of: " ", with: "")
            
            let fixedCode = codeWithoutSpaces.filter("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=".contains)
            
            return fixedCode
        }
    }
    
    func removeProtocol() -> String {
        return self.replacingOccurrences(of: "http://", with: "").replacingOccurrences(of: "https://", with: "")
    }
    
    func decodeUrl() -> String? {
        return self.removingPercentEncoding
    }
    
    var isRelayQRCode : Bool {
        get {
            return self.base64Decoded?.starts(with: "ip::") ?? false
        }
    }
    
    var isSwarmConnectCode : Bool {
        get {
            return self.localizedStandardContains("connect::")
        }
    }
    
    var isSwarmClaimCode : Bool {
        get {
            return self.localizedStandardContains("claim::")
        }
    }
    
    var isSwarmGlyphAction : Bool {//if they're signing up with their own signing device
        get {
            return self.localizedStandardContains("glyph")
        }
    }
    
    func getIPAndPassword() -> (String?, String?) {
        if let decodedString = self.base64Decoded, decodedString.starts(with: "ip::") {
            let stringWithoutPrefix = decodedString.replacingOccurrences(of: "ip::", with: "")
            let items = stringWithoutPrefix.components(separatedBy: "::")
            
            if items.count == 2 {
                return (items[0], items[1])
            }
        }
        return (nil, nil)
    }
    
    var isRestoreKeysString : Bool {
        get {
            return self.base64Decoded?.starts(with: "keys::") ?? false
        }
    }
    
    var isRestoreKeysStringLength : Bool {
        get {
            return self.length > 3000
        }
    }    
    
    func getRestoreKeys() -> String? {
        if let decodedString = self.base64Decoded, decodedString.starts(with: "keys::") {
            let stringWithoutPrefix = decodedString.replacingOccurrences(of: "keys::", with: "")
            return stringWithoutPrefix
        }
        return nil
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    func isEncryptedString() -> Bool {
        if let _ = Data(base64Encoded: self), self.hasSuffix("=") {
            return true
        }
        return false
    }
    
    func getBytesLength() -> Int {
        return self.utf8.count
    }
    
    func isValidLengthMemo() -> Bool {
        return getBytesLength() <= 639
    }
    
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
    
    var isValidEmail: Bool {
        get {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            return emailPred.evaluate(with: self)
        }
    }
    
    var isValidHTML: Bool {
        if self.isEmpty {
            return false
        }
        return (self.range(of: "<(\"[^\"]*\"|'[^']*'|[^'\">])*>", options: .regularExpression) != nil)
    }
    
    var percentEscaped: String? {
        return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
    }
    
    var percentNotEscaped: String? {
        return NSString(string: self).removingPercentEncoding
    }
    
    var fixedAlias: String {
        let ACCEPTABLE_CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"
        var fixedAlias = ""
        
        for ch in self.replacingOccurrences(of: " ", with: "_") {
            if (ACCEPTABLE_CHARACTERS.contains(ch)) {
                fixedAlias.append(ch)
            }
        }
        return fixedAlias
    }
    
    var stringLinks: [NSTextCheckingResult] {
        let textWithoutHightlights = self.replacingHightlightedChars
        let types: NSTextCheckingResult.CheckingType = .link
        let detector = try? NSDataDetector(types: types.rawValue)
        
        let matches = detector!.matches(
            in: textWithoutHightlights,
            options: [],
            range: NSMakeRange(0, textWithoutHightlights.utf16.count)
        )
        
        return matches
    }
    
    var pubKeyMatches: [NSTextCheckingResult] {
        let textWithoutHightlights = self.replacingHightlightedChars
        let pubkeyRegex = try? NSRegularExpression(pattern: "\\b[A-F0-9a-f]{66}\\b")
        let virtualPubkeyRegex = try? NSRegularExpression(pattern: "\\b[A-F0-9a-f]{66}:[A-F0-9a-f]{66}:[0-9]+\\b")
        
        let virtualPubkeyResults = virtualPubkeyRegex?.matches(
            in: textWithoutHightlights,
            range: NSRange(textWithoutHightlights.startIndex..., in: textWithoutHightlights)
        ) ?? []
        
        let pubkeyResults = pubkeyRegex?.matches(
            in: textWithoutHightlights,
            range: NSRange(textWithoutHightlights.startIndex..., in: textWithoutHightlights)
        ) ?? []
        
        return virtualPubkeyResults + pubkeyResults
    }
    
    var mentionMatches: [NSTextCheckingResult] {
        let textWithoutHightlights = self.replacingHightlightedChars
        let mentionRegex = try? NSRegularExpression(pattern: "\\B@[^\\s]+")
        
        return mentionRegex?.matches(
            in: textWithoutHightlights,
            range: NSRange(textWithoutHightlights.startIndex..., in: textWithoutHightlights)
        ) ?? []
    }
    
    var highlightedMatches: [NSTextCheckingResult] {
        let highlightedRegex = try? NSRegularExpression(pattern: "`(.*?)`", options: .dotMatchesLineSeparators)
        return highlightedRegex?.matches(in: self, range: NSRange(self.startIndex..., in: self)) ?? []
    }
    
    var replacingHightlightedChars: String {
        if !self.contains("`") {
            return self
        }
        
        var adaptedString = self
        let highlightedRegex = try? NSRegularExpression(pattern: "`(.*?)`", options: .dotMatchesLineSeparators)
        let matches =  highlightedRegex?.matches(in: self, range: NSRange(self.startIndex..., in: self)) ?? []
        
        for (index, match) in matches.enumerated() {
            
            ///Subtracting the previous matches delimiter characters since they have been removed from the string
            let substractionNeeded = index * 2
            let adaptedRange = NSRange(location: match.range.location - substractionNeeded, length: match.range.length)
            
            adaptedString = adaptedString.replacingOccurrences(
                of: "`",
                with: "",
                range: Range(adaptedRange, in: adaptedString)
            )
        }
        
        return adaptedString
    }
    
    var stringFirstWebLink : (String, NSRange)? {
        if let range = self.stringLinks.first?.range {
            let matchString = (self as NSString).substring(with: range) as String
            return (matchString, range)
        }
        return nil
    }
    
    var stringFirstTribeLink : (String, NSRange)? {
        for link in self.stringLinks {
            let range = link.range
            let matchString = (self as NSString).substring(with: range) as String
            if matchString.starts(with: "sphinx.chat://?action=tribe") {
                return (matchString, range)
            }
        }
        return nil
    }
    
    var stringFirstPubKey : (String, NSRange)? {
        if let range = self.pubKeyMatches.first?.range {
            let matchString = (self as NSString).substring(with: range) as String
            return (matchString, range)
        }
        return nil
    }
    
    var stringFirstLink: String? {
        let firstWebLink = stringFirstWebLink
        let firstContactLink = stringFirstPubKey
        let firstTribeJoinLink = stringFirstTribeLink
        
        var ranges = [NSRange]()

        if let firstWebLinkRange = firstWebLink?.1 {
            ranges.append(firstWebLinkRange)
        }
        
        if let firstContactLinkRange = firstContactLink?.1 {
            ranges.append(firstContactLinkRange)
        }
        
        if let firstTribeJoinLinkRange = firstTribeJoinLink?.1 {
            ranges.append(firstTribeJoinLinkRange)
        }
        
        ranges = ChatHelper.removeDuplicatedContainedFrom(urlRanges: ranges)
        
        if let firstLinkRange = ranges.first {
            return (self as NSString).substring(with: firstLinkRange) as String
        }
        
        return nil
    }
    
    func withProtocol(protocolString: String) -> String {
        if !self.contains(protocolString) {
            let linkString = "\(protocolString)://\(self)"
            return linkString
        }
        return self
    }
    
    var hasLinks: Bool {
        if self.isCallLink {
            return false
        }
        
        if stringLinks.count == 0 {
            return false
        }
        
        for link in stringLinks {
            let matchString = (self as NSString).substring(with: link.range) as String
            if matchString.isValidEmail || matchString.starts(with: "sphinx.chat://") {
                return false
            }
        }
        return !hasTribeLinks && !hasPubkeyLinks
    }
    
    var hasTribeLinks: Bool {
        for link in stringLinks {
            let matchString = (self as NSString).substring(with: link.range) as String
            if matchString.starts(with: "sphinx.chat://?action=tribe") {
                return true
            }
        }
        return false
    }
    
    var hasPubkeyLinks: Bool {
        if let contactInfo = SphinxOnionManager.sharedInstance.parseContactInfoString(fullContactInfo: self){
            return true
        }
        return pubKeyMatches.count > 0 && !hasTribeLinks
    }
    
    var isTribeJoinLink : Bool {
        get {
            return self.starts(with: "sphinx.chat://?action=tribe")
        }
    }
    
    var isPubKey : Bool {
        get {
            let pubkeyRegex = try? NSRegularExpression(pattern: "^[A-F0-9a-f]{66}$")
            return (pubkeyRegex?.matches(in: self, range: NSRange(self.startIndex..., in: self)) ?? []).count > 0 || self.isVirtualPubKey
        }
    }
    
    var isRouteHint : Bool {
        get {
            let routeHintRegex = try? NSRegularExpression(pattern: "^[A-F0-9a-f]{66}:[0-9]+$")
            return (routeHintRegex?.matches(in: self, range: NSRange(self.startIndex..., in: self)) ?? []).count > 0
        }
    }
    //uses _ instead of :
    var isV2RouteHint: Bool {
        get {
            // Adjust the number inside the curly braces {18} to match the expected length of digits.
            let v2RouteHintRegex = try? NSRegularExpression(pattern: "^[A-F0-9a-f]{66}_[0-9]{18}$")
            return (v2RouteHintRegex?.matches(in: self, range: NSRange(self.startIndex..., in: self)) ?? []).count > 0
        }
    }
    
    var isV2Pubkey: Bool {
        get {
            let v2PubkeyRegex = try? NSRegularExpression(pattern: "^[A-F0-9a-f]{66}_[A-F0-9a-f]{66}_[0-9]{18}$")
            return (v2PubkeyRegex?.matches(in: self, range: NSRange(self.startIndex..., in: self)) ?? []).count > 0
        }
    }

    
    var isVirtualPubKey : Bool {
        get {
            let completePubkeyRegex = try? NSRegularExpression(pattern: "^[A-F0-9a-f]{66}:[A-F0-9a-f]{66}:[0-9]+$")
            return (completePubkeyRegex?.matches(in: self, range: NSRange(self.startIndex..., in: self)) ?? []).count > 0
        }
    }
    
    var pubkeyComponents : (String, String) {
        get {
            let components = self.components(separatedBy: ":")
            if components.count >= 3 {
                return (components[0], self.replacingOccurrences(of: components[0] + ":", with: ""))
            }
            return (self, "")
        }
    }
    
    var v2PubkeyComponents : (String, String) {
        get {
            let components = self.components(separatedBy: "_")
            if components.count >= 3 {
                return (components[0], self.replacingOccurrences(of: components[0] + "_", with: ""))
            }
            return (self, "")
        }
    }
    
    func isExistingContactPubkey() -> (Bool, UserContact?) {
        if let pubkey = self.stringFirstPubKey?.0 {
            let (pk, _) = (pubkey.isV2Pubkey) ? pubkey.v2PubkeyComponents : pubkey.pubkeyComponents
            if let contact = UserContact.getContactWith(pubkey: pk), !contact.fromGroup {
               return (true, contact)
            }
            if let owner = UserContact.getOwner(), owner.publicKey == pk {
                return (true, owner)
            }
        }
        return (false, nil)
   }
    
    var isV2InviteCode : Bool{
        get {
            return self.localizedStandardContains("action=i&d")
        }
    }
    
    var isInviteCode : Bool {
        get {
            let regex = try? NSRegularExpression(pattern: "^[A-F0-9a-f]{40}$")
            return ((regex?.matches(in: self, range: NSRange(self.startIndex..., in: self)) ?? []).count > 0) || isV2InviteCode
        }
    }
    
    var isLNDInvoice : Bool {
        get {
            let prDecoder = PaymentRequestDecoder()
            prDecoder.decodePaymentRequest(paymentRequest: self)
            return prDecoder.isPaymentRequest()
        }
    }
    
    var amountWithoutSpaces: String {
        return self.replacingOccurrences(of: " ", with: "")
    }
    
    var base64Decoded : String? {
        if let decodedData = Data(base64Encoded: self) {
            if let decodedString = String(data: decodedData, encoding: .utf8) {
                return decodedString
            }
        }
        return nil
    }
    
    var hexEncoded : String {
        let data = Data(self.utf8)
        let hexString = data.map{ String(format:"%02x", $0) }.joined()
        return hexString
    }
    
    var base64Encoded : String? {
        return Data(self.utf8).base64EncodedString()
    }
    
    var dataFromString : Data? {
        return Data(base64Encoded: self.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/"))
    }
    
    var lowerClean : String {
        return self.trim().lowercased()
    }
    
    var callServer : String {
        if let range = self.lowerClean.range(of: "sphinx.call.") {
            let room = self.lowerClean[..<range.lowerBound]
            return String(room)
        }
        return self.lowerClean
    }
    
    var callRoom : String {
        if let range = self.lowerClean.range(of: "sphinx.call.") {
            let endIndex = self.index(of: "#") ?? self.endIndex
            let roomWithParams = String(self.lowerClean[range.lowerBound..<endIndex])
            let queryEndIndex = roomWithParams.index(of: "?") ?? roomWithParams.endIndex
            let room = roomWithParams.lowerClean[roomWithParams.startIndex..<queryEndIndex]
            return String(room)
        }
        return self.lowerClean
    }
    
    var isCallLink: Bool {
        get {
            return self.lowerClean.starts(with: "http") && self.lowerClean.contains(TransactionMessage.kCallRoomName)
        }
    }
    
    var isGiphy: Bool {
        get {
            if self.starts(with: GiphyHelper.kPrefix) {
                if let _ = self.replacingOccurrences(of: GiphyHelper.kPrefix, with: "").base64Decoded {
                    return true
                }
            }
            return false
        }
    }
    
    var isPodcastComment: Bool {
        get {
            return self.starts(with: PodcastFeed.kClipPrefix)
        }
    }
    
    var isPodcastBoost: Bool {
        get {
            return self.starts(with: PodcastFeed.kBoostPrefix)
        }
    }
    
    var isYouTubeRSSFeed: Bool {
        contains("www.youtube.com")
    }
    
    var podcastId: Int {
        get {
            let components = self.components(separatedBy: ":")
            if components.count > 1 {
                let value = components[1]
                
                if let id = Int(value) {
                    return id
                }
            }
            return -1
        }
    }
    
    var tribeUUIDAndHost: (String?, String?) {
        get {
            let components = self.components(separatedBy: ":")
            if components.count > 1 {
                let uuid = components[1]
                let host = (components.count > 2) ? components[2] : nil
                
                return (uuid, host)
            }
            return (nil, nil)
        }
    }
    
    var abbreviatedLink : String {
        if self.length > 30 {
            let first25 = String(self.prefix(20))
            let last5 = String(self.suffix(5))
            
            return "\(first25)...\(last5)"
        }
        return self
    }
    
    var withAbbreviatedLinks : String {
        var messageWithAbbreviatedLinks = ""
        for link in self.stringLinks {
            let linkString = (self as NSString).substring(with: link.range) as String
            messageWithAbbreviatedLinks = self.replacingOccurrences(of: linkString, with: linkString.abbreviatedLink)
        }
        return messageWithAbbreviatedLinks
    }
    
    func getNameStyleString() -> String {
        if self == "" {
            return "Unknown"
        }
        
        let names = self.split(separator: " ")
        var namesString = ""
        var namesCount = 0
        
        for name in names {
            if namesCount == 0 {
                namesString = "\(name)"
                namesCount += 1
            } else if namesCount == 1 {
                namesString = "\(namesString)\n\(name)"
                namesCount += 1
            } else {
                namesString = "\(namesString) \(name)"
            }
        }
        
        return namesString.uppercased()
    }
    
    func getFirstNameStyleString() -> String {
        let names = self.split(separator: " ")
        if names.count > 0 {
            return String(names[0])
        }
        
        return "Unknown"
    }
    
    func withDefaultValue(_ defaultValue:String) -> String {
        if self.isEmpty {
            return defaultValue
        }
        return self
    }
    
    func mimeTypeForPath() -> String {
        let url = NSURL(fileURLWithPath: self)
        let pathExtension = url.pathExtension

        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
    
    func withURLParam(key: String, value: String) -> String {
        if self.contains("?") {
            return "\(self)&\(key)=\(value)"
        } else {
            return "\(self)?\(key)=\(value)"
        }
    }
    
    func getExtensionFromMimeType() -> String {
        let components = self.components(separatedBy: "/")
        if components.count > 1 {
            return String(components[1])
        }
        return "txt"
    }
    
    public static func getAttributedText(string: String, boldStrings: [String], font: UIFont, boldFont: UIFont, color: UIColor = UIColor.white) -> NSAttributedString {
        let normalFont = font
        let stringRange = (string as NSString).range(of: string)
        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttribute(.foregroundColor, value: color, range: stringRange)
        attributedString.addAttribute(.font, value: normalFont, range: stringRange)
        
        for boldString in boldStrings {
            let boldRange = (string as NSString).range(of: boldString)
            attributedString.addAttribute(.font, value: boldFont, range: boldRange)
        }
        
        return attributedString
    }
    
    public static func getAttributedText(string: String, attributedStrings: [String], font: UIFont, styleFont: UIFont, color: UIColor = UIColor.white) -> NSAttributedString {
        let normalFont = font
        let stringRange = (string as NSString).range(of: string)
        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttribute(.foregroundColor, value: color, range: stringRange)
        attributedString.addAttribute(.font, value: normalFont, range: stringRange)
        
        for string in attributedStrings {
            let range = (string as NSString).range(of: string)
            attributedString.addAttribute(.font, value: styleFont, range: range)
        }
        
        return attributedString
    }
    
    func getInitialsFromName() -> String{
        let names = self.trim().components(separatedBy: " ")
        if names.count > 1 {
            if names[0].length > 0 && names[1].length > 0 {
                return String(names[0].trim().charAt(index: 0)) + String(names[1].trim().charAt(index: 0)).uppercased()
            }
        }
        if names.count > 0 {
            if names[0].length > 0 {
                return String(names[0].trim().charAt(index: 0)).uppercased()
            }
        }
        return ""
    }
    
    func removeDuplicatedProtocol() -> String {
        let urlWithoutHTTPProtocol = self.replacingOccurrences(of: "http://", with: "")
        if urlWithoutHTTPProtocol.contains("http") {
            return urlWithoutHTTPProtocol
        }
        let urlWithoutHTTPSProtocol = self.replacingOccurrences(of: "https://", with: "")
        if urlWithoutHTTPSProtocol.contains("http") {
            return urlWithoutHTTPSProtocol
        }
        return self
    }
    
    var isNotSupportedMessage: Bool { self.contains("message.not.supported".localized) }

    var isSingleEmoji: Bool { count == 1 && containsEmoji }

    var containsEmoji: Bool { contains { $0.isEmoji } }

    var containsOnlyEmoji: Bool { !isEmpty && !contains { !$0.isEmoji } }

    var emojiString: String { emojis.map { String($0) }.reduce("", +) }

    var emojis: [Character] { filter { $0.isEmoji } }

    var emojiScalars: [UnicodeScalar] { filter { $0.isEmoji }.flatMap { $0.unicodeScalars } }
    
    var btcAddresWithoutPrefix: String {
        return self.replacingOccurrences(of: "bitcoin:", with: "")
    }
    
    var isValidBitcoinAddress: Bool {
        let fullAddress = self.components(separatedBy: ":")
        var address = self

        if fullAddress.count == 2, fullAddress[0] == "bitcoin" {
            address = fullAddress[1]
        }

        let pattern = "\\b(bc(0([ac-hj-np-z02-9]{39}|[ac-hj-np-z02-9]{59})|1[ac-hj-np-z02-9]{8,87})|[13][a-km-zA-HJ-NP-Z1-9]{25,35})\\b"

        let bitCoinIDTest = NSPredicate(format:"SELF MATCHES %@", pattern)
        let result = bitCoinIDTest.evaluate(with: address)

        return result
    }
    
    func getLinkComponentWith(key: String) -> String? {
        let components = self.components(separatedBy: "&")
        
        if components.count > 0 {
            for component in components {
                let elements = component.components(separatedBy: "=")
                if elements.count > 1 {
                    let componentKey = elements[0]
                    let value = component.replacingOccurrences(of: "\(componentKey)=", with: "")
                    
                    switch(componentKey) {
                    case key:
                        return value
                    default:
                        break
                    }
                }
            }
        }
        
        return nil
    }
    
    func getHostAndPort(
        defaultPort: UInt16
    ) -> (String, UInt16, Bool) {
        
        var port: UInt16 = defaultPort
        
        if let portIndex = self.lastIndex(of: ":") {
            let portString = String(self[portIndex...]).replacingOccurrences(of: ":", with: "")
            
            if let portInt = UInt16(portString) {
                port = portInt
            }
        }
        
        let actualHost = self.replacingOccurrences(of: ":\(port)", with: "")
        let ssl = port == 8883
        
        return (actualHost, port, ssl)
    }
}

extension Character {
    var isSimpleEmoji: Bool {
        guard let firstScalar = unicodeScalars.first else { return false }
        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
    }

    var isCombinedIntoEmoji: Bool { unicodeScalars.count > 1 && unicodeScalars.first?.properties.isEmoji ?? false }
    var isEmoji: Bool { isSimpleEmoji || isCombinedIntoEmoji }
}

extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        var indices: [Index] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                indices.append(range.lowerBound)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return indices
    }
    
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                result.append(range)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
    
    var attributedStringFromHTML: NSAttributedString? {
        guard let data = data(using: .utf8) else {
            return nil
        }
        
        do {
            return try NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding:String.Encoding.utf8.rawValue,
                ],
                documentAttributes: nil
            )
        } catch {
            return nil
        }
    }
}


extension String {
    
    var attributedStringFromHTML: NSAttributedString? {
        guard let data = data(using: .utf8) else {
            return nil
        }
        
        do {
            return try NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding:String.Encoding.utf8.rawValue,
                ],
                documentAttributes: nil
            )
        } catch {
            return nil
        }
    }
    
    var nonHtmlRawString: String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
    
    func removingPunctuation() -> String {
        var filteredString = self
        while true {
            if let forbiddenCharRange = filteredString.rangeOfCharacter(from: CharacterSet.punctuationCharacters)  {
                filteredString.removeSubrange(forbiddenCharRange)
            } else {
                break
            }
        }
        return filteredString
    }
    
    var personHost: String? {
        let elements = self.split(separator: "/")
        if let last = elements.last {
            return self.replacingOccurrences(of: "/\(String(last))", with: "")
        }
        return nil
    }
    
    var personUUID: String? {
        let elements = self.split(separator: "/")
        if let last = elements.last {
            return String(last)
        }
        return nil
    }
    
    var tribeMemberProfileValue : String {
        if self.trim().isEmpty {
            return "-"
        }
        return self
    }
    
    var isEmptyPinnedMessage : Bool {
        return self.isEmpty || self == "_"
    }
    
    var isNotEmpty: Bool {
        return !isEmpty
    }
    
    func isNotEmptyField(with placeHolder: String) -> Bool {
        return !isEmpty && self != placeHolder
    }
}
