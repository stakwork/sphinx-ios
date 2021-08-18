//
//  TransactionMessageInfoGetterExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import CoreData
import SwiftyJSON

extension TransactionMessage {
    
    public enum MessageActionsItem: Int {
        case Delete
        case Copy
        case CopyLink
        case CopyPubKey
        case CopyCallLink
        case Reply
        case Save
        case Boost
        case Resend
    }
    
    
    public struct ActionsMenuOption {
        var tag: MessageActionsItem
        var materialIconName: String?
        var iconImage: String?
        var label: String
    }
    
    //Sender and Receiver info
    func getMessageSender() -> UserContact? {
        return UserContact.getContactWith(id: self.senderId)
    }
    
    func getMessageReceiver() -> UserContact? {
        if let chat = self.chat, chat.type == Chat.ChatType.conversation.rawValue {
            for user in chat.getContacts() {
                if user.id != self.senderId {
                    return user
                }
            }
        }
        return nil
    }
    
    func getMessageReceiverNickname() -> String {
        if let receiver = getMessageReceiver() {
            return receiver.getName()
        }
        return "name.unknown".localized
    }
    
    func getMessageSenderNickname(minimized: Bool = false, forceNickname: Bool = false) -> String {
        var alias = "name.unknown".localized
        
        if let senderAlias = senderAlias {
            alias = senderAlias
        } else if let sender = getMessageSender() {
            alias = sender.getUserName(forceNickname: forceNickname)
        }
        
        if let first = alias.components(separatedBy: " ").first, minimized {
            return first
        }
        
        return alias
    }
    
    func hasSameSenderThan(message: TransactionMessage?) -> Bool {
        let hasSameSenderId = senderId == (message?.senderId ?? -1)
        let hasSameSenderAlias = (senderAlias ?? "") == (message?.senderAlias ?? "")
        let hasSamePicture = (senderPic ?? "") == (message?.senderPic ?? "")
        
        return hasSameSenderId && hasSameSenderAlias && hasSamePicture
    }
    
    func getMessageSenderProfilePic(chat: Chat?, contact: UserContact?) -> String? {
        var image: String? = contact?.avatarUrl?.removeDuplicatedProtocol().trim()
        
        if chat?.isPublicGroup() ?? false {
            image = self.senderPic?.removeDuplicatedProtocol().trim()
        }
        
        if let image = image {
            return image + "?thumb=true"
        }
        return nil
    }
    
    //Message content and encryption
    static func isContentEncrypted(messageEncrypted: Bool, type: Int, mediaKey: String?) -> Bool {
        if type == TransactionMessageType.attachment.rawValue {
            return mediaKey != nil && mediaKey != ""
        }
        return messageEncrypted
    }
    
    func canBeDecrypted() -> Bool {
        if let messageC = self.messageContent, messageC.isEncryptedString() {
            return false
        }
        
        return true
    }
    
    func hasMessageContent() -> Bool {
        let messageC = (messageContent ?? "")
        
        if isGiphy() {
            if let message = GiphyHelper.getMessageFrom(message: messageC) {
                return !message.isEmpty
            }
        }
        
        if isPodcastComment() {
            self.processPodcastComment()
            return self.podcastComment?.text != nil
        }
        
        if isPodcastBoost() {
            return false
        }

        return messageC != ""
    }
    
    func getMessageContent(dashboard: Bool = false) -> String {
        var adjustedMC = self.messageContent ?? ""
        
        if isGiphy(), let message = GiphyHelper.getMessageFrom(message: adjustedMC) {
            return message
        }
        
        if isPodcastComment() {
            self.processPodcastComment()
            
            if let text = self.podcastComment?.text, !text.isEmpty {
                return text
            }
        }
        
        if isPodcastBoost() {
            return "Boost"
        }
        
        if let messageC = self.messageContent {
            if messageC.isEncryptedString() {
                adjustedMC = getDecrytedMessage(dashboard: dashboard)
            } else if messageC.isVideoCallLink {
                adjustedMC = "join.call".localized
            }
        }
        
        if self.isPaidMessage() {
            adjustedMC = getPaidMessageContent()
        }
        
        return adjustedMC
    }
    
