//
//  NewMessageTableViewCell+BubbleExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 06/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewMessageTableViewCell {
    
    func configureSwipeWith(
        swipeReply: BubbleMessageLayoutState.SwipeReply?
    ) {
        if let _ = swipeReply {
            isSwipeAllowed = true
        } else {
            isSwipeAllowed = false
        }
    }
    
    func configureWidthWith(
        messageCellState: MessageTableCellState
    ) {
        var mutableMessageCellState = messageCellState
        
        let isPodcastComment = mutableMessageCellState.podcastComment != nil
        let isPodcastBoost = mutableMessageCellState.podcastBoost != nil
        let isEmptyDirectPayment = mutableMessageCellState.directPayment != nil &&
                                   mutableMessageCellState.messageContent == nil
        
        let defaultWith = ((UIScreen.main.bounds.width - (MessageTableCellState.kRowLeftMargin + MessageTableCellState.kRowRightMargin)) * MessageTableCellState.kBubbleWidthPercentage)
        
        if isPodcastBoost || isEmptyDirectPayment {
            let widthDifference = defaultWith - MessageTableCellState.kSmallBubbleDesiredWidth
            
            bubbleWidthConstraint.constant = -(widthDifference)
        } else if isPodcastComment {
            let widthDiference = (defaultWith / 7 * 8.5) - defaultWith
            
            bubbleWidthConstraint.constant = widthDiference
        } else {
            bubbleWidthConstraint.constant = 0
        }
    }
    
    func configureWith(
        avatarImage: BubbleMessageLayoutState.AvatarImage?
    ) {
        if let avatarImage = avatarImage {
            chatAvatarView.configureForUserWith(
                color: avatarImage.color,
                alias: avatarImage.alias,
                picture: avatarImage.imageUrl,
                image: avatarImage.image,
                and: self
            )
        } else {
            chatAvatarView.resetView()
        }
    }
    
    func configureWith(
        bubble: BubbleMessageLayoutState.Bubble,
        threadMessages: BubbleMessageLayoutState.ThreadMessages?
    ) {
        configureWith(direction: bubble.direction, threadMessages: threadMessages)
        configureWith(bubbleState: bubble.grouping, direction: bubble.direction)
    }
    
    func configureWith(
        direction: MessageTableCellState.MessageDirection,
        threadMessages: BubbleMessageLayoutState.ThreadMessages?
    ) {
        let isOutgoing = direction.isOutgoing()
        let isThread = threadMessages != nil
        let textRightAligned = isOutgoing && bubbleAllView.isHidden
        
        sentMessageMargingView.isHidden = !isOutgoing
        receivedMessageMarginView.isHidden = isOutgoing
        
        receivedArrow.isHidden = isOutgoing
        receivedArrow.setArrowColorTo(
            color: isThread ? UIColor.Sphinx.ThreadOriginalMsg : UIColor.Sphinx.ReceivedMsgBG
        )
        
        sentArrow.isHidden = !isOutgoing
        sentArrow.setArrowColorTo(
            color: isThread ? UIColor.Sphinx.SentMsgBG : UIColor.Sphinx.SentMsgBG
        )
        
        messageLabelLeadingConstraint.priority = UILayoutPriority(textRightAligned ? 1 : 1000)
        messageLabelTrailingConstraint.priority = UILayoutPriority(textRightAligned ? 1000 : 1)
        
        let bubbleColor = isOutgoing ? UIColor.Sphinx.SentMsgBG : UIColor.Sphinx.ReceivedMsgBG
        let threadBubbleColor = isOutgoing ? UIColor.Sphinx.ReceivedMsgBG : UIColor.Sphinx.ThreadLastReply
        
        bubbleAllView.backgroundColor = isThread ? threadBubbleColor : bubbleColor
        
        statusHeaderView.configureWith(direction: direction)
    }
    
    func configureWith(
        bubbleState: MessageTableCellState.BubbleState,
        direction: MessageTableCellState.MessageDirection
    ) {
        let outgoing = direction == .Outgoing
        
        switch (bubbleState) {
        case .Isolated:
            chatAvatarContainerView.alpha = outgoing ? 0.0 : 1.0
            statusHeaderViewContainer.isHidden = false
            
            receivedArrow.alpha = 1.0
            sentArrow.alpha = 1.0
            break
        case .First:
            chatAvatarContainerView.alpha = outgoing ? 0.0 : 1.0
            statusHeaderViewContainer.isHidden = false
            
            receivedArrow.alpha = 1.0
            sentArrow.alpha = 1.0
            break
        case .Middle:
            chatAvatarContainerView.alpha = 0.0
            statusHeaderViewContainer.isHidden = true
            
            receivedArrow.alpha = 0.0
            sentArrow.alpha = 0.0
            break
        case .Last:
            chatAvatarContainerView.alpha = 0.0
            statusHeaderViewContainer.isHidden = true
            
            receivedArrow.alpha = 0.0
            sentArrow.alpha = 0.0
            break
        case .Empty:
            chatAvatarContainerView.alpha = outgoing ? 0.0 : 1.0
            statusHeaderViewContainer.isHidden = false
            bubbleAllView.backgroundColor = UIColor.clear
            
            receivedArrow.alpha = 0.0
            sentArrow.alpha = 0.0
            break
        }
    }
    
    func configureWith(
        invoiceLines: BubbleMessageLayoutState.InvoiceLines
    ) {
        switch (invoiceLines.linesState) {
        case .None:
            leftLineContainer.isHidden = true
            rightLineContainer.isHidden = true
            break
        case .Left:
            leftLineContainer.isHidden = false
            rightLineContainer.isHidden = true
            break
        case .Right:
            leftLineContainer.isHidden = true
            rightLineContainer.isHidden = false
            break
        case .Both:
            leftLineContainer.isHidden = false
            rightLineContainer.isHidden = false
            break
        }
    }
}
