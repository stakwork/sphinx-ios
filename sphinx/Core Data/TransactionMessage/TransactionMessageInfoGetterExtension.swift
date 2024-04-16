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
    
    var messageDate: Date {
        get {
            return self.date ?? Date(timeIntervalSince1970: 0)
        }
    }
    
    public enum MessageActionsItem: Int {
        case Delete
        case Copy
        case CopyLink
        case CopyPubKey
        case CopyCallLink
        case Reply
        case ShowThread
        case Save
        case Boost
        case Resend
        case Flag
        case Pin
        case Unpin
        case ToggleReadUnread
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
    
    func getMessageSenderNickname(
        minimized: Bool = false,
        forceNickname: Bool = false,
        owner: UserContact,
        contact: UserContact?
    ) -> String {
        var alias = "name.unknown".localized
        
        if let senderAlias = senderAlias {
            alias = senderAlias
        } else {
            if isIncoming(ownerId: owner.id) {
                if let sender = (contact ?? getMessageSender()) {
                    alias = sender.getUserName(forceNickname: forceNickname)
                }
            } else {
                alias = owner.getUserName(forceNickname: forceNickname)
            }
        }
        
        if let first = alias.components(separatedBy: " ").first, minimized {
            return first
        }
        
        return alias
    }
    
    func getMessageSenderImageUrl(
        owner: UserContact?,
        contact: UserContact?
    ) -> String? {
        let outgoing = self.isOutgoing()
        
        if (outgoing) {
            return self.chat?.myPhotoUrl ?? owner?.getPhotoUrl()
        } else {
            return self.senderPic ?? contact?.getPhotoUrl()
        }
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
        
        return image
    }
    
    //Message content and encryption
    static func isContentEncrypted(messageEncrypted: Bool, type: Int, mediaKey: String?) -> Bool {
        if type == TransactionMessageType.attachment.rawValue {
            return mediaKey != nil && mediaKey != ""
        }
        return messageEncrypted
    }
    
    func hasMessageContent() -> Bool {
        let messageC = (messageContent ?? "")
        
        if isGiphy() {
            if let message = GiphyHelper.getMessageFrom(message: messageC) {
                return !message.isEmpty
            }
        }
        
        if isPodcastComment() {
            return self.getPodcastComment()?.text != nil
        }
        
        if isPodcastBoost() {
            return false
        }

        return messageC != ""
    }
    
    func getMessageDescription() -> String {
        var adjustedMC = self.messageContent ?? ""
        
        if isGiphy(), let message = GiphyHelper.getMessageFrom(message: adjustedMC) {
            return message
        }
        
        if isPodcastComment(), let podcastComment = self.getPodcastComment() {
            return podcastComment.text ?? ""
        }
        
        if isPodcastBoost() {
            return "Boost"
        }
        
        if isCallLink() {
            adjustedMC = "join.call".localized
        }
        
        return adjustedMC
    }
    
    func getReplyMessageContent() -> String {
        if hasMessageContent() {
            let messageContent = bubbleMessageContentString ?? ""
            return messageContent.isValidHTML ? "bot.response.preview".localized : messageContent
        }
        if let fileName = self.mediaFileName {
            return fileName
        }
        return ""
    }
    
    //Direction
    func getDirection(id: Int) -> TransactionMessageDirection {
        if Int(self.senderId) == id {
            return TransactionMessageDirection.outgoing
        } else {
            return TransactionMessageDirection.incoming
        }
    }
    
    func isIncoming(
        ownerId: Int? = nil
    ) -> Bool {
        return getDirection(id: ownerId ?? UserData.sharedInstance.getUserId()) == TransactionMessageDirection.incoming
    }
    
    func isOutgoing(
        ownerId: Int? = nil
    ) -> Bool {
        return getDirection(id: ownerId ?? UserData.sharedInstance.getUserId()) == TransactionMessageDirection.outgoing
    }
    
    //Statues
    func isSeen(
        ownerId: Int
    ) -> Bool {
        return self.isOutgoing(ownerId: ownerId) || self.seen
    }
    
    func isProvisional() -> Bool {
        return id < 0
    }
    
    func pending() -> Bool {
        return status == TransactionMessageStatus.pending.rawValue
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
        return
            self.status == TransactionMessageStatus.received.rawValue ||
            (
                self.status == TransactionMessageStatus.confirmed.rawValue &&
                (
                    self.type == TransactionMessageType.payment.rawValue ||
                    self.type == TransactionMessageType.invoice.rawValue
                )
            )
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
        let mediaAttachmentTypes = [
            TransactionMessageType.imageAttachment.rawValue,
            TransactionMessageType.videoAttachment.rawValue,
            TransactionMessageType.pdfAttachment.rawValue,
        ]
        
        return mediaAttachmentTypes.contains(getType() ?? -1)
    }
    
    func isPaidMessage() -> Bool {
        return isAttachment() && getType() == TransactionMessageType.textAttachment.rawValue
    }
    
    func isPaidGenericFile() -> Bool {
        return isAttachment() && getType() == TransactionMessageType.fileAttachment.rawValue
    }
    
    func isPaidPendingMessage() -> Bool {
        return isAttachment() && getType() == TransactionMessageType.textAttachment.rawValue && mediaKey == nil
    }
    
    func isAttachment() -> Bool {
        return type == TransactionMessageType.attachment.rawValue
    }
    
    func isVideo() -> Bool {
        return getMediaType() == TransactionMessage.TransactionMessageType.videoAttachment.rawValue
    }
    
    func isImage() -> Bool {
        return getMediaType() == TransactionMessage.TransactionMessageType.imageAttachment.rawValue
    }
    
    func isAudio() -> Bool {
        return getMediaType() == TransactionMessage.TransactionMessageType.audioAttachment.rawValue
    }
    
    func isPDF() -> Bool {
        return getMediaType() == TransactionMessage.TransactionMessageType.pdfAttachment.rawValue
    }
    
    func isDoc() -> Bool {
        let fileName = getFileName().lowercased()
        return fileName.contains(".doc")
    }
    
    func isSpreadsheet() -> Bool {
        let fileName = getFileName().lowercased()
        return fileName.contains(".xls") || fileName.contains(".csv")
    }
    
    func getFileExtension() -> String {
        let fileName = getFileName().lowercased()
        return fileName.substringAfterLastOccurenceOf(".") ?? "txt"
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
    
    func isMessageBoost() -> Bool {
        return (type == TransactionMessageType.boost.rawValue && replyUUID != nil)
    }
    
    func isPayment() -> Bool {
        return type == TransactionMessageType.payment.rawValue
    }
    
    func isInvoice() -> Bool {
        return type == TransactionMessageType.invoice.rawValue
    }
    
    func isBotResponse() -> Bool {
        return type == TransactionMessageType.botResponse.rawValue
    }
    
    func isBotHTMLResponse() -> Bool {
        return type == TransactionMessageType.botResponse.rawValue && self.messageContent?.isValidHTML == true
    }
    
    func isBotTextResponse() -> Bool {
        return type == TransactionMessageType.botResponse.rawValue && self.messageContent?.isValidHTML == false
    }
    
    func isUnknownType() -> Bool {
        return type == TransactionMessageType.unknown.rawValue
    }
    
    func isMessageReaction() -> Bool {
        return type == TransactionMessageType.boost.rawValue &&
               (!(replyUUID ?? "").isEmpty || (messageContent?.isEmpty ?? true))
    }
    
    func isMemberRequest() -> Bool {
        return type == TransactionMessageType.memberRequest.rawValue
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
               type == TransactionMessageType.groupDelete.rawValue ||
               type == TransactionMessageType.memberRequest.rawValue ||
               type == TransactionMessageType.memberApprove.rawValue ||
               type == TransactionMessageType.memberReject.rawValue
    }
    
    func isGroupLeaveMessage() -> Bool {
        return type == TransactionMessageType.groupLeave.rawValue
    }
    
    func isGroupJoinMessage() -> Bool {
        return type == TransactionMessageType.groupJoin.rawValue
    }
    
    func isGroupKickMessage() -> Bool {
        return type == TransactionMessageType.groupKick.rawValue
    }
    
    func isGroupDeletedMessage() -> Bool {
        return type == TransactionMessageType.groupDelete.rawValue
    }
    
    func isGroupLeaveOrJoinMessage() -> Bool {
        return type == TransactionMessageType.groupJoin.rawValue ||
               type == TransactionMessageType.groupLeave.rawValue
    }
    
    func isDeleted() -> Bool {
        return status == TransactionMessageStatus.deleted.rawValue
    }
    
    func isFlagged() -> Bool {
        if !isFlagActionAllowed {
            return false
        }
        if let uuid = uuid {
            return (UserDefaults.standard.value(forKey: "\(uuid)-message-flag") as? Bool) ?? false
        }
        return false
    }
    
    func isNotConsecutiveMessage() -> Bool {
        return isPayment() || isInvoice() || isGroupActionMessage() || isDeleted()
    }
    
    func isDirectPayment() -> Bool {
        return type == TransactionMessageType.directPayment.rawValue
    }
    
    func isPurchaseAccept() -> Bool {
        return type == TransactionMessageType.purchaseAccept.rawValue
    }
    
    func isPodcastPayment() -> Bool {
        let feedIDString1 = "{\"feedID\":"
        let feedIDString2 = "{\"feedID\":"
        
        return (chat == nil &&
                    (messageContent?.contains(feedIDString1) ?? false || messageContent?.contains(feedIDString2) ?? false))
    }
    
    func isCallLink() -> Bool {
        return isCallMessageType() || messageContent?.isCallLink == true
    }
    
    func isCallMessageType() -> Bool {
        return type == TransactionMessageType.call.rawValue
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
    
    func getAmountString() -> String {
        let result = self.amount ?? NSDecimalNumber(value: 0)
        let amountString = Int(truncating: result).formattedWithSeparator
        return amountString
    }
    
    func getInvoicePaidAmountString() -> String {
        let invoice = TransactionMessage.getInvoiceWith(paymentHash: self.paymentHash ?? "")
        return invoice?.getAmountString() ?? "0"
    }
    

    func getActionsMenuOptions(
        isThreadRow: Bool = false,
        contactsViewIsRead: Bool? = nil
    ) -> [ActionsMenuOption] {
        var options = [ActionsMenuOption]()
        
        if isPodcastBoost() || isBotResponse() {
            return options
        }
        
        if messageContainText() {
            
            if isCopyTextActionAllowed {
                options.append(
                    .init(
                        tag: MessageActionsItem.Copy,
                        materialIconName: "",
                        iconImage: nil,
                        label: "copy.text".localized
                    )
                )
            }
            
            if isCopyLinkActionAllowed {
                options.append(
                    .init(
                        tag: MessageActionsItem.CopyLink,
                        materialIconName: "link",
                        iconImage: nil,
                        label:  "copy.link".localized
                    )
                )
            }
            
            if isCopyPublicKeyActionAllowed {
                options.append(
                    .init(
                        tag: MessageActionsItem.CopyPubKey,
                        materialIconName: "supervisor_account",
                        iconImage: nil,
                        label:  "copy.pub.key".localized
                    )
                )
            }
            
            if isCopyCallLinkActionAllowed {
                options.append(
                    .init(
                        tag: MessageActionsItem.CopyCallLink,
                        materialIconName: "link",
                        iconImage: nil,
                        label:  "copy.call.link".localized
                    )
                )
            }
        }
        
        if isReplyActionAllowed  {
            options.append(
                .init(
                    tag: MessageActionsItem.Reply,
                    materialIconName: "",
                    iconImage: nil,
                    label:  "reply".localized
                )
            )
        }
        
        if isDownloadFileActionAllowed {
            options.append(
                .init(
                    tag: MessageActionsItem.Save,
                    materialIconName: "",
                    iconImage: nil,
                    label: "save.file".localized
                )
            )
        }
        
        if isResendActionAllowed {
            options.append(
                .init(
                    tag: MessageActionsItem.Resend,
                    materialIconName: "redo",
                    iconImage: nil,
                    label: "Resend"
                )
            )
        }
        
        if isBoostActionAllowed {
            options.append(
                .init(
                    tag: MessageActionsItem.Boost,
                    materialIconName: nil,
                    iconImage: "boostIconGreen",
                    label: "Boost"
                )
            )
        }
        
        if isPinActionAllowed {
            options.append(
                .init(
                    tag: MessageActionsItem.Pin,
                    materialIconName: "push_pin",
                    iconImage: nil,
                    label:  "pin.message".localized
                )
            )
        }
        
        if isUnpinActionAllowed {
            options.append(
                .init(
                    tag: MessageActionsItem.Unpin,
                    materialIconName: "push_pin",
                    iconImage: nil,
                    label:  "unpin.message".localized
                )
            )
        }
        
        if let uuid = self.uuid, let chat = self.chat {
            ///Remove flag/delete for thread original message
            let threadMessages = TransactionMessage.getThreadMessagesFor([uuid], on: chat)
            
            if threadMessages.count > 1 {
                return options
            }
        }
        
//        if isFlagActionAllowed {
//            options.append(
//                .init(
//                    tag: MessageActionsItem.Flag,
//                    materialIconName: nil,
//                    iconImage: "iconFlagContent",
//                    label:  "flag.item".localized
//                )
//            )
//        }
        
        if isDeleteActionAllowed {
            options.append(
                .init(
                    tag: MessageActionsItem.Delete,
                    materialIconName: "delete",
                    iconImage: nil,
                    label:  "delete.message".localized
                )
            )
        }
        
        return options
    }
    
    func messageContainText() -> Bool {
        return bubbleMessageContentString != nil && bubbleMessageContentString != ""
    }
    
    var isCopyTextActionAllowed: Bool {
        get {
            if let messageContent = bubbleMessageContentString {
                return !self.isCallLink() && !messageContent.isEncryptedString()
            }
            return false
        }
    }
    
    var isCopyLinkActionAllowed: Bool {
        get {
            if let messageContent = bubbleMessageContentString {
                return messageContent.stringLinks.count > 0
            }
            return false
        }
    }
    
    var isCopyPublicKeyActionAllowed: Bool {
        get {
            if let messageContent = bubbleMessageContentString {
                return messageContent.pubKeyMatches.count > 0
            }
            return false
        }
    }
    
    var isCopyCallLinkActionAllowed: Bool {
        get {
            return self.isCallLink()
        }
    }
    
    var isReplyActionAllowed: Bool {
        get {
            return (isTextMessage() || (isAttachment() && !isAudio())) && !(uuid ?? "").isEmpty
        }
    }
    
    var isDownloadFileActionAllowed: Bool {
        get {
            return (type == TransactionMessageType.attachment.rawValue && getMediaType() != TransactionMessageType.textAttachment.rawValue) || isGiphy()
        }
    }
    
    var isResendActionAllowed: Bool {
        get {
            return (isTextMessage() && status == TransactionMessageStatus.failed.rawValue)
        }
    }
    
    var isFlagActionAllowed: Bool {
        get {
            return isIncoming()
        }
    }
    
    var isDeleteActionAllowed: Bool {
        get {
            return (!isInvoice() || (isInvoice() && !isPaid())) && canBeDeleted()
        }
    }
    
    var isPinActionAllowed: Bool {
        get {
            return (self.chat?.isMyPublicGroup() ?? false) && !isMessagePinned && messageContainText()
        }
    }
    
    var isUnpinActionAllowed: Bool {
        get {
            return (self.chat?.isMyPublicGroup() ?? false) && isMessagePinned
        }
    }
    
    var isMessagePinned: Bool {
        get {
            return self.uuid == self.chat?.pinnedMessageUUID
        }
    }
    
    var bubbleMessageContentString: String? {
        get {
            if isGiphy(), let message = GiphyHelper.getMessageFrom(message: messageContent ?? "") {
                return message
            }
            
            if isPodcastComment(), let podcastComment = self.getPodcastComment() {
                return podcastComment.text
            }
            
            if isPodcastBoost() {
                return nil
            }
            
            if isCallLink() {
                return nil
            }
            
            if let messageC = messageContent {
                if messageC.isEncryptedString() {
                    return "encryption.error".localized
                }
            }
            
            return self.messageContent
        }
    }
    
    var isBoostActionAllowed: Bool {
        get {
            return isIncoming() &&
            !isInvoice() &&
            !isDirectPayment() &&
            !isCallLink() &&
            !(uuid ?? "").isEmpty
        }
    }
    
    //Message description
    func getMessageContentPreview(
        owner: UserContact,
        contact: UserContact?
    ) -> String {
        let amount = self.amount ?? NSDecimalNumber(value: 0)
        let amountString = Int(truncating: amount).formattedWithSeparator
        
        let incoming = self.isIncoming(ownerId: owner.id)
        let directionString = incoming ? "received".localized : "sent".localized
        let senderAlias = self.getMessageSenderNickname(minimized: true, owner: owner, contact: contact)
        
        if isDeleted() {
            return "message.x.deleted".localized
        }

        switch (self.getType()) {
        case TransactionMessage.TransactionMessageType.message.rawValue,
             TransactionMessage.TransactionMessageType.call.rawValue:
            if self.isGiphy() {
                return "\("gif.capitalize".localized) \(directionString)"
            } else {
                return "\(senderAlias): \(self.getMessageDescription())"
            }
        case TransactionMessage.TransactionMessageType.invoice.rawValue:
            return  "\("invoice".localized) \(directionString): \(amountString) sats"
        case TransactionMessage.TransactionMessageType.payment.rawValue:
            let invoiceAmount = getInvoicePaidAmountString()
            return  "\("payment".localized) \(directionString): \(invoiceAmount) sats"
        case TransactionMessage.TransactionMessageType.directPayment.rawValue:
            let isTribe = self.chat?.isPublicGroup() ?? false
            let senderAlias = self.senderAlias ?? "Unknown".localized
            let recipientAlias = self.recipientAlias ?? "Unknown".localized
            
            if isTribe {
                if incoming {
                    return String(format: "tribe.payment.received".localized, senderAlias, "\(amountString) sats" , recipientAlias)
                } else {
                    return String(format: "tribe.payment.sent".localized, "\(amountString) sats", recipientAlias)
                }
            } else {
                return "\("payment".localized) \(directionString): \(amountString) sats"
            }
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
            return self.getGroupMessageText(owner: owner, contact: contact).withoutBreaklines
        case TransactionMessage.TransactionMessageType.boost.rawValue:
            return "\(self.getMessageSenderNickname(minimized: true, owner: owner, contact: contact)): Boost"
        case TransactionMessage.TransactionMessageType.purchase.rawValue:
            return "\("purchase.item.description".localized) \(directionString)"
        case TransactionMessage.TransactionMessageType.purchaseAccept.rawValue:
            return "item.purchased".localized
        case TransactionMessage.TransactionMessageType.purchaseDeny.rawValue:
            return "item.purchase.denied".localized
        default: break
        }
        return "\("message.not.supported".localized) \(directionString)"
    }
    
    func getGroupMessageText(
        owner: UserContact,
        contact: UserContact?
    ) -> String {
        var message = "message.not.supported"
        
        switch(type) {
        case TransactionMessageType.groupJoin.rawValue:
            message = getGroupJoinMessageText(owner: owner, contact: contact)
        case TransactionMessageType.groupLeave.rawValue:
            message = getGroupLeaveMessageText(owner: owner, contact: contact)
        case TransactionMessageType.groupKick.rawValue:
            message = "tribe.kick".localized
        case TransactionMessageType.groupDelete.rawValue:
            message = "tribe.deleted".localized
        case TransactionMessageType.memberRequest.rawValue:
            message = String(format: "member.request".localized, getMessageSenderNickname(owner: owner, contact: contact))
        case TransactionMessageType.memberApprove.rawValue:
            message = getMemberApprovedMessageText(owner: owner, contact: contact)
        case TransactionMessageType.memberReject.rawValue:
            message = getMemberDeclinedMessageText(owner: owner, contact: contact)
        default:
            break
        }
        return message
    }
    
    func getMemberDeclinedMessageText(
        owner: UserContact,
        contact: UserContact?
    ) -> String {
        if self.chat?.isMyPublicGroup(ownerPubKey: owner.publicKey) ?? false {
            return String(format: "admin.request.rejected".localized, getMessageSenderNickname(owner: owner, contact: contact))
        } else {
            return "member.request.rejected".localized
        }
    }
    
    func getMemberApprovedMessageText(
        owner: UserContact,
        contact: UserContact?
    ) -> String {
        if self.chat?.isMyPublicGroup(ownerPubKey: owner.publicKey) ?? false {
            return String(format: "admin.request.approved".localized, getMessageSenderNickname(owner: owner, contact: contact))
        } else {
            return "member.request.approved".localized
        }
    }
    
    func getGroupJoinMessageText(
        owner: UserContact,
        contact: UserContact?
    ) -> String {
        return getGroupJoinMessageText(
            senderAlias: getMessageSenderNickname(
                owner: owner,
                contact: contact
            )
        )
    }
    
    func getGroupLeaveMessageText(
        owner: UserContact,
        contact: UserContact?
    ) -> String {
        return getGroupLeaveMessageText(
            senderAlias: getMessageSenderNickname(
                owner: owner,
                contact: contact
            )
        )
    }
    
    func getGroupJoinMessageText(senderAlias: String) -> String {
        return String(format: "has.joined.tribe".localized, senderAlias)
    }
    
    func getGroupLeaveMessageText(senderAlias: String) -> String {
        return String(format: "just.left.tribe".localized, senderAlias)
    }
    
    func getPodcastComment() -> PodcastComment? {
        let messageC = (messageContent ?? "")
        
        if messageC.isPodcastComment {
            let stringWithoutPrefix = messageC.replacingOccurrences(
                of: PodcastFeed.kClipPrefix,
                with: ""
            )
            
            if let data = stringWithoutPrefix.data(using: .utf8) {
                
                if let jsonObject = try? JSON(data: data) {
                    
                    var podcastComment = PodcastComment()
                    podcastComment.feedId = jsonObject["feedID"].stringValue
                    podcastComment.itemId = jsonObject["itemID"].stringValue
                    podcastComment.timestamp = jsonObject["ts"].intValue
                    podcastComment.title = jsonObject["title"].stringValue
                    podcastComment.text = jsonObject["text"].stringValue
                    podcastComment.url = jsonObject["url"].stringValue
                    podcastComment.pubkey = jsonObject["pubkey"].stringValue
                    podcastComment.uuid = self.uuid ?? ""
                    
                    if podcastComment.isValid() {
                        return podcastComment
                    }
                }
            }
        }
        
        return nil
    }
    
    func getBoostAmount() -> Int {
        let messageC = (messageContent ?? "")
        
        let stringWithoutPrefix = messageC.replacingOccurrences(of: PodcastFeed.kBoostPrefix, with: "")
        if let data = stringWithoutPrefix.data(using: .utf8) {
            if let jsonObject = try? JSON(data: data) {
                return jsonObject["amount"].intValue
            }
        }
        return 0
    }
    
    func getTimeStamp() -> Int? {
        let messageC = (messageContent ?? "")
        
        var stringWithoutPrefix = messageC.replacingOccurrences(of: PodcastFeed.kBoostPrefix, with: "")
        stringWithoutPrefix = stringWithoutPrefix.replacingOccurrences(of: PodcastFeed.kClipPrefix, with: "")
        
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
            return (isStandardPIN && !(messageSender?.pin ?? "").isEmpty) ||
                   (!isStandardPIN && (messageSender?.pin ?? "").isEmpty) ||
                   messageSender?.isBlocked() == true
        } else {
            return (isStandardPIN && !(chat?.pin ?? "").isEmpty) ||
                   (!isStandardPIN && (chat?.pin ?? "").isEmpty)
        }
    }
    
    //Grouping Logic
    func shouldAvoidGrouping() -> Bool {
        return pending() || failed() || isDeleted() || isInvoice() || isPayment() || isGroupActionMessage() || isFlagged()
    }
    
    func hasSameSenderThanMessage(_ message: TransactionMessage) -> Bool {
        let hasSameSenderId = senderId == message.senderId
        let hasSameSenderAlias = (senderAlias ?? "") == (message.senderAlias ?? "")
        let hasSameSenderPicture = (senderPic ?? "") == (message.senderPic ?? "")

        return hasSameSenderId && hasSameSenderAlias && hasSameSenderPicture
    }
}