    func getReplyMessageContent() -> String {
        if hasMessageContent() {
            return getMessageContent()
        }
        if let fileName = self.mediaFileName {
            return fileName
        }
        return ""
    }
    
    func getDecrytedMessage(dashboard: Bool = false) -> String {
        if let messageC = self.messageContent, UIApplication.shared.isActive() {
            if messageC.isEncryptedString() {
                let (decrypted, message) = EncryptionManager.sharedInstance.decryptMessage(message: messageC)
                if decrypted {
                    self.messageContent = message
                    self.saveMessage()
                    return message
                }
            }
        }
        return dashboard ? "decrypting.message".localized : "encryption.error".localized.uppercased()
    }
    
    func getPaidMessageContent() -> String {
        var adjustedMC = self.messageContent ?? ""
        
        if self.isPendingPaidMessage() {
            if paidMessageError {
                adjustedMC = "cannot.load.message.data".localized.uppercased()
            } else {
                adjustedMC = "pay.to.unlock.msg".localized.uppercased()
            }
        } else if self.isLoadingPaidMessage() {
            adjustedMC = "loading.paid.message".localized.uppercased()
        }
        
        return adjustedMC
    }
    
    //Direction
    func getDirection(id: Int) -> TransactionMessageDirection {
        if Int(self.senderId) == id {
            return TransactionMessageDirection.outgoing
        } else {
            return TransactionMessageDirection.incoming
        }
    }
    
    func isIncoming() -> Bool {
        return getDirection(id: UserData.sharedInstance.getUserId()) == TransactionMessageDirection.incoming
    }
    
    func isOutgoing() -> Bool {
        return getDirection(id: UserData.sharedInstance.getUserId()) == TransactionMessageDirection.outgoing
    }
    
    //Statues
    func isFailedOrMediaExpired() -> Bool {
        let failed = self.failed()
        let expired = self.isMediaExpired()
        
        return failed || expired
    }
    
    func received() -> Bool {
        return status == TransactionMessageStatus.received.rawValue
    }
    
    func failed() -> Bool {
        return status == TransactionMessageStatus.cancelled.rawValue || status == TransactionMessageStatus.failed.rawValue
    }
    
    func isPaid() -> Bool {
        return status == TransactionMessageStatus.confirmed.rawValue
    }
    
    func isExpired() -> Bool {
        let expired = Date().timeIntervalSince1970 > (self.expirationDate ?? Date()).timeIntervalSince1970
        return expired
    }
    
    func isCancelled() -> Bool {
        return status == TransactionMessageStatus.cancelled.rawValue
    }
    
    public func isConfirmedAsReceived() -> Bool {
        return self.status == TransactionMessageStatus.received.rawValue
    }
    
    //Message type
    func getType() -> Int? {
        if let mediaType = getMediaType() {
            return mediaType
        }
        return self.type
    }
    
    func isTextMessage() -> Bool {
        return getType() == TransactionMessageType.message.rawValue
    }
    
    func isMediaAttachment() -> Bool {
        return (isAttachment() && getType() != TransactionMessageType.textAttachment.rawValue) || isGiphy()
    }
    
    func isPaidMessage() -> Bool {
        return isAttachment() && getType() == TransactionMessageType.textAttachment.rawValue
    }
    
    func isPendingPaidMessage() -> Bool {
        return isPaidMessage() && isIncoming() && getMediaUrl(queryDB: false) == nil && (messageContent?.isEmpty ?? true)
    }
    
    func isLoadingPaidMessage() -> Bool {
        if let _ = getMediaUrl(), (messageContent?.isEmpty ?? true) && isPaidMessage() {
            return true
        }
        return false
    }
    
    func isMessageUploadingAttachment() -> Bool {
        return isAttachment() && getType() == TransactionMessageType.textAttachment.rawValue && messageContent == nil && !isIncoming()
    }
    
    func isAttachment() -> Bool {
        return type == TransactionMessageType.attachment.rawValue
    }
    
    func canBeDownloaded() -> Bool {
        return (type == TransactionMessageType.attachment.rawValue && getMediaType() != TransactionMessageType.textAttachment.rawValue) || isGiphy()
    }
    
