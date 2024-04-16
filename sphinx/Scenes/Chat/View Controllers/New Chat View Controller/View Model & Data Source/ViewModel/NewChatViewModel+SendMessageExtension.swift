//
//  NewChatViewModel+SendMessageExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewChatViewModel {
    func shouldSendGiphyMessage(
        text: String,
        type: Int,
        data: Data,
        completion: @escaping (Bool) -> ()
    ) {
        chatDataSource?.setMediaDataForMessageWith(
            messageId: TransactionMessage.getProvisionalMessageId(),
            mediaData: MessageTableCellState.MediaData(
                image: data.gifImageFromData(),
                failed: false
            )
        )
        
        shouldSendMessage(
            text: text,
            type: type,
            completion: completion
        )
    }
    
    func shouldSendMessage(
        text: String,
        type: Int,
        completion: @escaping (Bool) -> ()
    ) {
        var messageText = text
        
        if let podcastComment = podcastComment {
            messageText = podcastComment.getJsonString(withComment: text) ?? text
        }
        
        let (botAmount, wrongAmount) = isWrongBotCommandAmount(text: messageText)
        
        if wrongAmount {
            completion(false)
            return
        }
        guard let chat = chat else{
            completion(false)
            return
        }
        
        let tuuid = threadUUID ?? replyingTo?.threadUUID ?? replyingTo?.uuid
        let validMessage = SphinxOnionManager.sharedInstance.sendMessage(to: contact, content: text, chat: chat,msgType: UInt8(type), threadUUID: tuuid, replyUUID: replyingTo?.uuid)
        completion(validMessage != nil)
        
    }
    
    func createProvisionalAndSend(
        messageText: String,
        type: Int,
        botAmount: Int,
        completion: @escaping (Bool) -> ()
    ) -> TransactionMessage? {
        
        let provisionalMessage = insertProvisionalMessage(
            text: messageText,
            type: type,
            chat: chat
        )
        
        sendMessage(
            provisionalMessage: provisionalMessage,
            text: messageText,
            botAmount: botAmount,
            completion: completion
        )
        
        return provisionalMessage
    }

    func insertProvisionalMessage(
        text: String,
        type: Int,
        chat: Chat?
    ) -> TransactionMessage? {
        
        let message = TransactionMessage.createProvisionalMessage(
            messageContent: text,
            type: type,
            date: Date(),
            chat: chat,
            replyUUID: replyingTo?.uuid,
            threadUUID: threadUUID ?? replyingTo?.threadUUID ?? replyingTo?.uuid
        )
        
        if chat == nil {
            ///Sending first message. Chat does not exist yet
            updateSnapshotWith(message: message)
        }
        
        return message
    }
    
    func updateSnapshotWith(
        message: TransactionMessage?
    ) {
        guard let message = message else {
            return
        }
        
        chatDataSource?.updateSnapshotWith(message: message)
    }
    
    func sendMessage(
        provisionalMessage: TransactionMessage?,
        text: String,
        isResend: Bool = false,
        botAmount: Int = 0,
        completion: @escaping (Bool) -> ()
    ) {
        let messageType = TransactionMessage.TransactionMessageType(fromRawValue: provisionalMessage?.type ?? 0)
        let som = SphinxOnionManager.sharedInstance
        guard let chat = chat else{
            completion(false)
            return
        }
        
        let error = SphinxOnionManager.sharedInstance.sendMessage(to: contact!, content: text, chat: chat,threadUUID: threadUUID, replyUUID: replyingTo?.uuid)
        
        guard let params = TransactionMessage.getMessageParams(
            contact: contact,
            chat: chat,
            type: messageType,
            text: text,
            botAmount: botAmount,
            replyingMessage: replyingTo,
            threadUUID: provisionalMessage?.threadUUID
        ) else {
            completion(false)
            return
        }
        
        sendMessage(
            provisionalMessage: isResend ? nil : provisionalMessage,
            params: params,
            completion: completion
        )
    }

    func sendMessage(
        provisionalMessage: TransactionMessage?,
        params: [String: AnyObject],
        completion: @escaping (Bool) -> ()
    ) {
        askForNotificationPermissions()
        
        API.sharedInstance.sendMessage(params: params, callback: { m in
            
            let provisionalMessageId = provisionalMessage?.id
            
            if let provisionalMessage = provisionalMessage {
                self.chatDataSource?.replaceMediaDataForMessageWith(
                    provisionalMessageId: provisionalMessage.id,
                    toMessageWith: m["id"].intValue
                )
            }
            
            if let message = TransactionMessage.insertMessage(m: m, existingMessage: provisionalMessage).0 {
                message.managedObjectContext?.saveContext()
                message.setPaymentInvoiceAsPaid()
                
                self.insertSentMessage(
                    message: message,
                    completion: completion
                )
                
                self.deleteMessageWith(id: provisionalMessageId)
                
                ActionsManager.sharedInstance.trackMessageSent(message: message)
            }
            
            if let podcastComment = self.podcastComment {
                ActionsManager.sharedInstance.trackClipComment(podcastComment: podcastComment)
            }
            
        }, errorCallback: {
             if let provisionalMessage = provisionalMessage {
                 
                provisionalMessage.status = TransactionMessage.TransactionMessageStatus.failed.rawValue
                 
                self.insertSentMessage(
                    message: provisionalMessage,
                    completion: completion
                )
             }
        })
    }
    
    func deleteMessageWith(
        id: Int?
    ) {
        if let id = id {
            TransactionMessage.deleteMessageWith(id: id)
        }
    }

    func insertSentMessage(
        message: TransactionMessage,
        completion: @escaping (Bool) -> ()
    ) {
        ChatTrackingHandler.shared.deleteOngoingMessage(with: chat?.id)

        joinIfCallMessage(message: message)
        showBoostErrorAlert(message: message)
        
        resetReply()
        
        completion(true)
    }

    func joinIfCallMessage(
        message: TransactionMessage
    ) {
        if message.isCallMessageType() {
            if let callLink = message.messageContent {
                VideoCallManager.sharedInstance.startVideoCall(link: callLink)
            }
        }
    }
    
    func showBoostErrorAlert(
        message: TransactionMessage
    ) {
        if message.isMessageBoost() && message.failed() {
            AlertHelper.showAlert(title: "boost.error.title".localized, message: message.errorMessage ?? "generic.error.message".localized)
        }
    }

    func isWrongBotCommandAmount(
        text: String
    ) -> (Int, Bool) {
        let (botAmount, failureMessage) = GroupsManager.sharedInstance.calculateBotPrice(chat: chat, text: text)
        
        if let failureMessage = failureMessage {
            AlertHelper.showAlert(title: "generic.error.title".localized, message: failureMessage)
            return (botAmount, true)
        }
        
        return (botAmount, false)
    }
    
    func shouldSendTribePayment(
        amount: Int,
        message: String,
        messageUUID: String,
        callback: (() -> ())?
    ) {
        guard let params = TransactionMessage.getTribePaymentParams(
            chat: chat,
            messageUUID: messageUUID,
            amount: amount,
            text: message
        ) else {
            callback?()
            return
        }
        
        sendMessage(provisionalMessage: nil, params: params, completion: { _ in
            callback?()
        })
    }
    
    func createCallMessage(sender: UIButton) {
        VideoCallHelper.createCallMessage(button: sender, callback: { link in
            self.sendCallMessage(link: link)
        })
    }
    
    func sendCallMessage(link: String) {
        let type = (self.chat?.isGroup() == false) ?
            TransactionMessage.TransactionMessageType.call.rawValue :
            TransactionMessage.TransactionMessageType.message.rawValue
        
        var messageText = link
        
        if type == TransactionMessage.TransactionMessageType.call.rawValue {
            
            let voipRequestMessage = VoIPRequestMessage()
            voipRequestMessage.recurring = false
            voipRequestMessage.link = link
            voipRequestMessage.cron = ""
            
            messageText = voipRequestMessage.getCallLinkMessage() ?? link
        }
        
        self.shouldSendMessage(
            text: messageText,
            type: type,
            completion: { _ in }
        )
    }
}
