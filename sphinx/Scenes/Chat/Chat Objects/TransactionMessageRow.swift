//
//  Library
//
//  Created by Tomas Timinskas on 12/04/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class TransactionMessageRow {
    
    var transactionMessage: TransactionMessage! = nil
    
    var shouldShowRightLine = false
    var shouldShowLeftLine = false
    var isPodcastLive = false
    
    var headerDate : Date?
    
    var audioHelper: AudioPlayerHelper? = nil
    var podcastPlayerHelper: PodcastRowPlayerHelper? = nil
    
    init(message: TransactionMessage? = nil) {
        self.transactionMessage = message
    }
    
    func configureAudioPlayer() {
        if audioHelper == nil {
            audioHelper = AudioPlayerHelper()
        }
        audioHelper?.configureAudioSession()
    }
    
    func configurePodcastPlayer() {
        if podcastPlayerHelper == nil {
            podcastPlayerHelper = PodcastRowPlayerHelper()
        }
    }
    
    func getConsecutiveMessages() -> TransactionMessage.ConsecutiveMessages {
        if self.isPodcastLive {
            return TransactionMessage.ConsecutiveMessages(previousMessage: false, nextMessage: false)
        }
        return self.transactionMessage.consecutiveMessages
    }
    
    func getMessageContent() -> String {
        if let message = transactionMessage, message.getMessageContent() != "" {
            return message.getMessageContent()
        }
        return ""
    }
    
    func getMessageAttributes() -> (String, UIColor, UIFont) {
        let regularBigFont = UIFont.getMessageFont()
        let mediumSmallFont = UIFont.getEncryptionErrorFont()
        
        let messageTextColor = CommonChatTableViewCell.kMessageTextColor
        let encryptionMessageColor = CommonChatTableViewCell.kEncryptionMessageColor
        
        guard let message = transactionMessage else {
            return ("", messageTextColor, regularBigFont)
        }
        
        let messageContent = message.getMessageContent()
        let canDecrypt = canBeDecrypted()
        let messagePendingAttachment = message.isPendingPaidMessage() || message.isLoadingPaidMessage()
        var font = canDecrypt && !messagePendingAttachment ? regularBigFont : mediumSmallFont
        let textColor = canDecrypt ? messageTextColor : encryptionMessageColor
        
        font = isEmojisMessage() ? UIFont.getEmojisFont() : font
        
        return (messageContent, textColor, font)
    }
    
    func isEmojisMessage() -> Bool {
        let messageContent = transactionMessage.getMessageContent()
        return messageContent.length < 4 && messageContent.length > 0 && messageContent.containsOnlyEmoji && transactionMessage.isTextMessage()
    }
    
    func shouldLoadLinkPreview() -> Bool {
        return self.getMessageContent().hasLinks && !isPodcastComment &&
            (transactionMessage.type == TransactionMessage.TransactionMessageType.message.rawValue || transactionMessage.isPaidMessage())
    }
    
    func shouldShowLinkPreview() -> Bool {
        return shouldLoadLinkPreview() && transactionMessage.linkHasPreview
    }
    
    func shouldLoadTribeLinkPreview() -> Bool {
        return self.getMessageContent().hasTribeLinks && !isPodcastComment &&
            (transactionMessage.type == TransactionMessage.TransactionMessageType.message.rawValue || transactionMessage.isPaidMessage())
    }
    
    func shouldShowTribeLinkPreview() -> Bool {
        return shouldLoadTribeLinkPreview() && transactionMessage.linkHasPreview
    }
    
    func shouldLoadPubkeyPreview() -> Bool {
        return self.getMessageContent().hasPubkeyLinks && !isPodcastComment &&
            (transactionMessage.type == TransactionMessage.TransactionMessageType.message.rawValue || transactionMessage.isPaidMessage())
    }
    
    func shouldShowPubkeyPreview() -> Bool {
        return shouldLoadPubkeyPreview()
    }
    
    func isJoinedTribeLink(uuid: String? = nil) -> Bool {
        if let uuid = uuid {
            if let _ = Chat.getChatWith(uuid: uuid) {
                return true
            }
        }
        
        let tribeLink = getMessageContent().stringFirstTribeLink
        if let tribeInfo = GroupsManager.sharedInstance.getGroupInfo(query: tribeLink), let uuid = tribeInfo.uuid, !uuid.isEmpty {
            if let _ = Chat.getChatWith(uuid: uuid) {
                return true
            }
        }
        return false
    }
    
    func isExistingContactPubkey() -> (Bool, UserContact?) {
        return getMessageContent().isExistingContactPubkey()
    }
    
    func getMessageLink() -> String {
        return self.getMessageContent().stringFirstLink
    }
    
    func getStatus() -> Int {
        if let message = transactionMessage {
            let status = message.status
            return status
        }
        return TransactionMessage.TransactionMessageStatus.pending.rawValue
    }
    
    func getMessageId() -> Int? {
        if let message = transactionMessage {
            return message.id
        }
        return nil
    }
    
    func getType() -> Int? {
        if let message = transactionMessage {
            return message.getType()
        }
        return nil
    }
    
    func getAmountString() -> String {
        let amountNumber = self.transactionMessage?.amount ?? NSDecimalNumber(value: 0)
        let amountString = Int(truncating: amountNumber).formattedWithSeparator
        return amountString
    }
    
    func isIncoming() -> Bool {
        if let message = transactionMessage {
            return message.isIncoming()
        }
        return false
    }
    
    func canBeDecrypted() -> Bool {
        return transactionMessage?.canBeDecrypted() ?? false
    }
    
    func isPaymentWithImage() -> Bool {
        return transactionMessage?.isPaymentWithImage() ?? false
    }
    
    func shouldShowPaidAttachmentView() -> Bool {
        if let message = transactionMessage {
            return message.shouldShowPaidAttachmentView()
        }
        return false
    }
    
    func getPodcastComment() -> PodcastComment? {
        transactionMessage?.processPodcastComment()
        return transactionMessage?.podcastComment
    }
    
    var isDayHeader: Bool {
        get {
            return headerDate != nil
        }
    }
    
    var isAttachment: Bool {
        get {
            if let message = transactionMessage {
                return message.isAttachment()
            }
            return false
        }
    }
    
    var isPaidAttachment: Bool {
        get {
            if let message = transactionMessage {
                return message.isPaidAttachment()
            }
            return false
        }
    }
    
    var isMediaAttachment: Bool {
        get {
            if let message = transactionMessage {
                return message.isMediaAttachment()
            }
            return false
        }
    }
    
    var isReply: Bool {
        get {
            if let message = transactionMessage {
                return message.isReply()
            }
            return false
        }
    }
    
    var isPaidSentAttachment: Bool {
        get {
            if let message = transactionMessage {
                return message.isPaidAttachment() && message.isOutgoing()
            }
            return false
        }
    }
    
    var isPaidSentMessage: Bool {
        get {
            if let message = transactionMessage {
                return message.isPaidMessage() && message.isOutgoing()
            }
            return false
        }
    }
    
    var isPendingPaidMessage: Bool {
        get {
            if let message = transactionMessage {
                return message.isPendingPaidMessage()
            }
            return false
        }
    }
    
    var isDirectPayment: Bool {
        get {
            if let message = transactionMessage {
                return message.isDirectPayment()
            }
            return false
        }
    }
    
    var isVideoCallLink: Bool {
        get {
            return (transactionMessage?.messageContent ?? "").isVideoCallLink
        }
    }
    
    var isGiphy: Bool {
        get {
            return (transactionMessage?.isGiphy() ?? false)
        }
    }
    
    var isPodcastComment: Bool {
        get {
            return (transactionMessage?.isPodcastComment() ?? false)
        }
    }
    
    var isPodcastBoost: Bool {
        get {
            return (transactionMessage?.isPodcastBoost() ?? false)
        }
    }
    
    var isFlagged: Bool {
        get {
            return (transactionMessage?.isFlagged() ?? false)
        }
    }
    
    var encrypted: Bool {
        get {
            if let message = transactionMessage {
                return message.encrypted
            }
            return false
        }
    }
    
    var date: Date? {
        get {
            if let message = transactionMessage {
                return message.date
            }
            return nil
        }
    }
    
    var chat: Chat? {
        get {
            if let message = transactionMessage, let chat = message.chat {
                return chat
            }
            return nil
        }
    }
    
    var isBoosted: Bool {
        get {
            return transactionMessage?.isBoosted() ?? false
        }
    }
}
