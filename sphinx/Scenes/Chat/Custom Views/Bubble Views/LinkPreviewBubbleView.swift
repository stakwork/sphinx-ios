//
//  LinkPreviewBubbleView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 04/12/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import UIKit

class LinkPreviewBubbleView : CommonBubbleView {
    
    func addConstraintsTo(bubbleView: UIView, messageRow: TransactionMessageRow) {
        let leftMargin = messageRow.isIncoming() ? Constants.kBubbleReceivedArrowMargin : 0
        let height = CommonChatTableViewCell.getLinkPreviewHeight(messageRow: messageRow) - Constants.kBubbleBottomMargin
        let width = getViewWidth(messageRow: messageRow)
        
        for c in  self.constraints {
            self.removeConstraint(c)
        }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bubbleView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bubbleView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: leftMargin).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: height).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: width).isActive = true
    }
    
    func getViewWidth(messageRow: TransactionMessageRow) -> CGFloat {
        let isIncoming = messageRow.isIncoming()
        let leftMargin = isIncoming ? Constants.kBubbleReceivedArrowMargin : 0
        let rightMargin = isIncoming ? 0 : Constants.kBubbleSentArrowMargin
        
        return CommonBubbleView.getBubbleMaxWidth(message: messageRow.transactionMessage) - rightMargin - leftMargin
    }
    
    func showIncomingLinkBubble(contentView: UIView, messageRow: TransactionMessageRow, size: CGSize, consecutiveBubble: ConsecutiveBubbles? = nil, bubbleMargin: CGFloat? = nil, existingObject: Bool) {
        if existingObject {
            showIncomingEmptyBubble(contentView: contentView, messageRow: messageRow, size: size, consecutiveBubble: consecutiveBubble, bubbleMargin: bubbleMargin)
        } else {
            clearEmptyBubbleLayer(view: contentView)
            
            let consecutiveBubbles = consecutiveBubble ?? ConsecutiveBubbles(previousBubble: false, nextBubble: false)
            let bezierPath = getIncomingBezierPath(size: size, bubbleMargin: bubbleMargin ?? Constants.kBubbleReceivedArrowMargin, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: messageRow.getConsecutiveMessages())
            
            let color = messageRow.isIncoming() ? UIColor.Sphinx.LinkReceivedColor : UIColor.Sphinx.LinkSentColor
            let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            
            addDashedLineBorder(contentView: contentView, frame: frame, color: color, bezierPath: bezierPath)
        }
    }
    
    func showOutgoingLinkBubble(contentView: UIView, messageRow: TransactionMessageRow, size: CGSize, consecutiveBubble: ConsecutiveBubbles? = nil, bubbleMargin: CGFloat? = nil, existingObject: Bool) {
        if existingObject {
            showOutgoingEmptyBubble(contentView: contentView, messageRow: messageRow, size: size, consecutiveBubble: consecutiveBubble, bubbleMargin: bubbleMargin, xPosition: 0)
        } else {
            clearEmptyBubbleLayer(view: contentView)
            
            let consecutiveBubbles = consecutiveBubble ?? ConsecutiveBubbles(previousBubble: false, nextBubble: false)
            let bezierPath = getOutgoingBezierPath(size: size, bubbleMargin: bubbleMargin ?? Constants.kBubbleSentArrowMargin, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: messageRow.getConsecutiveMessages())
            
            let color = messageRow.isIncoming() ? UIColor.Sphinx.LinkReceivedColor : UIColor.Sphinx.LinkSentColor
            let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            
            addDashedLineBorder(contentView: contentView, frame: frame, color: color, bezierPath: bezierPath)
        }
    }
    
    func addDashedLineBorder(contentView: UIView, frame: CGRect, color: UIColor, bezierPath: UIBezierPath) {
        let shapeLayer:CAShapeLayer = CAShapeLayer()
        shapeLayer.path = bezierPath.cgPath
        shapeLayer.frame = frame
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color.resolvedCGColor(with: contentView)
        shapeLayer.lineWidth = 1.5
        shapeLayer.lineJoin = .round
        shapeLayer.lineDashPattern = [8,4]
        shapeLayer.name = CommonBubbleView.kInvoiceDashedLayerName
        
        contentView.layer.addSublayer(shapeLayer)
    }
}
