//
//  ChatChatListExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import CoreData

extension Chat: ChatListCommonObject {
    
    public func getObjectId() -> Int {
        return self.id
    }
    
    public func getOrderDate() -> Date? {
        var date = createdAt
        
        if let lastMessage = lastMessage {
            date = lastMessage.date
        }
        
        if let webAppLastDate = webAppLastDate, webAppLastDate > date {
            date = webAppLastDate
        }
        
        return date
    }
    
    func getConversationContact() -> UserContact? {
        if conversationContact == nil {
            conversationContact = getContact()
        }
        return conversationContact
    }
    
    public func getName() -> String {
        if isConversation() {
            return getConversationContact()?.getName() ?? ""
        }
        return name ?? "unknown.group".localized
    }
    
    public func isPending() -> Bool {
        return false
    }
    
    public func isConfirmed() -> Bool {
        return true
    }
    
    public func hasEncryptionKey() -> Bool {
        return true
    }
    
    public func subscribedToContact() -> Bool {
        return false
    }
    
    public func shouldShowSingleImage() -> Bool {
        if isPublicGroup() || isConversation() {
            return true
        }
        if let url = photoUrl, url != "" {
            return true
        }
        return getChatContacts().count == 1
    }
    
    public func getChatContacts() -> [UserContact] {
        return self.getContacts(ownerAtEnd: true)
    }
    
    public func getPhotoUrl() -> String? {
        if isConversation() {
            return getConversationContact()?.getPhotoUrl() ?? ""
        }
        return photoUrl
    }
    
    public func setImage(image: UIImage)  {
        self.image = image
    }
    
    public func getImage() -> UIImage? {
        return image
    }
    
    public func getConversation() -> Chat? {
        return self
    }
    
    public func isGroupObject() -> Bool {
        return true
    }
    
    public func getColor() -> UIColor {
        if let contact = self.getContact() {
            return contact.getColor()
        }
        let key = "chat-\(self.id)-color"
        return UIColor.getColorFor(key: key)
    }
    
    public func deleteColor() {
        let key = "chat-\(self.id)-color"
        UIColor.removeColorFor(key: key)
    }
}
