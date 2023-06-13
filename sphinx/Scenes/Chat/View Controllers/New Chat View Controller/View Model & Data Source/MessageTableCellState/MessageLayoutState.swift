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
        
        init(
            text: String?,
            font: UIFont
        ) {
            self.text = text
            self.font = font
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
        var image: UIImage?
        var gifData: Data?
        var fileInfo: MessageTableCellState.FileInfo?
        var loading: Bool
        var failed: Bool
        var isImage: Bool
        var isVideo: Bool
        var isGif: Bool
        var isPdf: Bool
        var isPaid: Bool
        
        init(
            url: URL?,
            image: UIImage?,
            gifData: Data?,
            fileInfo: MessageTableCellState.FileInfo?,
            loading: Bool,
            failed: Bool,
            isImage: Bool,
            isVideo: Bool,
            isGif: Bool,
            isPdf: Bool,
            isPaid: Bool
        ) {
            self.url = url
            self.image = image
            self.gifData = gifData
            self.fileInfo = fileInfo
            self.loading = loading
            self.failed = failed
            self.isImage = isImage
            self.isVideo = isVideo
            self.isGif = isGif
            self.isPdf = isPdf
            self.isPaid = isPaid
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
        var tribeLinkLoaded: TribeLinkLoaded? = nil
        
        init(
            link: String,
            tribeLinkLoaded: TribeLinkLoaded? = nil
        ) {
            self.link = link
            self.tribeLinkLoaded = tribeLinkLoaded
        }
    }
    
    struct TribeLinkLoaded {
        var name: String
        var description: String
        var imageUrl: String?
        var showJoinButton: Bool
        var bubbleWidth: CGFloat
        var roundedBottom: Bool
        
        init(
            name: String,
            description: String,
            imageUrl: String?,
            showJoinButton: Bool,
            bubbleWidth: CGFloat,
            roundedBottom: Bool
        ) {
            self.name = name
            self.description = description
            self.imageUrl = imageUrl
            self.showJoinButton = showJoinButton
            self.bubbleWidth = bubbleWidth
            self.roundedBottom = roundedBottom
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