    func isVideo() -> Bool {
        return getMediaType() == TransactionMessage.TransactionMessageType.videoAttachment.rawValue
    }
    
    func isAudio() -> Bool {
        return getMediaType() == TransactionMessage.TransactionMessageType.audioAttachment.rawValue
    }
    
    func isPDF() -> Bool {
        return getMediaType() == TransactionMessage.TransactionMessageType.pdfAttachment.rawValue
    }
    
    func isFileAttachment() -> Bool {
        return getMediaType() == TransactionMessage.TransactionMessageType.fileAttachment.rawValue
    }
    
    func isPicture() -> Bool {
        return isAttachment() && (mediaType?.contains("image") ?? false)
    }
    
    func isGif() -> Bool {
        return isAttachment() && (mediaType?.contains("gif") ?? false)
    }
    
    func isGiphy() -> Bool {
        return (self.messageContent ?? "").isGiphy
    }
    
    func isPodcastComment() -> Bool {
        return (self.messageContent ?? "").isPodcastComment
    }
    
    func isPodcastBoost() -> Bool {
        return (self.messageContent ?? "").isPodcastBoost ||
               (type == TransactionMessageType.boost.rawValue && replyUUID == nil)
    }
    
    func isPayment() -> Bool {
        return type == TransactionMessageType.payment.rawValue
    }
    
    func isInvoice() -> Bool {
        return type == TransactionMessageType.invoice.rawValue
    }
    
    func isBoosted() -> Bool {
        return self.reactions != nil && (self.reactions?.totalSats ?? 0) > 0
    }
    
    func isUnknownType() -> Bool {
        return type == TransactionMessageType.unknown.rawValue
    }
    
    func isMessageReaction() -> Bool {
        return type == TransactionMessageType.boost.rawValue &&
               (!(replyUUID ?? "").isEmpty || (messageContent?.isEmpty ?? true))
    }
    
    func isApprovedRequest() -> Bool {
        return type == TransactionMessageType.memberApprove.rawValue
    }
    
    func isDeclinedRequest() -> Bool {
        return type == TransactionMessageType.memberReject.rawValue
    }
    
    func isGroupActionMessage() -> Bool {
        return type == TransactionMessageType.groupJoin.rawValue ||
               type == TransactionMessageType.groupLeave.rawValue ||
               type == TransactionMessageType.groupKick.rawValue ||
               type == TransactionMessageType.memberRequest.rawValue ||
               type == TransactionMessageType.memberApprove.rawValue ||
               type == TransactionMessageType.memberReject.rawValue
    }
    
    func isDeleted() -> Bool {
        return status == TransactionMessageStatus.deleted.rawValue
    }
    
    func isNotConsecutiveMessage() -> Bool {
        return isPayment() || isInvoice() || isGroupActionMessage() || isDeleted()
    }
    
    func isDirectPayment() -> Bool {
        return type == TransactionMessageType.directPayment.rawValue
    }
    
    func isPodcastPayment() -> Bool {
        let feedIDString1 = "{\"feedID\":"
        let feedIDString2 = "{\"feedID\":"
        
        return (chat == nil &&
                    (messageContent?.contains(feedIDString1) ?? false || messageContent?.contains(feedIDString2) ?? false))
    }
    
    func canBeDeleted() -> Bool {
        return isOutgoing() || (self.chat?.isMyPublicGroup() ?? false)
    }
    
    func isReply() -> Bool {
        if let replyUUID = replyUUID, !replyUUID.isEmpty {
            return true
        }
        return false
    }
    
    func getReplyingTo() -> TransactionMessage? {
        if let replyUUID = replyUUID, !replyUUID.isEmpty {
            if let replyingMessage = replyingMessage {
                return replyingMessage
            }
            replyingMessage = TransactionMessage.getMessageWith(uuid: replyUUID)
            return replyingMessage
        }
        return nil
    }
    
    func getAmountString() -> String {
        let result = self.amount ?? NSDecimalNumber(value: 0)
        let amountString = Int(truncating: result).formattedWithSeparator
        return amountString
    }
    
