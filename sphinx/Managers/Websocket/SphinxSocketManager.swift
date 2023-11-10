//
//  SphinxSocketManager.swift
//  sphinx
//
//  Created by Tomas Timinskas on 11/10/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import SwiftyJSON

@objc protocol SocketManagerDelegate: class {
    @objc optional func didUpdateChatFromMessage(_ chat: Chat)
    @objc optional func togglePaidContainer(invoice: String)
}

class SphinxSocketManager {
    
    class var sharedInstance : SphinxSocketManager {
        struct Static {
            static let instance = SphinxSocketManager()
        }
        return Static.instance
    }
    
    weak var delegate: SocketManagerDelegate?
    var manager: SocketManager? = nil
    var socket: SocketIOClient? = nil
    var preventReconnection = false
    
    var newMessageBubbleHelper = NewMessageBubbleHelper()
    let onionConnector = SphinxOnionConnector.sharedInstance
    
    var confirmationIds: [Int] = []
    
    func setDelegate(delegate: SocketManagerDelegate?) {
        self.delegate = delegate
    }
    
    func resetSocket() {
        disconnectWebsocket()
        socket = nil
    }
    
    func reconnectSocketToNewIP() {
        resetSocket()
        createAndConnectSocket()
    }
    
    func reconnectSocketOnTor() {
        if isConnected() {
            return
        }
        resetSocket()
        createAndConnectSocket()
    }
    
    func createAndConnectSocket() {
        let (urlString, url) = getSocketUrl()
        if onionConnector.usingTor() && !onionConnector.isReady() {
            return
        }
    
        if socket == nil {
            if let urlString = urlString, let url = url {
                let secure = urlString.starts(with: "wss")
                var socketConfiguration : SocketIOClientConfiguration!
                let headers = UserData.sharedInstance.getAuthenticationHeader()
                
                if onionConnector.usingTor() {
                    socketConfiguration = [.compress, .forcePolling(true), .secure(secure), .extraHeaders(headers)]
                } else {
                    socketConfiguration = [.compress, .secure(secure), .extraHeaders(headers)]
                }
                
                manager = SocketManager(socketURL: url, config: socketConfiguration)
                socket = manager?.defaultSocket
            }

            socket?.on(clientEvent: .connect) {data, ack in
                self.socketDidConnect()
            }

            socket?.on(clientEvent: .disconnect) {data, ack in
                self.socketDidDisconnect()
            }

            socket?.on("message") { dataArray, ack in
                for data in dataArray {
                    if let string = data as? String {
                       self.insertData(dataString: string)
                    }
                }
            }
        }
        
        socket?.connect()
    }
    
    func getSocketUrl() -> (String?, URL?) {
        let ip = UserData.sharedInstance.getNodeIP()

        if ip == "" {
            return (nil, nil)
        }

        let urlString = API.getWebsocketUrl(route: "\(ip)")
        return (urlString, URL(string: urlString))
    }
    
    func isConnected() -> Bool {
        return (socket?.status ?? .notConnected) == .connected
    }
    
    func isConnecting() -> Bool {
        return (socket?.status ?? .notConnected) == .connecting
    }
    
    func connectWebsocket(forceConnect: Bool = false) {
        let connected = isConnected()
        let connecting = isConnecting()
        let connectedToInternet = ConnectivityHelper.isConnectedToInternet
        
        if forceConnect || (!connected && !connecting && connectedToInternet) {
            createAndConnectSocket()
        }
    }
    
    func disconnectWebsocket() {
        preventReconnection = true
        socket?.disconnect()
    }
    
    func socketDidDisconnect() {
        postConnectionStatusChange()
        
        if preventReconnection {
            preventReconnection = false
            return
        }
        createAndConnectSocket()
    }
    
    func socketDidConnect() {
        postConnectionStatusChange()
        
        preventReconnection = false
    }
    
    func postConnectionStatusChange() {
        NotificationCenter.default.post(name: .onConnectionStatusChanged, object: nil)
    }
}

extension SphinxSocketManager {
    
