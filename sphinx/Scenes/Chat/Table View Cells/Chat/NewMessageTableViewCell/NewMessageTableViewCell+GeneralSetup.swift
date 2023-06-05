//
//  NewMessageTableViewCell+GeneralSetup.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewMessageTableViewCell {
    func setupViews() {
        bubbleOnlyText.layer.cornerRadius = 8.0
        bubbleAllView.layer.cornerRadius = 8.0
        
        paidAttachmentView.roundCorners(
            corners: [.bottomLeft, .bottomRight],
            radius: 8.0,
            viewBounds: CGRect(
                origin: CGPoint.zero,
                size: CGSize(
                    width: (UIScreen.main.bounds.width - 24.0) * 0.7,
                    height: 50.0
                )
            )
        )
        
        receivedArrow.drawReceivedBubbleArrow(color: UIColor.Sphinx.ReceivedMsgBG)
        sentArrow.drawSentBubbleArrow(color: UIColor.Sphinx.SentMsgBG)
        
        messageLabel.font = Constants.kMessageFont
    }
    
    func configureFor(
        direction: MessageDirection
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
        
        statusHeaderView.configureFor(direction: direction)
    }
    
    func configureFor(groupingState: GroupingState) {
        switch (groupingState) {
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