    func getInvoicePaidAmountString() -> String {
        let invoice = TransactionMessage.getInvoiceWith(paymentHash: self.paymentHash ?? "")
        return invoice?.getAmountString() ?? "0"
    }
    
    func getActionsMenuOptions() -> [ActionsMenuOption] {
        var options = [ActionsMenuOption]()
        
        if isPodcastBoost() {
            return options
        }
        
        if let messageContent = messageContent, messageContent != "" && !isGiphy() {
            if !messageContent.isVideoCallLink && !messageContent.isEncryptedString() {
                options.append(
                    .init(tag: MessageActionsItem.Copy, materialIconName: "", iconImage: nil, label: "copy.text".localized)
                )
            }
            
            if !messageContent.isVideoCallLink && messageContent.stringLinks.count > 0 {
                options.append(
                    .init(tag: MessageActionsItem.CopyLink, materialIconName: "link", iconImage: nil, label:  "copy.link".localized)
                )
            }
            
            if messageContent.pubKeyMatches.count > 0 {
                options.append(
                    .init(tag: MessageActionsItem.CopyPubKey, materialIconName: "supervisor_account", iconImage: nil, label:  "copy.pub.key".localized)
                )
            }
            
            if messageContent.isVideoCallLink {
                options.append(
                    .init(tag: MessageActionsItem.CopyCallLink, materialIconName: "link", iconImage: nil, label:  "copy.call.link".localized)
                )
            }
        }
        if (isTextMessage() || isAttachment()) && !(uuid ?? "").isEmpty {
            options.append(
                .init(tag: MessageActionsItem.Reply, materialIconName: "", iconImage: nil, label:  "reply".localized)
            )
        }
        
        if canBeDownloaded() {
            options.append(
                .init(tag: MessageActionsItem.Save, materialIconName: "", iconImage: nil, label: "save.file".localized)
            )
        }
        
        if (!isInvoice() || (isInvoice() && !isPaid())) && canBeDeleted() {
            options.append(
                .init(tag: MessageActionsItem.Delete, materialIconName: "delete", iconImage: nil, label:  "delete.message".localized)
            )
        }
        
        if shouldAllowBoost() {
            options.append(
                .init(tag: MessageActionsItem.Boost, materialIconName: nil, iconImage: "boostIconGreen", label: "Boost")
            )
        }
        
        if (isTextMessage() && status == TransactionMessageStatus.failed.rawValue) {
            options.append(
                .init(
                    tag: MessageActionsItem.Resend,
                    materialIconName: "redo",
                    iconImage: nil,
                    label: "Resend"
                )
            )
        }
        
        return options
    }
    
    func shouldAllowBoost() -> Bool {
        return isIncoming() && !isInvoice() && !isDirectPayment() && !(messageContent ?? "").isVideoCallLink && !(uuid ?? "").isEmpty
    }
    
    func isNewUnseenMessage() -> Bool {
        let chatSeen = (self.chat?.seen ?? false)
        var newMessage = !chatSeen && !seen && !failed() && isIncoming()
        
        let (purchaseStateItem, seen) = getPurchaseStateItem()
        if let _ = purchaseStateItem {
            newMessage = !seen
        }
        
        return newMessage
    }
    
    func isUniqueOnChat() -> Bool {
        return (self.chat?.messages?.count ?? 0) == 1
    }
    
    func save(webViewHeight height: CGFloat) {
        if var heighs: [Int: CGFloat] = UserDefaults.Keys.webViewsHeight.getObject() {
            heighs[self.id] = height
            UserDefaults.Keys.webViewsHeight.setObject(heighs)
        } else {
            UserDefaults.Keys.webViewsHeight.setObject([self.id: height])
        }
    }
    
    func getWebViewHeight() -> CGFloat? {
        if let heighs: [Int: CGFloat] = UserDefaults.Keys.webViewsHeight.getObject() {
            return heighs[self.id]
        }
        return nil
    }
    