    func insertData(dataString: String) {
        if let dataFromString = dataString.data(using: .utf8, allowLossyConversion: false) {
            var json : JSON!
            do {
                json = try JSON(data: dataFromString)
            } catch {
                return
            }
            
            if let type = json["type"].string {
                let response = json["response"]
                
                switch(type) {
                case "contact":
                    didReceiveContact(contactJson: response)
                case "invite":
                    didReceiveInvite(inviteJson: response)
                case "group_create":
                    didReceiveGroup(groupJson: response)
                case "group_leave":
                    didLeaveGroup(type: type, json: response)
                case "group_join":
                    didJoinGroup(type: type, json: response)
                case "group_kick", "tribe_delete":
                    tribeDeletedOrkickedFromGroup(type: type, json: response)
                case "member_request":
                    memberRequest(type: type, json: response)
                case "member_approve", "member_reject":
                    memberRequestResponse(type: type, json: response)
                case "invoice_payment":
                    didReceiveInvoicePayment(json: response)
                case "chat_seen":
                    didSeenChat(chatJson: response)
                case "purchase", "purchase_accept", "purchase_deny":
                    didReceivePurchaseMessage(type: type, messageJson: response)
                case "keysend":
                    keysendReceived(json: response)
                default:
                    didReceiveMessage(type: type, messageJson: response)
                }
            }
        }
    }
    
    func didReceiveInvoicePayment(json: JSON) {
        if let string = json["invoice"].string {
            let prDecoder = PaymentRequestDecoder()
            prDecoder.decodePaymentRequest(paymentRequest: string)
            
            if prDecoder.isPaymentRequest() {
                let amount = prDecoder.getAmount() ?? 0
                
                var message = "\("amount".localized): \(amount)"
                if let memo = prDecoder.getMemo() {
                    message = message + "\n\("memo".localized): \(memo)"
                }
                newMessageBubbleHelper.showMessageView(title: "invoice.paid".localized, text: message)
                togglePaidInvoiceIfNeeded(string: string)
            }
        }
        
        NotificationCenter.default.post(name: .onBalanceDidChange, object: nil)
    }
    
    func togglePaidInvoiceIfNeeded(string: String) {
        delegate?.togglePaidContainer?(invoice: string)
    }
    
    func didReceivePurchaseMessage(type: String, messageJson: JSON) {
        let _ = TransactionMessage.insertMessage(
            m: messageJson,
            existingMessage: TransactionMessage.getMessageWith(id: messageJson["id"].intValue)
        )
        NotificationCenter.default.post(name: .onBalanceDidChange, object: nil)
    }
    
    func didReceiveConfirmationWith(id: Int) {
        confirmationIds.append(id)
        
        if confirmationIds.count > 20 {
            confirmationIds.removeFirst()
        }
    }
    
    func didReceiveMessage(type: String, messageJson: JSON) {
        let isConfirmation = type == "confirmation"
        
        var delay: Double = 0.0
        var existingMessages: TransactionMessage? = nil
        
        if isConfirmation {
            let messageId = messageJson["id"].intValue
            
            if confirmationIds.contains(messageId) {
                return
            }
            
            didReceiveConfirmationWith(id: messageId)
            
            existingMessages = TransactionMessage.getMessageWith(id: messageJson["id"].intValue)
            
            if existingMessages == nil {
                ///Handles case where confirmation of message is received before the send message endpoint returns.
                ///Adding delay to prevent provisional message not being overwritten (duplicated bubble issue)
                delay =  1.5
            }
        }
        
        if let contactJson = messageJson["contact"].dictionary {
            let _ = UserContact.getOrCreateContact(contact: JSON(contactJson))
        }

        DelayPerformedHelper.performAfterDelay(seconds: delay, completion: {
            if let message = TransactionMessage.insertMessage(
                m: messageJson,
                existingMessage: existingMessages ?? TransactionMessage.getMessageWith(id: messageJson["id"].intValue)
            ).0 {
                
                if let chat = message.chat {
                    self.delegate?.didUpdateChatFromMessage?(chat)
                }
                
                self.setSeen(message: message, value: false)
                self.updateBalanceIfNeeded(type: type)
                
                message.setPaymentInvoiceAsPaid()
                
                if !isConfirmation {
                    let _ = self.showBubbleIfNeeded(message: message)
                    SoundsPlayer.playHaptic()
                }
            }
        })
    }
    
    func updateBalanceIfNeeded(type: String) {
        if type == "payment" || type == "direct_payment" || type == "keysend" || type == "boost" {
            NotificationCenter.default.post(name: .onBalanceDidChange, object: nil)
        }
    }
    
