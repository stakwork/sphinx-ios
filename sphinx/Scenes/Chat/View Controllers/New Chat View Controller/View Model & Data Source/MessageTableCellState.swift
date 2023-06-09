//
//  MessageTableCellState.swift
//  sphinx
//
//  Created by Tomas Timinskas on 06/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

struct MessageTableCellState {
    
    ///Constants
    static let kBubbleCornerRadius: CGFloat = 8.0
    static let kRowLeftMargin: CGFloat = 15
    static let kRowRightMargin: CGFloat = 9
    static let kBubbleWidthPercentage: CGFloat = 0.7
    static let kSmallBubbleDesiredWidth: CGFloat = 200
    static let kSendPaidContentButtonHeight: CGFloat = 50.0
    
    //Messages Data
    var message: TransactionMessage? = nil
    var chat: Chat
    var owner: UserContact
    var contact: UserContact? = nil
    var tribeAdmin: UserContact? = nil
    var bubbleState: MessageTableCellState.BubbleState? = nil
    var contactImage: UIImage? = nil
    var replyingMessage: TransactionMessage? = nil
    var boostMessages: [TransactionMessage] = []
    var linkContact: (String, UserContact?)? = nil
    
    //Generic rows Data
    var separatorDate: Date? = nil
    
    init(
        message: TransactionMessage? = nil,
        chat: Chat,
        owner: UserContact,
        contact: UserContact?,
        tribeAdmin: UserContact?,
        separatorDate: Date?,
        bubbleState: MessageTableCellState.BubbleState? = nil,
        contactImage: UIImage? = nil,
        replyingMessage: TransactionMessage? = nil,
        boostMessages: [TransactionMessage] = [],
        linkContact: (String, UserContact?)? = nil
    ) {
        self.message = message
        self.chat = chat
        self.contact = contact
        self.owner = owner
        self.tribeAdmin = tribeAdmin
        self.separatorDate = separatorDate
        self.bubbleState = bubbleState
        self.contactImage = contactImage
        self.replyingMessage = replyingMessage
        self.boostMessages = boostMessages
        self.linkContact = linkContact
    }
    
    ///Bubble States
    lazy var bubble: BubbleMessageLayoutState.Bubble? = {
        
        guard let message = message, let bubbleState = self.bubbleState else {
            return nil
        }
        
        let isSent = message.isOutgoing(ownerId: owner.id)
        
        return BubbleMessageLayoutState.Bubble(
            direction: isSent ? .Outgoing : .Incoming,
            grouping: bubbleState
        )
    }()
    
    lazy var avatarImage: BubbleMessageLayoutState.AvatarImage? = {
        
        guard let message = message else {
            return nil
        }
        
        if chat.isPublicGroup() {
            return BubbleMessageLayoutState.AvatarImage(
                imageUrl: message.senderPic,
                color: ChatHelper.getSenderColorFor(message: message),
                alias: message.senderAlias ?? "Unknown"
            )
        } else if let contact = contact {
            return BubbleMessageLayoutState.AvatarImage(
                imageUrl: contact.avatarUrl,
                color: contact.getColor(),
                alias: contact.nickname ?? "Unknown",
                image: contactImage
            )
        }
        
        return nil
    }()
    
    lazy var statusHeader: BubbleMessageLayoutState.StatusHeader? = {
        
        guard let message = message else {
            return nil
        }
        
        var isSent = message.isOutgoing(ownerId: owner.id)
        
        var statusHeader = BubbleMessageLayoutState.StatusHeader(
            senderName: (chat.isConversation() ? nil : message.senderAlias),
            color: ChatHelper.getSenderColorFor(message: message),
            showSent: isSent,
            showSendingIcon: isSent && message.pending() && message.isProvisional(),
            showBoltIcon: isSent && message.isConfirmedAsReceived(),
            showFailedContainer: isSent && message.failed(),
            showLockIcon: true,
            timestamp: (message.date ?? Date()).getStringDate(format: "hh:mm a")
        )
        
        return statusHeader
    }()
    