    //Message description
    func getMessageDescription(dashboard: Bool = false) -> String {
        let amount = self.amount ?? NSDecimalNumber(value: 0)
        let amountString = Int(truncating: amount).formattedWithSeparator
        let incoming = self.isIncoming()
        let directionString = incoming ? "received".localized : "sent".localized
        
        if isDeleted() {
            return "message.x.deleted".localized
        }
        
        if let purchaseItem = getPurchaseItems(includeAttachment: true).last, let purchaseDecription = purchaseItem.getPurchaseDescription(directionString) {
            return purchaseDecription
        }

        switch (self.getType()) {
        case TransactionMessage.TransactionMessageType.message.rawValue:
            if self.isGiphy() {
                return "\("gif.capitalize".localized) \(directionString)"
            } else {
                return "\(self.getMessageSenderNickname(minimized: true)): \(self.getMessageContent(dashboard: dashboard))"
            }
        case TransactionMessage.TransactionMessageType.invoice.rawValue:
            return  "\("invoice".localized) \(directionString): \(amountString) sat"
        case TransactionMessage.TransactionMessageType.payment.rawValue:
            let invoiceAmount = getInvoicePaidAmountString()
            return  "\("payment".localized) \(directionString): \(invoiceAmount) sat"
        case TransactionMessage.TransactionMessageType.directPayment.rawValue:
            return "\("payment".localized) \(directionString): \(amountString) sat"
        case TransactionMessage.TransactionMessageType.imageAttachment.rawValue:
            if self.isGif() {
                return "\("gif.capitalize".localized) \(directionString)"
            } else {
                return "\("picture.capitalize".localized) \(directionString)"
            }
        case TransactionMessage.TransactionMessageType.videoAttachment.rawValue:
            return "\("video.capitalize".localized) \(directionString)"
        case TransactionMessage.TransactionMessageType.audioAttachment.rawValue:
            return "\("audio.capitalize".localized) \(directionString)"
        case TransactionMessage.TransactionMessageType.pdfAttachment.rawValue:
            return "PDF \(directionString)"
        case TransactionMessage.TransactionMessageType.fileAttachment.rawValue:
            return "\("file".localized) \(directionString)"
        case TransactionMessage.TransactionMessageType.textAttachment.rawValue:
            return "\("paid.message.capitalize".localized) \(directionString)"
        case TransactionMessage.TransactionMessageType.botResponse.rawValue:
            return "\("bot.response".localized) \(directionString)"
        case TransactionMessage.TransactionMessageType.groupLeave.rawValue,
             TransactionMessage.TransactionMessageType.groupJoin.rawValue,
             TransactionMessage.TransactionMessageType.groupKick.rawValue,
             TransactionMessage.TransactionMessageType.groupDelete.rawValue,
             TransactionMessage.TransactionMessageType.memberRequest.rawValue,
             TransactionMessage.TransactionMessageType.memberApprove.rawValue,
             TransactionMessage.TransactionMessageType.memberReject.rawValue:
            return self.getGroupMessageText().withoutBreaklines
        case TransactionMessage.TransactionMessageType.boost.rawValue:
            return "\(self.getMessageSenderNickname(minimized: true)): Boost"
        default: break
        }
        return "\("message.not.supported".localized) \(directionString)"
    }
    
    func getGroupMessageText() -> String {
        var message = "message.not.supported"
        
        switch(type) {
        case TransactionMessageType.groupJoin.rawValue:
            message = getGroupJoinMessageText()
        case TransactionMessageType.groupLeave.rawValue:
            message = getGroupLeaveMessageText()
        case TransactionMessageType.groupKick.rawValue:
            message = "tribe.kick".localized
        case TransactionMessageType.groupDelete.rawValue:
            message = "tribe.deleted".localized
        case TransactionMessageType.memberRequest.rawValue:
            message = String(format: "member.request".localized, getMessageSenderNickname())
        case TransactionMessageType.memberApprove.rawValue:
            message = getMemberApprovedMessageText()
        case TransactionMessageType.memberReject.rawValue:
            message = getMemberDeclinedMessageText()
        default:
            break
        }
        return message
    }
    
    func getMemberDeclinedMessageText() -> String {
        if self.chat?.isMyPublicGroup() ?? false {
            return String(format: "admin.request.rejected".localized, getMessageSenderNickname())
        } else {
            return "member.request.rejected".localized
        }
    }
    
