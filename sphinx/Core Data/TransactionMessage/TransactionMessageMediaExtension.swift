//
//  TransactionMessageMediaExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import CoreData
import UIKit

extension TransactionMessage {
    func getMediaType() -> Int? {
        if self.type == TransactionMessage.TransactionMessageType.attachment.rawValue {
            if let mediaType = self.mediaType, mediaType != "" {
                if mediaType.contains("image") {
                    return TransactionMessage.TransactionMessageType.imageAttachment.rawValue
                } else if mediaType.contains("video") {
                    return TransactionMessage.TransactionMessageType.videoAttachment.rawValue
                } else if mediaType.contains("audio") {
                    return TransactionMessage.TransactionMessageType.audioAttachment.rawValue
                } else if mediaType.contains("sphinx/text") {
                    return TransactionMessage.TransactionMessageType.textAttachment.rawValue
                } else if mediaType.contains("pdf") {
                    return TransactionMessage.TransactionMessageType.pdfAttachment.rawValue
                }
                return TransactionMessage.TransactionMessageType.fileAttachment.rawValue
            } else {
                return TransactionMessage.TransactionMessageType.imageAttachment.rawValue
            }
        }
        return nil
    }
    
    func getAttachmentsType() -> AttachmentsManager.AttachmentType? {
        if self.type == TransactionMessage.TransactionMessageType.attachment.rawValue {
            if let mediaType = self.mediaType, mediaType != "" {
                if mediaType.contains("image/jpg") {
                    return .Photo
                } else if mediaType.contains("image/gif") {
                    return .Gif
                } else if mediaType.contains("video") {
                    return .Video
                } else if mediaType.contains("audio") {
                    return .Audio
                } else if mediaType.contains("sphinx/text") {
                    return .Text
                } else if mediaType.contains("pdf") {
                    return .PDF
                }
                return .GenericFile
            } else {
                return .Photo
            }
        }
        return nil
    }
    
    func getFileName() -> String {
        if let fileName = self.mediaFileName, !fileName.isEmpty {
            return fileName
        }
        if let attachmentType = self.getAttachmentsType() {
            let fileAndMime = AttachmentObject.getFileAndMime(type: attachmentType, fileName: self.mediaFileName)
            return fileAndMime.0
        }
        return "file.txt"
    }
    
    func isPaidAttachment() -> Bool {
        if let price = getAttachmentPrice(), price > 0 {
            return true
        }
        return false
    }
    
    func isPaymentWithImage() -> Bool {
        return self.type == TransactionMessage.TransactionMessageType.directPayment.rawValue && self.mediaToken != nil
    }
    
    func isMediaExpired() -> Bool {
        if let expirationDate = getMediaExpirationDate() {
            let expired = Date().timeIntervalSince1970 > expirationDate.timeIntervalSince1970
            return expired
        }
        return false
    }
    
    func getMediaUrlFromMediaToken() -> URL? {
        if let mediaToken = mediaToken, let host = getHost() {
            let mediaUrl = "https://\(host)/file/\(mediaToken)".trim()
                        
            if let nsUrl = URL(string: mediaUrl), mediaUrl != "" {
                return nsUrl
            }
        }
        return nil
    }
    
    func getTemplateURL() -> URL? {
        let muid = getMUID()
        if let host = getHost(), let url = URL(string: "https://\(host)/template/\(muid)"), !muid.isEmpty {
            return url
        }
        return nil
    }
    
    func getGiphyUrl() -> URL? {
        if let messageContent = messageContent,
            let urlString = GiphyHelper.getUrlFrom(message: messageContent, mobile: false) {
            return URL(string: urlString)
        }
        return nil
    }
    
    func getHost() -> String? {
        if let host = getItemAtIndex(index: 0)?.base64Decoded {
            return host
        }
        return nil
    }
    
    func getMUID() -> String {
        if let muid = self.muid, muid != "" {
            return muid
        }
        
        if let mmuid = getItemAtIndex(index: 1) {
            return mmuid
        }
        return ""
    }
    
    func getMediaExpirationDate() -> Date? {
        if let expiration = getItemAtIndex(index: 3) {
            let miliseconds = (String(expiration).dataFromString)!.uint32
            return Date(timeIntervalSince1970: Double(miliseconds))
        }
        return nil
    }
    
    func getImageRatio() -> Double? {
        if let attributeValue = getMediaAttribute(attribute: "dim") {
            let dimentions = attributeValue.split(separator: "x")
            
            if dimentions.count > 1 {
                if let width = Double(String(dimentions[0])), let height = Double(String(dimentions[1])) {
                    return height / width
                }
            }
        }
        return nil
    }
    
    func getAttachmentPrice() -> Int? {
        if let attributeValue = getMediaAttribute(attribute: "amt") {
            if let price = Int(attributeValue) {
                return price
            }
        }
        return nil
    }
    
    func getItemAtIndex(index: Int) -> String? {
        if let mediaToken = self.mediaToken {
            if let item = TransactionMessage.getItemAtIndex(index: index, on: mediaToken) {
                return item
            }
        }
        return nil
    }
    
    func getMediaAttribute(attribute: String) -> String? {
        if let metaDataItems = getItemAtIndex(index: 4)?.base64Decoded?.split(separator: "&") {
            for mdItem in metaDataItems {
                if String(mdItem).contains("\(attribute)=") {
                    let attributeValue = String(mdItem).replacingOccurrences(of: "\(attribute)=", with: "")
                    return String(attributeValue)
                }
            }
        }
        return nil
    }

    func getPurchaseItemWith(type: Int) -> TransactionMessage? {
        guard let muid = self.muid else {
            return nil
        }

        let predicate = NSPredicate(
            format: "(muid == %@ || originalMuid == %@) AND type == %d",
            muid,
            muid,
            type
        )
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        
        let message: TransactionMessage? = CoreDataManager.sharedManager.getObjectOfTypeWith(
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            entityName: "TransactionMessage"
        )

        return message
    }

    func getPurchaseAcceptItem() -> TransactionMessage? {
        return getPurchaseItemWith(type: TransactionMessageType.purchaseAccept.rawValue)
    }
    
    func saveFileName(_ fileName: String?) {
        guard let fileName = fileName, !fileName.isEmpty else {
            return
        }
        self.mediaFileName = fileName
    }
    
    func saveFileSize(_ size: Int?) {
        guard let size = size, size > 0 else {
            return
        }
        self.mediaFileSize = size
    }
    
    func saveFileInfo(filename: String?, size: Int?) {
        if let filename = filename, !filename.isEmpty {
            self.mediaFileName = filename
        }
        
        if let size = size, size > 0 {
            self.mediaFileSize = size
        }
    }
    
    //Static methods
    static func getMUIDFrom(mediaToken: String?) -> String? {
        if let mediaToken = mediaToken, let mmuid = getItemAtIndex(index: 1, on: mediaToken) {
            return mmuid
        }
        return nil
    }
    
    static func getItemAtIndex(index: Int, on mediaToken: String) -> String? {
        let items = mediaToken.split(separator: ".", omittingEmptySubsequences: false)
        if items.count > index {
            let item = String(items[index])
            if item.trim() != "" {
                return item
            }
        }
        return nil
    }
}
