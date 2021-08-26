//
//  UserContactChatListExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import CoreData

extension UserContact : ChatListCommonObject {
    
    public func getObjectId() -> Int {
        return self.id
    }
    
    public func getOrderDate() -> Date? {
        if let lastMessage = lastMessage {
            return lastMessage.date
        }
        return createdAt
    }
    
    public func getName() -> String {
        return getUserName()
    }
    
    func getUserName(forceNickname: Bool = false) -> String {
        if isOwner && !forceNickname {
            return "name.you".localized
        }
        if let nn = nickname, nn != "" {
            return nn
        }
        return "name.unknown".localized
    }
    
    public func getChatContacts() -> [UserContact] {
        return [self]
    }
    
    public func getPhotoUrl() -> String? {
        return avatarUrl
    }
    
    public func getCachedImage() -> UIImage? {
        if let url = getPhotoUrl(), let cachedImage = MediaLoader.getImageFromCachedUrl(url: url) {
            return cachedImage
        }
        return nil
    }
    
    public func setImage(image: UIImage)  {
        self.image = image
    }
    
    public func getImage() -> UIImage? {
        return image
    }
    
    public func shouldShowSingleImage() -> Bool {
        return true
    }
    
    public func isConversation() -> Bool {
        return true
    }
    
    public func isPublicGroup() -> Bool {
        return false
    }
    
    public func getColor() -> UIColor {
        let key = "\(self.id)-color"
        return UIColor.getColorFor(key: key)
    }
    
    public func deleteColor() {
        let key = "\(self.id)-color"
        UIColor.removeColorFor(key: key)
    }
}