    func getMemberApprovedMessageText() -> String {
        if self.chat?.isMyPublicGroup() ?? false {
            return String(format: "admin.request.approved".localized, getMessageSenderNickname())
        } else {
            return "member.request.approved".localized
        }
    }
    
    func getGroupJoinMessageText() -> String {
        if (self.chat?.isPublicGroup() ?? false) {
            return String(format: "has.joined.tribe".localized, getMessageSenderNickname())
        } else {
            return String(format: "added.to.group".localized, getMessageSenderNickname())
        }
    }
    
    func getGroupLeaveMessageText() -> String {
        if (self.chat?.isPublicGroup() ?? false) {
            return String(format: "just.left.tribe".localized, getMessageSenderNickname())
        } else {
            return String(format: "just.left.group".localized, getMessageSenderNickname())
        }
    }
    
    func getPurchaseDescription(_ directionString: String) -> String? {
        let (purchaseItem, _) = getPurchaseStateItem()
        if let purchaseItem = purchaseItem {
            switch (purchaseItem.getType()) {
            case TransactionMessage.TransactionMessageType.purchase.rawValue:
                return String(format: "purchase.item.description".localized, directionString)
            case TransactionMessage.TransactionMessageType.purchaseAccept.rawValue:
                return "item.purchased".localized
            case TransactionMessage.TransactionMessageType.purchaseDeny.rawValue:
                return "item.purchase.denied".localized
            default: break
            }
        }
        return nil
    }
    
    func processPodcastComment() {
        if let _ = self.podcastComment {
            return
        }
        
        let messageC = (messageContent ?? "")
        
        if messageC.isPodcastComment {
            let stringWithoutPrefix = messageC.replacingOccurrences(of: PodcastPlayerHelper.kClipPrefix, with: "")
            if let data = stringWithoutPrefix.data(using: .utf8) {
                if let jsonObject = try? JSON(data: data) {
                    var podcastComment = PodcastComment()
                    podcastComment.feedId = jsonObject["feedID"].intValue
                    podcastComment.itemId = jsonObject["itemID"].intValue
                    podcastComment.timestamp = jsonObject["ts"].intValue
                    podcastComment.title = jsonObject["title"].stringValue
                    podcastComment.text = jsonObject["text"].stringValue
                    podcastComment.url = jsonObject["url"].stringValue
                    podcastComment.pubkey = jsonObject["pubkey"].stringValue
                    podcastComment.uuid = self.uuid ?? ""
                    
                    self.podcastComment = podcastComment
                }
            }
        }
    }
    
    func getBoostAmount() -> Int {
        let messageC = (messageContent ?? "")
        
        let stringWithoutPrefix = messageC.replacingOccurrences(of: PodcastPlayerHelper.kBoostPrefix, with: "")
        if let data = stringWithoutPrefix.data(using: .utf8) {
            if let jsonObject = try? JSON(data: data) {
                return jsonObject["amount"].intValue
            }
        }
        return 0
    }
    
    func getTimeStamp() -> Int? {
        let messageC = (messageContent ?? "")
        
        var stringWithoutPrefix = messageC.replacingOccurrences(of: PodcastPlayerHelper.kBoostPrefix, with: "")
        stringWithoutPrefix = stringWithoutPrefix.replacingOccurrences(of: PodcastPlayerHelper.kClipPrefix, with: "")
        
        if let data = stringWithoutPrefix.data(using: .utf8) {
            if let jsonObject = try? JSON(data: data) {
                return jsonObject["ts"].intValue
            }
        }
        return nil
    }
    
    func shouldAvoidShowingBubble() -> Bool {
        let groupsPinManager = GroupsPinManager.sharedInstance
        let isStandardPIN = groupsPinManager.isStandardPIN
        let isPrivateConversation = !(chat?.isGroup() ?? false)
        let messageSender = getMessageSender()
        
        if isPrivateConversation {
            return (isStandardPIN && !(messageSender?.pin ?? "").isEmpty) || (!isStandardPIN && (messageSender?.pin ?? "").isEmpty)
        } else {
            return (isStandardPIN && !(chat?.pin ?? "").isEmpty) || (!isStandardPIN && (chat?.pin ?? "").isEmpty)
        }
    }
}
