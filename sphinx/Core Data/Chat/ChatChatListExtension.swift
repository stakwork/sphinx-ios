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
    
    public func getObjectId() -> String {
        return "chat-\(self.id)"
    }
    
    public func getOrderDate() -> Date? {
        var date: Date? = nil
        
        if let lastMessage = lastMessage {
            date = lastMessage.date
        }
        
        if let webAppLastDate = webAppLastDate {
            if date == nil {
                date = webAppLastDate
            } else if let savedDate = date, webAppLastDate > savedDate {
                date = webAppLastDate
            }
        }
        
        return date ?? createdAt
    }
    
    func getConversationContact() -> UserContact? {
        if isGroup() {
            return nil
        }
        if conversationContact == nil {
            let contacts = getContacts(includeOwner: false)
            conversationContact = contacts.first
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
    
    public func isMuted() -> Bool {
        return self.notify == NotificationLevel.MuteChat.rawValue
    }
    
    public func isSeen(
        ownerId: Int
    ) -> Bool {
        if self.lastMessage?.isOutgoing(ownerId: ownerId) ?? true {
            return true
        }
        
        if self.lastMessage?.isSeen(ownerId: ownerId) ?? true {
            return true
        }
        
        return self.seen
    }
    
    public func isOnlyMentions() -> Bool {
        return self.notify == NotificationLevel.OnlyMentions.rawValue
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
    
    public func getChat() -> Chat? {
        return self
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
    
    public func getInvite() -> UserInvite? {
        return nil
    }
    
    public func getContactStatus() -> Int? {
        return UserContact.Status.Confirmed.rawValue
    }
    
    public func getInviteStatus() -> Int? {
        return UserInvite.Status.Complete.rawValue
    }
}
