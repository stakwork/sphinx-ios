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
    
}

struct NoBubbleMessageLayoutState: CommonLayoutState {
    
    struct DateSeparator {
        
        var date: Date
        
        init(
            date: Date
        ) {
            self.date = date
        }
    }
}