    lazy var messageReply: BubbleMessageLayoutState.MessageReply? = {
        
        guard let message = message, let replyingMessage = replyingMessage else {
            return nil
        }
        
        let senderInfo: (UIColor, String, String?) = getSenderInfo(message: replyingMessage)
        
        return BubbleMessageLayoutState.MessageReply(
            messageId: replyingMessage.id,
            color: senderInfo.0,
            alias: senderInfo.1,
            message: replyingMessage.bubbleMessageContentString,
            mediaType: replyingMessage.getMediaType()
        )
    }()
    
    lazy var messageContent: BubbleMessageLayoutState.MessageContent? = {
        guard let message = message else {
            return nil
        }
        
        if let messageContent = message.bubbleMessageContentString, messageContent.isNotEmpty {
            var message = BubbleMessageLayoutState.MessageContent(
                text: messageContent,
                font: message.bubbleMessageContentFont
            )
            
            return message
        } else {
            return nil
        }
    }()
    
    lazy var directPayment: BubbleMessageLayoutState.DirectPayment? = {
        guard let message = message, message.isDirectPayment() else {
            return nil
        }
        
        return BubbleMessageLayoutState.DirectPayment(
            amount: message.amount?.intValue ?? 0,
            isTribePmt: chat.isPublicGroup(),
            recipientPic: message.recipientPic,
            recipientAlias: message.recipientAlias,
            recipientColor: ChatHelper.getRecipientColorFor(message: message)
        )
    }()
    
    lazy var callLink: BubbleMessageLayoutState.CallLink? = {
        guard let message = message, message.isCallLink() else {
            return nil
        }
        
        if let link = message.messageContent, link.isNotEmpty {
            return BubbleMessageLayoutState.CallLink(
                link: link,
                callMode: VideoCallHelper.getCallMode(link: link)
            )
        }
        
        return nil
    }()
    
    lazy var boosts: BubbleMessageLayoutState.Boosts? = {
        
        guard let message = message, boostMessages.count > 0 else {
            return nil
        }
        
        var boosts: [BubbleMessageLayoutState.Boost] = []
        var boostedByMe = false
        var totalAmount = 0

        for boostMessage in boostMessages {
            let senderInfo: (UIColor, String, String?) = getSenderInfo(message: boostMessage)

            totalAmount += boostMessage.amount?.intValue ?? 0

            boosts.append(
                BubbleMessageLayoutState.Boost(
                    amount: boostMessage.amount?.intValue ?? 0,
                    senderPic: senderInfo.2,
                    senderAlias: senderInfo.1,
                    senderColor: senderInfo.0
                )
            )
            
            if !boostedByMe {
                boostedByMe = boostMessage.senderId == owner.id
            }
        }
        
        return BubbleMessageLayoutState.Boosts(
            boosts: boosts,
            totalAmount: totalAmount,
            boostedByMe: boostedByMe
        )
    }()
    
    lazy var podcastBoost: BubbleMessageLayoutState.PodcastBoost? = {
        guard let message = message, message.isPodcastBoost() else {
            return nil
        }
        
        guard let amount = message.amount?.intValue, amount > 0 else {
            return nil
        }
        
        return BubbleMessageLayoutState.PodcastBoost(amount: amount)
    }()
    
    lazy var contactLink: BubbleMessageLayoutState.ContactLink? = {
        guard let linkContact = linkContact else {
            return nil
        }
        
        return BubbleMessageLayoutState.ContactLink(
            pubkey: linkContact.0,
            imageUrl: linkContact.1?.avatarUrl,
            alias: linkContact.1?.nickname,
            color: linkContact.1?.getColor(),
            isContact: linkContact.1 != nil,
            bubbleWidth: (UIScreen.main.bounds.width - (MessageTableCellState.kRowLeftMargin + MessageTableCellState.kRowRightMargin)) * (MessageTableCellState.kBubbleWidthPercentage),
            roundedBottom: false
        )
    }()
    
    
    ///No Bubble States
    lazy var noBubble: NoBubbleMessageLayoutState.NoBubble? = {
        
        guard let message = message, bubbleState == nil else {
            return nil
        }
        
        let isSent = message.isOutgoing(ownerId: owner.id)
        
        return NoBubbleMessageLayoutState.NoBubble(
            direction: isSent ? .Outgoing : .Incoming
        )
    }()
    