    func didSeenChat(chatJson: JSON) {
        let seen = chatJson["seen"].boolValue

        if let id = Chat.getChatId(chat: chatJson), let chatToUpdate = Chat.getChatWith(id: id), seen == chatToUpdate.seen {
            return
        }
        
        if let chat = Chat.insertChat(chat: chatJson) {
            chat.setChatMessagesAsSeen(shouldSync: false, shouldSave: false)
        }
    }
    
    func didReceiveContact(contactJson: JSON) {
        let _ = UserContact.insertContact(contact: contactJson)
    }
    
    func didReceiveGroup(groupJson: JSON) {
        if let contacts = groupJson["new_contacts"].array {
            for c in contacts {
                let _ = UserContact.insertContact(contact: c)
            }
        }
        
        let _ = Chat.getOrCreateChat(chat: groupJson["chat"])
    }
    
    func tribeDeletedOrkickedFromGroup(type: String, json: JSON) {
        if let message = json["message"].dictionary {
            didReceiveMessage(type: type, messageJson: JSON(message))
        }
    }
    
    func didLeaveGroup(type: String, json: JSON) {
        didJoinOrLeaveGroup(type: type, json: json)
    }
    
    func didJoinGroup(type: String, json: JSON) {
        didJoinOrLeaveGroup(type: type, json: json)
    }
    
    func didJoinOrLeaveGroup(type: String, json: JSON) {
        if let _ = json["contact"].dictionary, let chatJson = json["chat"].dictionary {
            let _ = Chat.insertChat(chat: JSON(chatJson))
        }
        
        if let message = json["message"].dictionary {
            didReceiveMessage(type: type, messageJson: JSON(message))
        }
    }
    
    func memberRequest(type: String, json: JSON) {
        if let message = json["message"].dictionary {
            let _ = Chat.insertChat(chat: json["chat"])
            didReceiveMessage(type: type, messageJson: JSON(message))
        }
    }
    
    func memberRequestResponse(type: String, json: JSON) {
        if let message = json["message"].dictionary {
            
            let _ = Chat.insertChat(chat: json["chat"])
            didReceiveMessage(type: type, messageJson: JSON(message))
        }
    }
    
    func didReceiveInvite(inviteJson: JSON) {
        let _ = UserInvite.insertInvite(invite: inviteJson)
    }
    
    func showBubbleIfNeeded(message: TransactionMessage) -> Bool {
        let showBubble = shouldShowBubble(message: message)
        let onFullScreenCall = VideoCallManager.sharedInstance.activeFullScreenCall()
        
        if showBubble {
            newMessageBubbleHelper.showMessageView(
                message: message,
                onKeyWindow: !onFullScreenCall
            )
        }
        
        return showBubble
    }
    
    func shouldShowBubble(message: TransactionMessage) -> Bool {
        let outgoing = message.isOutgoing()
        
        if message.isUnknownType() {
            return false
        }
        
        if outgoing {
            return false
        }
        
        if message.chat?.isMuted() ?? false {
            return false
        }
        
        if (message.chat?.isOnlyMentions() ?? false) && !message.push {
            return false
        }
        
        if message.isPodcastPayment() {
            return false
        }
        
        if message.chat?.isMuted() ?? false {
            return false
        }
        
        if message.isPodcastPayment() {
            return false
        }
        
        if !outgoing && message.shouldAvoidShowingBubble() {
            return false
        }
        
        return true
    }
    
    func setSeen(
        message: TransactionMessage,
        value: Bool
    ) {
        message.seen = value
        message.chat?.seen = value
        CoreDataManager.sharedManager.saveContext()
    }
    
    func keysendReceived(json: JSON) {
        let _ = TransactionMessage.insertMessage(
            m: json,
            existingMessage: TransactionMessage.getMessageWith(id: json["id"].intValue)
        )
        let amt = json["amount"].intValue
        let messageContent = json["message_content"].stringValue
        
        if amt > 0 {
            if messageContent.isEmpty {
                let text = String(format: "keysend.received".localized, amt)
                newMessageBubbleHelper.showMessageView(title: "payment".localized, text: text)
            }
            updateBalanceIfNeeded(type: "keysend")
        }
    }
}
