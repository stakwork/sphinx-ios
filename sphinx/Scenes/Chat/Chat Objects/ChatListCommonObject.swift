//
//  ChatListCommonObject.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

public protocol ChatListCommonObject: class {
    func isPending() -> Bool
    func isConfirmed() -> Bool
    func isGroupObject() -> Bool
    
    func getObjectId() -> Int
    func getOrderDate() -> Date?
    func getName() -> String
    func getChatContacts() -> [UserContact]
    func getPhotoUrl() -> String?
    func getColor() -> UIColor
    func shouldShowSingleImage() -> Bool
    
    func getImage() -> UIImage?
    func setImage(image: UIImage) 
    
    func hasEncryptionKey() -> Bool
    func subscribedToContact() -> Bool
    
    func getConversation() -> Chat?
    
    var lastMessage : TransactionMessage? { get set }
}
