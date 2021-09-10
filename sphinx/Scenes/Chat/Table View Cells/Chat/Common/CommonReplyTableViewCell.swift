//
//  CommonMessageTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 11/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class CommonReplyTableViewCell: CommonChatTableViewCell {
    
    var replyBubbleView : MessageBubbleView? = nil
    
    func addReplyBubble(relativeTo view: UIView) {
        if replyBubbleView == nil {
            replyBubbleView = MessageBubbleView()
            replyBubbleView?.isHidden = true
            
            let container = allContentView ?? self.contentView
            container.addSubview(replyBubbleView!)
            
            replyBubbleView!.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint(item: replyBubbleView!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0.0).isActive = true
            NSLayoutConstraint(item: replyBubbleView!, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: 0.0).isActive = true
            NSLayoutConstraint(item: replyBubbleView!, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1.0, constant: 0.0).isActive = true
            NSLayoutConstraint(item: replyBubbleView!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: MessageReplyView.kMessageReplyHeight).isActive = true
            
            replyBubbleView?.superview?.setNeedsLayout()
            replyBubbleView?.superview?.layoutIfNeeded()
        }
    }
    
    func configureReplyBubble(bubbleView: UIView, bubbleSize: CGSize, incoming: Bool) {
        guard let messageRow = messageRow, let message = messageRow.transactionMessage, message.isReply() else {
            replyBubbleView?.isHidden = true
            return
        }
        
        addReplyBubble(relativeTo: bubbleView)
        
        if let replyBubbleView = replyBubbleView {
            let replyingTo = message.getReplyingTo()
            let replySize = CGSize(width: bubbleSize.width, height: MessageReplyView.kMessageReplyHeight)
            var viewFrame: CGRect = CGRect.zero
            let consecutiveBubble = MessageBubbleView.ConsecutiveBubbles(previousBubble: false, nextBubble: true)
            
            if incoming {
                replyBubbleView.showIncomingEmptyBubble(contentView: replyBubbleView.contentView, messageRow: messageRow, size: replySize, consecutiveBubble: consecutiveBubble)
                let leftMargin = Constants.kBubbleReceivedArrowMargin
                viewFrame = CGRect(x: leftMargin, y: 0, width: bubbleSize.width - leftMargin, height: replyBubbleView.frame.height)
            } else {
                replyBubbleView.showOutgoingEmptyBubble(contentView: replyBubbleView.contentView, messageRow: messageRow, size: replySize, consecutiveBubble: consecutiveBubble)
                let rightMargin = Constants.kBubbleSentArrowMargin
                viewFrame = CGRect(x: replyBubbleView.frame.width - bubbleSize.width, y: 0, width: bubbleSize.width - rightMargin, height: replyBubbleView.frame.height)
            }
            
            replyBubbleView.contentView.removeAllSubviews()
            
            let messageReplyView = MessageReplyView(frame: viewFrame)
            messageReplyView.configureForRow(with: replyingTo, isIncoming: incoming, delegate: self)
            replyBubbleView.contentView.addSubview(messageReplyView)
            replyBubbleView.isHidden = false
        }
    }
}

extension CommonReplyTableViewCell : MessageReplyViewDelegate {
    func shouldScrollTo(message: TransactionMessage) {
        delegate?.shouldScrollTo(message: message)
    }
}
