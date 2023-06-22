//
//  NewOnlyTextMessageTableViewCell+MessageTypesExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewOnlyTextMessageTableViewCell {
    func configureWith(
        statusHeader: BubbleMessageLayoutState.StatusHeader?
    ) {
        if let statusHeader = statusHeader {
            statusHeaderView.configureWith(statusHeader: statusHeader, uploadProgressData: nil)
        }
    }
    
    func configureWith(
        messageContent: BubbleMessageLayoutState.MessageContent?
    ) {
        urlRanges = []
        
        if let messageContent = messageContent {
            if messageContent.linkMatches.isEmpty {
                messageLabel.attributedText = nil
                
                messageLabel.text = messageContent.text
                messageLabel.font = messageContent.font
            } else {
                let messageC = messageContent.text ?? ""
                let attributedString = NSMutableAttributedString(string: messageC)
                attributedString.addAttributes([NSAttributedString.Key.font: messageContent.font], range: messageC.nsRange)
                
                for match in messageContent.linkMatches {
                    
                    attributedString.setAttributes(
                        [
                            NSAttributedString.Key.foregroundColor: UIColor.Sphinx.PrimaryBlue,
                            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
                            NSAttributedString.Key.font: messageContent.font
                        ],
                        range: match.range
                    )
                    
                    urlRanges.append(match.range)
                }
                
                messageLabel.attributedText = attributedString
                messageLabel.isUserInteractionEnabled = true
            }
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(labelTapped(gesture:)))
        
        if urlRanges.isEmpty {
            messageLabel.removeGestureRecognizer(tap)
        } else {
            messageLabel.addGestureRecognizer(tap)
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
        bubble: BubbleMessageLayoutState.Bubble
    ) {
        configureWith(direction: bubble.direction)
        configureWith(bubbleState: bubble.grouping, direction: bubble.direction)
    }
    
    func configureWith(
        direction: MessageTableCellState.MessageDirection
    ) {
        let isOutgoing = direction.isOutgoing()
        
        sentMessageMargingView.isHidden = !isOutgoing
        receivedMessageMarginView.isHidden = isOutgoing
        
        receivedArrow.isHidden = isOutgoing
        sentArrow.isHidden = !isOutgoing
        
        messageLabelLeadingConstraint.priority = UILayoutPriority(isOutgoing ? 1 : 1000)
        messageLabelTrailingConstraint.priority = UILayoutPriority(isOutgoing ? 1000 : 1)
        
        let bubbleColor = isOutgoing ? UIColor.Sphinx.SentMsgBG : UIColor.Sphinx.ReceivedMsgBG
        bubbleOnlyText.backgroundColor = bubbleColor
        
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
        }
    }
}
