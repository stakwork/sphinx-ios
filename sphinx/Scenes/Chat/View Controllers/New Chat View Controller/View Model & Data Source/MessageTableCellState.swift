//
//  MessageTableCellState.swift
//  sphinx
//
//  Created by Tomas Timinskas on 06/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

struct MessageTableCellState {
    
    //Messages Data
    var message: TransactionMessage? = nil
    var chat: Chat
    var owner: UserContact
    var contact: UserContact? = nil
    var tribeAdmin: UserContact? = nil
    var bubbleState: MessageTableCellState.BubbleState? = nil
    
    //Generic rows Data
    var separatorDate: Date? = nil
    
    init(
        message: TransactionMessage?,
        chat: Chat,
        owner: UserContact,
        contact: UserContact?,
        tribeAdmin: UserContact?,
        separatorDate: Date?,
        bubbleState: MessageTableCellState.BubbleState?
    ) {
        self.message = message
        self.chat = chat
        self.contact = contact
        self.owner = owner
        self.tribeAdmin = tribeAdmin
        self.separatorDate = separatorDate
        self.bubbleState = bubbleState
    }
    
    lazy var bubble: BubbleMessageLayoutState.Bubble? = {
        
        guard let message = message else {
            return nil
        }
        
        guard let bubbleState = self.bubbleState else {
            return nil
        }
        
        var isSent = message.isOutgoing(ownerId: owner.id)
        
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
                alias: contact.nickname ?? "Unknown"
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
    
    
}

extension MessageTableCellState : Hashable {

    static func == (lhs: MessageTableCellState, rhs: MessageTableCellState) -> Bool {
        return
            lhs.message?.id == rhs.message?.id &&
            lhs.message?.status == rhs.message?.status &&
            lhs.bubbleState == rhs.bubbleState
            
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.message?.id)
    }
}

extension MessageTableCellState {
    public enum MessageDirection {
        case Incoming
        case Outgoing
    }
    
    public enum BubbleState {
        case Isolated
        case First
        case Middle
        case Last
    }
}
