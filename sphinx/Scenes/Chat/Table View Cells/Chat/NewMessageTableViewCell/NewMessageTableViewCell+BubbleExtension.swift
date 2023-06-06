//
//  NewMessageTableViewCell+BubbleExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 06/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewMessageTableViewCell {
    
    func configureWith(
        avatarImage: BubbleMessageLayoutState.AvatarImage?
    ) {
        if let avatarImage = avatarImage {
            chatAvatarView.configureForUserWith(
                color: avatarImage.color,
                alias: avatarImage.alias,
                picture: avatarImage.imageUrl
            )
        } else {
            chatAvatarView.resetView()
        }
    }
    
    func configureWith(
        bubble: BubbleMessageLayoutState.Bubble
    ) {
        configureWith(direction: bubble.direction)
        configureWith(bubbleState: bubble.grouping)
    }
    
    func configureWith(
        direction: MessageTableCellState.MessageDirection
    ) {
        let outgoing = direction == .Outgoing
        
        chatAvatarContainerView.alpha = outgoing ? 0.0 : 1.0
        
        sentMessageMargingView.isHidden = !outgoing
        receivedMessageMarginView.isHidden = outgoing
        
        receivedArrow.isHidden = outgoing
        sentArrow.isHidden = !outgoing
        
        messageLabelLeadingConstraint.priority = UILayoutPriority(outgoing ? 1 : 1000)
        messageLabelTrailingConstraint.priority = UILayoutPriority(outgoing ? 1000 : 1)
        
        let bubbleColor = outgoing ? UIColor.Sphinx.SentMsgBG : UIColor.Sphinx.ReceivedMsgBG
        bubbleOnlyText.backgroundColor = bubbleColor
        bubbleAllView.backgroundColor = bubbleColor
        
        statusHeaderView.configureWith(direction: direction)
    }
    
    func configureWith(
        bubbleState: MessageTableCellState.BubbleState
    ) {
        switch (bubbleState) {
        case .Isolated:
            chatAvatarContainerView.isHidden = false
            statusHeaderViewContainer.isHidden = false
            
            receivedArrow.alpha = 1.0
            sentArrow.alpha = 1.0
            break
        case .First:
            chatAvatarContainerView.isHidden = false
            statusHeaderViewContainer.isHidden = false
            
            receivedArrow.alpha = 1.0
            sentArrow.alpha = 1.0
            break
        case .Middle:
            chatAvatarContainerView.isHidden = true
            statusHeaderViewContainer.isHidden = true
            
            receivedArrow.alpha = 0.0
            sentArrow.alpha = 0.0
            break
        case .Last:
            chatAvatarContainerView.isHidden = true
            statusHeaderViewContainer.isHidden = true
            
            receivedArrow.alpha = 0.0
            sentArrow.alpha = 0.0
            break
        }
    }
}
