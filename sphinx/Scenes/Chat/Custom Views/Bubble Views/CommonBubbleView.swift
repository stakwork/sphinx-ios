//
//  Library
//
//  Created by Tomas Timinskas on 27/02/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class CommonBubbleView : UIView {
    
    public static let kBubbleLayerName: String = "bubble-layer"
    public static let kInvoiceDashedLayerName: String = "dashed-line"
    
    public struct ConsecutiveBubbles {
        var previousBubble: Bool
        var nextBubble: Bool
        
        init(previousBubble: Bool, nextBubble: Bool) {
            self.previousBubble = previousBubble
            self.nextBubble = nextBubble
        }
    }
    
    func clearSubview(view: UIView) {
        view.subviews.forEach { $0.removeFromSuperview() }
        view.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }
    
    func clearEmptyBubbleLayer(view: UIView) {
        view.layer.sublayers?.forEach {
            if[CommonBubbleView.kInvoiceDashedLayerName, CommonBubbleView.kBubbleLayerName].contains($0.name) {
                $0.removeFromSuperlayer()
            }
        }
    }
    
    func showIncomingEmptyBubble(contentView: UIView, messageRow: TransactionMessageRow, size: CGSize, consecutiveBubble: ConsecutiveBubbles? = nil, bubbleMargin: CGFloat? = nil) {
        clearEmptyBubbleLayer(view: contentView)

        let consecutiveBubbles = consecutiveBubble ?? ConsecutiveBubbles(previousBubble: false, nextBubble: false)
        let bezierPath = getIncomingBezierPath(size: size, bubbleMargin: bubbleMargin ?? Constants.kBubbleReceivedArrowMargin, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: messageRow.getConsecutiveMessages())

        let layer = CAShapeLayer()
        layer.path = bezierPath.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        layer.fillColor = UIColor.Sphinx.OldReceivedMsgBG.resolvedCGColor(with: contentView)
        layer.strokeColor = UIColor.Sphinx.ReceivedBubbleBorder.resolvedCGColor(with: contentView)
        layer.name = CommonBubbleView.kBubbleLayerName

        addMessageShadow(layer: layer)
        contentView.layer.addSublayer(layer)
    }
    
    func showOutgoingEmptyBubble(contentView: UIView, messageRow: TransactionMessageRow, size: CGSize, consecutiveBubble: ConsecutiveBubbles? = nil, bubbleMargin: CGFloat? = nil, xPosition: CGFloat? = nil) {
        clearEmptyBubbleLayer(view: contentView)

        let consecutiveBubbles = consecutiveBubble ?? ConsecutiveBubbles(previousBubble: false, nextBubble: false)
        let bezierPath = getOutgoingBezierPath(size: size, bubbleMargin: bubbleMargin ?? Constants.kBubbleSentArrowMargin, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: messageRow.getConsecutiveMessages())
        let x = xPosition ?? contentView.frame.width - size.width
        
        let layer = CAShapeLayer()
        layer.path = bezierPath.cgPath
        layer.frame = CGRect(x: x, y: 0, width: size.width, height: size.height)
        layer.fillColor = UIColor.Sphinx.OldSentMsgBG.resolvedCGColor(with: contentView)
        layer.strokeColor = UIColor.Sphinx.SentBubbleBorder.resolvedCGColor(with: contentView)
        layer.name = CommonBubbleView.kBubbleLayerName

        addMessageShadow(layer: layer)
        contentView.layer.addSublayer(layer)
    }
    
    public static func getBubbleMaxWidth(message: TransactionMessage?) -> CGFloat {
        let windowWidth = WindowsManager.getWindowWidth()
        let hasLinks = (message?.getMessageContent().hasLinks ?? false) || (message?.getMessageContent().hasTribeLinks ?? false) || (message?.getMessageContent().hasPubkeyLinks ?? false)
        let incoming = message?.isIncoming() ?? false
        
        var bubbleWidth:CGFloat = 0
        
        if incoming {
            bubbleWidth =  windowWidth - MessageBubbleView.kBubbleReceivedLeftMargin - MessageBubbleView.kBubbleReceivedRightMargin
        } else {
            bubbleWidth = windowWidth - MessageBubbleView.kBubbleSentLeftMargin - MessageBubbleView.kBubbleSentRightMargin
        }
        return min(bubbleWidth, hasLinks ? Constants.kLinkBubbleMaxWidth : Constants.kBubbleMaxWidth)
    }
    
    func getIncomingBezierPath(size: CGSize,
                               bubbleMargin: CGFloat,
                               consecutiveBubbles: ConsecutiveBubbles,
                               consecutiveMessages: TransactionMessage.ConsecutiveMessages) -> UIBezierPath {
        
        let curveSize = Constants.kBubbleCurveSize
        let width = size.width
        let height = size.height
        let halfCurveSize = curveSize/2
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: width - curveSize, y: height))
        bezierPath.addLine(to: CGPoint(x: curveSize + bubbleMargin, y: height))
        
        if consecutiveBubbles.nextBubble || consecutiveMessages.nextMessage {
            bezierPath.addLine(to: CGPoint(x: bubbleMargin, y: height))
            bezierPath.addLine(to: CGPoint(x: bubbleMargin, y: height - curveSize))
        } else {
            bezierPath.addCurve(to: CGPoint(x: bubbleMargin, y: height - curveSize),
                                controlPoint1: CGPoint(x: bubbleMargin + halfCurveSize, y: height),
                                controlPoint2: CGPoint(x: bubbleMargin, y: height - halfCurveSize))
        }
        
        bezierPath.addLine(to: CGPoint(x: bubbleMargin, y: curveSize))
        
        if consecutiveBubbles.previousBubble {
            bezierPath.addLine(to: CGPoint(x: bubbleMargin, y: 0))
            bezierPath.addLine(to: CGPoint(x: width, y: 0))
        } else {
            if consecutiveMessages.previousMessage {
                bezierPath.addLine(to: CGPoint(x: bubbleMargin, y: 0))
            } else {
                bezierPath.addLine(to: CGPoint(x: 0, y: 0))
            }
            bezierPath.addLine(to: CGPoint(x: width - curveSize, y: 0))
            bezierPath.addCurve(to: CGPoint(x: width, y: curveSize),
                                      controlPoint1: CGPoint(x: width - halfCurveSize, y: 0),
                                      controlPoint2: CGPoint(x: width, y: halfCurveSize))
        }
        
        if consecutiveBubbles.nextBubble {
            bezierPath.addLine(to: CGPoint(x: width, y: height))
        } else {
            bezierPath.addLine(to: CGPoint(x: width, y: height - curveSize))
            bezierPath.addCurve(to: CGPoint(x: width - curveSize, y: height),
                                      controlPoint1: CGPoint(x: width, y: height - halfCurveSize),
                                      controlPoint2: CGPoint(x: width - halfCurveSize, y: height))
        }
        
        bezierPath.close()
        return bezierPath
    }
    
    func getOutgoingBezierPath(size: CGSize,
                               bubbleMargin: CGFloat,
                               consecutiveBubbles: ConsecutiveBubbles,
                               consecutiveMessages: TransactionMessage.ConsecutiveMessages) -> UIBezierPath {
        
        let curveSize = Constants.kBubbleCurveSize
        let width = size.width
        let height = size.height
        let halfCurveSize = curveSize/2
        let bezierPath = UIBezierPath()
        
        bezierPath.move(to: CGPoint(x: width - (curveSize + bubbleMargin), y: height))
        
        if consecutiveBubbles.nextBubble {
            bezierPath.addLine(to: CGPoint(x: 0, y: height))
        } else {
            bezierPath.addLine(to: CGPoint(x: curveSize, y: height))
            bezierPath.addCurve(to: CGPoint(x: 0, y: height - curveSize),
                                controlPoint1: CGPoint(x: halfCurveSize, y: height),
                                controlPoint2: CGPoint(x: 0, y: height - halfCurveSize))
        }
        
        if consecutiveBubbles.previousBubble {
            bezierPath.addLine(to: CGPoint(x: 0, y: 0))
            bezierPath.addLine(to: CGPoint(x: width - bubbleMargin, y: 0))
        } else {
            bezierPath.addLine(to: CGPoint(x: 0, y: curveSize))
            bezierPath.addCurve(to: CGPoint(x: curveSize, y: 0),
                                        controlPoint1: CGPoint(x: 0, y: halfCurveSize),
                                        controlPoint2: CGPoint(x: halfCurveSize, y: 0))
            if consecutiveMessages.previousMessage {
                bezierPath.addLine(to: CGPoint(x: width - bubbleMargin, y: 0))
            } else {
                bezierPath.addLine(to: CGPoint(x: width, y: 0))
            }
        }
        
        bezierPath.addLine(to: CGPoint(x: width - bubbleMargin, y: curveSize))
        bezierPath.addLine(to: CGPoint(x: width - bubbleMargin, y: height - curveSize))
        
        if consecutiveBubbles.nextBubble || consecutiveMessages.nextMessage {
            bezierPath.addLine(to: CGPoint(x: width - bubbleMargin, y: height))
            bezierPath.addLine(to: CGPoint(x: width - (curveSize + bubbleMargin), y: height))
        } else {
            bezierPath.addCurve(to: CGPoint(x: width - (curveSize + bubbleMargin), y: height),
                                controlPoint1: CGPoint(x: width - bubbleMargin, y: height - halfCurveSize),
                                controlPoint2: CGPoint(x: width - (halfCurveSize + bubbleMargin), y: height))
        }
        bezierPath.close()
        return bezierPath
    }
    
    func getIncomingInvoiceTopBezierPath(width: CGFloat, height: CGFloat, curveSize: CGFloat, bubbleMargin: CGFloat) -> UIBezierPath {
        let halfCurveSize = curveSize/2
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: width - curveSize, y: height))
        bezierPath.addLine(to: CGPoint(x: curveSize + bubbleMargin, y: height))
        bezierPath.addCurve(to: CGPoint(x: bubbleMargin, y: height - curveSize),
                            controlPoint1: CGPoint(x: bubbleMargin + halfCurveSize, y: height),
                            controlPoint2: CGPoint(x: bubbleMargin, y: height - halfCurveSize))
        bezierPath.addLine(to: CGPoint(x: bubbleMargin, y: curveSize))
        bezierPath.addLine(to: CGPoint(x: 0, y: 0))
        bezierPath.addLine(to: CGPoint(x: width - curveSize, y: 0))
        bezierPath.addCurve(to: CGPoint(x: width, y: curveSize),
                            controlPoint1: CGPoint(x: width - halfCurveSize, y: 0),
                            controlPoint2: CGPoint(x: width, y: halfCurveSize))
        bezierPath.addLine(to: CGPoint(x: width, y: height - curveSize))
        bezierPath.addCurve(to: CGPoint(x: width - curveSize, y: height),
                            controlPoint1: CGPoint(x: width, y: height - halfCurveSize),
                            controlPoint2: CGPoint(x: width - halfCurveSize, y: height))
        bezierPath.close()
        return bezierPath
    }
    
    func getIncomingInvoiceBottomBezierPath(width: CGFloat, height: CGFloat, curveSize: CGFloat, bubbleMargin: CGFloat, rightBubbleMargin: CGFloat,  paid: Bool) -> UIBezierPath {
        let halfCurveSize = curveSize/2
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: width - curveSize, y: height))
        bezierPath.addLine(to: CGPoint(x: curveSize + bubbleMargin, y: height))
        bezierPath.addCurve(to: CGPoint(x: bubbleMargin, y: height - curveSize),
                            controlPoint1: CGPoint(x: bubbleMargin + halfCurveSize, y: height),
                            controlPoint2: CGPoint(x: bubbleMargin, y: height - halfCurveSize))
        bezierPath.addLine(to: CGPoint(x: bubbleMargin, y: curveSize))
        bezierPath.addCurve(to: CGPoint(x: bubbleMargin + curveSize, y: 0),
                            controlPoint1: CGPoint(x: bubbleMargin, y: halfCurveSize),
                            controlPoint2: CGPoint(x: bubbleMargin + halfCurveSize, y: 0))
        bezierPath.addLine(to: CGPoint(x: width - curveSize, y: 0))
        
        if paid {
            bezierPath.addLine(to: CGPoint(x: width + rightBubbleMargin, y: 0))
            bezierPath.addLine(to: CGPoint(x: width, y: curveSize))
        } else {
            bezierPath.addCurve(to: CGPoint(x: width, y: curveSize),
                                controlPoint1: CGPoint(x: width - halfCurveSize, y: 0),
                                controlPoint2: CGPoint(x: width, y: halfCurveSize))
        }
        bezierPath.addLine(to: CGPoint(x: width, y: height - curveSize))
        bezierPath.addCurve(to: CGPoint(x: width - curveSize, y: height),
                            controlPoint1: CGPoint(x: width, y: height - halfCurveSize),
                            controlPoint2: CGPoint(x: width - halfCurveSize, y: height))
        bezierPath.close()
        return bezierPath
    }
    
    func getOutgoingInvoiceTopBezierPath(width: CGFloat, height: CGFloat, curveSize: CGFloat, bubbleMargin: CGFloat, leftBubbleMargin: CGFloat) -> UIBezierPath {
        let halfCurveSize = curveSize/2
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: width - (curveSize + bubbleMargin), y: height))
        bezierPath.addLine(to: CGPoint(x: leftBubbleMargin + curveSize, y: height))
        bezierPath.addCurve(to: CGPoint(x: leftBubbleMargin, y: height - curveSize),
                            controlPoint1: CGPoint(x: leftBubbleMargin + halfCurveSize, y: height),
                            controlPoint2: CGPoint(x: leftBubbleMargin, y: height - halfCurveSize))
        bezierPath.addLine(to: CGPoint(x: leftBubbleMargin, y: curveSize))
        bezierPath.addCurve(to: CGPoint(x: leftBubbleMargin + curveSize, y: 0),
                            controlPoint1: CGPoint(x: leftBubbleMargin, y: halfCurveSize),
                            controlPoint2: CGPoint(x: leftBubbleMargin + halfCurveSize, y: 0))
        bezierPath.addLine(to: CGPoint(x: width, y: 0))
        bezierPath.addLine(to: CGPoint(x: width - bubbleMargin, y: curveSize))
        bezierPath.addLine(to: CGPoint(x: width - bubbleMargin, y: height - curveSize))
        bezierPath.addCurve(to: CGPoint(x: width - (curveSize + bubbleMargin), y: height),
                            controlPoint1: CGPoint(x: width - bubbleMargin, y: height - halfCurveSize),
                            controlPoint2: CGPoint(x: width - (halfCurveSize + bubbleMargin), y: height))
        return bezierPath
    }
    
    func getOutgoingInvoiceBottomBezierPath(width: CGFloat, height: CGFloat, curveSize: CGFloat, bubbleMargin: CGFloat, leftBubbleMargin: CGFloat, paid: Bool) -> UIBezierPath {
        let halfCurveSize = curveSize/2
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: width - (curveSize + bubbleMargin), y: height))
        bezierPath.addLine(to: CGPoint(x: leftBubbleMargin + curveSize, y: height))
        bezierPath.addCurve(to: CGPoint(x: leftBubbleMargin, y: height - curveSize),
                            controlPoint1: CGPoint(x: leftBubbleMargin + halfCurveSize, y: height),
                            controlPoint2: CGPoint(x: leftBubbleMargin, y: height - halfCurveSize))
        bezierPath.addLine(to: CGPoint(x: leftBubbleMargin, y: curveSize))
        if paid {
            bezierPath.addLine(to: CGPoint(x: 0, y: 0))
        } else {
            bezierPath.addCurve(to: CGPoint(x: leftBubbleMargin + curveSize, y: 0),
                                controlPoint1: CGPoint(x: leftBubbleMargin, y: halfCurveSize),
                                controlPoint2: CGPoint(x: leftBubbleMargin + halfCurveSize, y: 0))
        }
        bezierPath.addLine(to: CGPoint(x: width - (curveSize + bubbleMargin), y: 0))
        bezierPath.addCurve(to: CGPoint(x: width - bubbleMargin, y: curveSize),
                            controlPoint1: CGPoint(x: width - (halfCurveSize + bubbleMargin), y: 0),
                            controlPoint2: CGPoint(x: width - bubbleMargin, y: halfCurveSize))
        bezierPath.addLine(to: CGPoint(x: width - bubbleMargin, y: height - curveSize))
        bezierPath.addCurve(to: CGPoint(x: width - (curveSize + bubbleMargin), y: height),
                            controlPoint1: CGPoint(x: width - bubbleMargin, y: height - halfCurveSize),
                            controlPoint2: CGPoint(x: width - (halfCurveSize + bubbleMargin), y: height))
        return bezierPath
    }
    
    func addMessageShadow(layer: CALayer) {
        layer.shadowColor = UIColor.Sphinx.BubbleShadow.resolvedCGColor(with: self)
        layer.shadowOffset = CGSize(width: 0, height: 1.0)
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 1.5
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }
}