    lazy var deleted: NoBubbleMessageLayoutState.Deleted? = {
        
        guard let message = message, message.isDeleted() else {
            return nil
        }
        
        return NoBubbleMessageLayoutState.Deleted(
            timestamp: (message.date ?? Date()).getStringDate(format: "hh:mm a")
        )
    }()
    
    lazy var dateSeparator: NoBubbleMessageLayoutState.DateSeparator? = {
        
        guard let separatorDate = separatorDate else {
            return nil
        }
        
        let (shouldShowMonth, shouldShowYear) = separatorDate.shouldShowMonthAndYear()
        var timestamp = ""
        
        if separatorDate.isToday() {
            timestamp = "today".localized
        } else if shouldShowMonth && shouldShowYear {
            timestamp = separatorDate.getStringDate(format: "EEEE MMMM dd, yyyy")
        } else if shouldShowMonth {
            timestamp = separatorDate.getStringDate(format: "EEEE MMMM dd")
        } else {
            timestamp = separatorDate.getStringDate(format: "EEEE dd")
        }
        
        return NoBubbleMessageLayoutState.DateSeparator(
            timestamp: timestamp
        )
    }()
    
    var isTextOnlyMessage: Bool {
        mutating get {
            return (self.messageContent != nil) &&
                (self.messageContent?.text?.hasPubkeyLinks == false) &&
                (self.messageReply == nil) &&
                (self.callLink == nil) &&
                (self.directPayment == nil) &&
                (self.boosts == nil)
        }
    }
}

extension MessageTableCellState {
    func getSenderInfo(
        message: TransactionMessage
    ) -> (UIColor, String, String?) {
        
        var senderInfo: (UIColor, String, String?) = (
            UIColor.Sphinx.SecondaryText,
            "Unknow",
            nil
        )
        
        let isSent = message.isOutgoing(ownerId: owner.id)
        
        if isSent {
            senderInfo = (
                owner.getColor(),
                owner.nickname ?? "Unknow",
                owner.avatarUrl
            )
        } else if chat.isPublicGroup() {
            senderInfo = (
                ChatHelper.getSenderColorFor(message: message),
                message.senderAlias ?? "Unknow",
                message.senderPic
            )
        } else if let contact = contact {
            senderInfo = (
                contact.getColor(),
                contact.nickname ?? "Unknow",
                contact.avatarUrl
            )
        }
        
        return senderInfo
    }
}

extension MessageTableCellState : Hashable {

    static func == (lhs: MessageTableCellState, rhs: MessageTableCellState) -> Bool {
        var mutableLhs = lhs
        var mutableRhs = rhs
        
        return
            mutableLhs.message?.id           == mutableRhs.message?.id &&
            mutableLhs.message?.status       == mutableRhs.message?.status &&
            mutableLhs.bubbleState           == mutableRhs.bubbleState &&
            mutableLhs.boostMessages.count   == mutableRhs.boostMessages.count &&
            mutableLhs.isTextOnlyMessage     == mutableRhs.isTextOnlyMessage &&
            mutableLhs.separatorDate         == mutableRhs.separatorDate &&
            mutableLhs.linkContact?.0        == mutableRhs.linkContact?.0
            
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.message?.id)
    }
}

extension MessageTableCellState {
    public enum MessageDirection {
        case Incoming
        case Outgoing
        
        func isIncoming() -> Bool {
            return self == MessageDirection.Incoming
        }
        
        func isOutgoing() -> Bool {
            return self == MessageDirection.Outgoing
        }
    }
    
    public enum BubbleState {
        case Isolated
        case First
        case Middle
        case Last
    }
}
