//
//  ChatTrackingHandler.swift
//  sphinx
//
//  Created by Tomas Timinskas on 25/01/2024.
//  Copyright © 2024 sphinx. All rights reserved.
//

import Foundation

class ChatTrackingHandler {
    
    class var shared : ChatTrackingHandler {
        struct Static {
            static let instance = ChatTrackingHandler()
        }
        return Static.instance
    }
    
    var replyableMessages: [Int: Int] = [:]
    var ongoingMessages : [Int: String] = [:]
    
    func deleteReplyableMessage(with chatId: Int?) {
        guard let chatId = chatId else { return }
        
        replyableMessages.removeValue(forKey: chatId)
    }
    
    func saveReplyableMessage(
        with messageId: Int,
        chatId: Int?
    ) {
        guard let chatId = chatId else { return }
        
        replyableMessages[chatId] = messageId
    }
    
    func getReplyableMessageFor(chatId: Int?) -> TransactionMessage? {
        guard let chatId = chatId else { return nil }
        
        if let messageId = replyableMessages[chatId], let message = TransactionMessage.getMessageWith(id: messageId) {
            return message
        }
        
        return nil
    }
    
    func deleteOngoingMessage(with chatId: Int?) {
        guard let chatId = chatId else { return }
        
        ongoingMessages.removeValue(forKey: chatId)
    }
    
    func saveOngoingMessage(
        with message: String,
        chatId: Int?
    ) {
        guard let chatId = chatId else { return }
        
        ongoingMessages[chatId] = message
    }
    
    func getOngoingMessageFor(chatId: Int?) -> String? {
        guard let chatId = chatId else { return nil }
        
        if let message = ongoingMessages[chatId] {
            return message
        }
        
        return nil
    }
}
