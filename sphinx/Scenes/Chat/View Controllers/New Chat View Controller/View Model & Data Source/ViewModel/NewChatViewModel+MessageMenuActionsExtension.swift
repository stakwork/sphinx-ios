//
//  NewChatViewModel+MessageMenuActionsExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 18/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension NewChatViewModel {
    func shouldBoostMessage(message: TransactionMessage) {
        guard let params = TransactionMessage.getBoostMessageParams(
            contact: contact,
            chat: chat,
            replyingMessage: message
        ),
        let chat = chat else {
            return
        }
        
        SphinxOnionManager.sharedInstance.sendBoostReply(params: params, chat: chat)
    }
    
    func shouldResendMessage(message: TransactionMessage) {
        sendMessage(
            provisionalMessage: message,
            text: message.messageContent ?? "",
            isResend: true,
            completion: { _ in }
        )
    }
}

extension NewChatViewModel {
    func shouldFlagMessage(message: TransactionMessage) {
        DelayPerformedHelper.performAfterDelay(seconds: 0.1, completion: {
            AlertHelper.showTwoOptionsAlert(
                title: "alert-confirm.flag-message-title".localized,
                message: "alert-confirm.flag-message-message".localized,
                confirm: {
                    self.flagMessage(message)
                })
        })
    }
    
    private func flagMessage(_ message: TransactionMessage) {
        if message.flag() {
            sendFlagMessageFor(message)
            return
        }
        AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
    }
    
    func sendFlagMessageFor(_ message: TransactionMessage) {
        DispatchQueue.global().async {
            let supportContact = SignupHelper.getSupportContact()
            
            if let pubkey = supportContact["pubkey"].string {
                
                if let contact = UserContact.getContactWith(pubkey: pubkey) {
                    
                    let messageSender = message.getMessageSender()
                    
                    var flagMessageContent = """
                    Message Flagged
                    - Message: \(message.uuid ?? "Empty Message UUID")
                    - Sender: \(messageSender?.publicKey ?? "Empty Sender")
                    """
                    
                    if let chat = message.chat, chat.isPublicGroup() {
                        flagMessageContent = "\(flagMessageContent)\n- Tribe: \(chat.uuid ?? "Empty Tribe UUID")"
                    }
                    
                    self.sendFlagMessage(
                        contact: contact,
                        text: flagMessageContent
                    )
                    return
                }
            }
        }
    }
    
    func sendFlagMessage(
        contact: UserContact,
        text: String
    ) {
        guard let params = TransactionMessage.getMessageParams(
                contact: contact,
                type: TransactionMessage.TransactionMessageType.message,
                text: text
        ) else {
            return
        }
        
        API.sharedInstance.sendMessage(params: params, callback: { _ in }, errorCallback: {})
    }
}

extension NewChatViewModel {
    func shouldDeleteMessage(message: TransactionMessage) {
        DelayPerformedHelper.performAfterDelay(seconds: 0.1, completion: {
            AlertHelper.showTwoOptionsAlert(
                title: "alert-confirm.delete-message-title".localized,
                message: "alert-confirm.delete-message-message".localized,
                confirm: {
                    self.deleteMessage(message)
                })
        })
    }
    
    private func deleteMessage(_ message: TransactionMessage) {
        if message.id < 0 {
            CoreDataManager.sharedManager.deleteObject(object: message)
            return
        }
        
        SphinxOnionManager.sharedInstance.sendDeleteRequest(message: message)
    }
}
