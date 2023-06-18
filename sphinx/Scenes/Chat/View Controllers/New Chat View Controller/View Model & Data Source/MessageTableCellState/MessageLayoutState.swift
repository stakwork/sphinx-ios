//
//  MessageLayoutState.swift
//  sphinx
//
//  Created by Tomas Timinskas on 06/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol CommonLayoutState {
    
}

struct BubbleMessageLayoutState: CommonLayoutState {
    
    struct Bubble {
        var direction: MessageTableCellState.MessageDirection
        var grouping: MessageTableCellState.BubbleState
        
        init(
            direction: MessageTableCellState.MessageDirection,
            grouping: MessageTableCellState.BubbleState
        ) {
            self.direction = direction
            self.grouping = grouping
        }
    }
    
    struct AvatarImage {
        var imageUrl: String?
        var color: UIColor
        var alias: String
        var image: UIImage?
        
        init(
            imageUrl: String?,
            color: UIColor,
            alias: String,
            image: UIImage? = nil
        ) {
            self.imageUrl = imageUrl
            self.color = color
            self.alias = alias
            self.image = image
        }
    }
    
    struct StatusHeader {
        var senderName: String?
        var color: UIColor?
        var showSent: Bool
        var showSendingIcon: Bool
        var showBoltIcon: Bool
        var showFailedContainer: Bool
        var showLockIcon: Bool
        var timestamp: String
        
        init(
            senderName: String?,
            color: UIColor?,
            showSent: Bool,
            showSendingIcon: Bool,
            showBoltIcon: Bool,
            showFailedContainer: Bool,
            showLockIcon: Bool,
            timestamp: String
        ) {
            self.senderName = senderName
            self.color = color
            self.showSent = showSent
            self.showSendingIcon = showSendingIcon
            self.showBoltIcon = showBoltIcon
            self.showFailedContainer = showFailedContainer
            self.showLockIcon = showLockIcon
            self.timestamp = timestamp
        }
    }
    
    struct MessageReply {
        var messageId: Int
        var color: UIColor
        var alias: String
        var message: String?
        var mediaType: Int?
        
        init(
            messageId: Int,
            color: UIColor,
            alias: String,
            message: String?,
            mediaType: Int?
        ) {
            self.messageId = messageId
            self.color = color
            self.alias = alias
            self.message = message
            self.mediaType = mediaType
        }
    }
    
    struct MessageContent {
        var text: String?
        var font: UIFont
        var linkMatches: [NSTextCheckingResult]
        
        init(
            text: String?,
            font: UIFont,
            linkMatches: [NSTextCheckingResult]
        ) {
            self.text = text
            self.font = font
            self.linkMatches = linkMatches
        }
    }
    
    struct DirectPayment {
        var amount: Int
        var isTribePmt: Bool
        
        var recipientPic: String?
        var recipientAlias: String?
        var recipientColor: UIColor?
        
        init(
            amount: Int,
            isTribePmt: Bool,
            recipientPic: String?,
            recipientAlias: String?,
            recipientColor: UIColor?
        ) {
            self.amount = amount
            self.isTribePmt = isTribePmt
            self.recipientPic = recipientPic
            self.recipientAlias = recipientAlias
            self.recipientColor = recipientColor
        }
    }
    
    struct CallLink {
        var link: String
        var callMode: VideoCallHelper.CallMode
        
        init(
            link: String,
            callMode: VideoCallHelper.CallMode
        ) {
            self.link = link
            self.callMode = callMode
        }
    }
    
    struct MessageMedia {
        var url: URL?
        var isImage: Bool
        var isVideo: Bool
        var isGif: Bool
        var isPdf: Bool
        var isPaid: Bool
        var isPaymentTemplate: Bool
        
        init(
            url: URL?,
            isImage: Bool,
            isVideo: Bool,
            isGif: Bool,
            isPdf: Bool,
            isPaid: Bool,
            isPaymentTemplate: Bool
        ) {
            self.url = url
            self.isImage = isImage
            self.isVideo = isVideo
            self.isGif = isGif
            self.isPdf = isPdf
            self.isPaid = isPaid
            self.isPaymentTemplate = isPaymentTemplate
        }
    }
    
    struct Boosts {
        var boosts: [Boost]
        var totalAmount: Int
        var boostedByMe: Bool
        
        init(
            boosts: [Boost],
            totalAmount: Int,
            boostedByMe: Bool
        ) {
            self.boosts = boosts
            self.totalAmount = totalAmount
            self.boostedByMe = boostedByMe
        }
    }
    
    struct Boost {
        var amount: Int
        var senderPic: String?
        var senderAlias: String?
        var senderColor: UIColor?
        
        init(
            amount: Int,
            senderPic: String?,
            senderAlias: String?,
            senderColor: UIColor?
        ) {
            self.amount = amount
            self.senderPic = senderPic
            self.senderAlias = senderAlias
            self.senderColor = senderColor
        }
    }
    
    struct PodcastBoost {
        var amount: Int
        
        init(
            amount: Int
        ) {
            self.amount = amount
        }
    }
    
    struct ContactLink {
        var pubkey: String
        var imageUrl: String?
        var alias: String?
        var color: UIColor?
        var isContact: Bool
        var bubbleWidth: CGFloat
        var roundedBottom: Bool
        
        init(
            pubkey: String,
            imageUrl: String?,
            alias: String?,
            color: UIColor?,
            isContact: Bool,
            bubbleWidth: CGFloat,
            roundedBottom: Bool
        ) {
            self.pubkey = pubkey
            self.imageUrl = imageUrl
            self.alias = alias
            self.color = color
            self.isContact = isContact
            self.bubbleWidth = bubbleWidth
            self.roundedBottom = roundedBottom
        }
    }
    
    struct TribeLink {
        var link: String
        
        init(
            link: String
        ) {
            self.link = link
        }
    }
}

struct NoBubbleMessageLayoutState: CommonLayoutState {
    
    struct NoBubble {
        var direction: MessageTableCellState.MessageDirection
        
        init(
            direction: MessageTableCellState.MessageDirection
        ) {
            self.direction = direction
        }
    }
    
    struct GroupMemberNotification {
        
        var message: String
        
        init(
            message: String
        ) {
            self.message = message
        }
    }
    
    struct GroupKickRemovedOrDeclined {
        var message: String
        
        init(
            message: String
        ) {
            self.message = message
        }
    }
    
    struct GroupMemberRequest {
        var status: MemberRequestStatus
        var isActiveMember: Bool
        var senderAlias: String
        
        enum MemberRequestStatus: Int {
            case Pending = 19
            case Approved = 20
            case Rejected = 21
        }
        
        init(
            status: MemberRequestStatus,
            isActiveMember: Bool,
            senderAlias: String
        ) {
            self.status = status
            self.isActiveMember = isActiveMember
            self.senderAlias = senderAlias
        }
    }
    
    struct DateSeparator {
        
        var timestamp: String
        
        init(
            timestamp: String
        ) {
            self.timestamp = timestamp
        }
    }
    
    struct Deleted {
        var timestamp: String
        
        init(
            timestamp: String
        ) {
            self.timestamp = timestamp
        }
    }
}


