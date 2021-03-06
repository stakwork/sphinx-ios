//
//  MessageOptionsView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 13/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

@objc protocol MessageOptionsDelegate: class {
    func shouldDismiss()
    func shouldDeleteMessage()
    func shouldReplayToMessage()
    func shouldSaveFile()
    func shouldBoostMessage()
}

class MessageOptionsView : UIView {
    
    weak var delegate: MessageOptionsDelegate?
    
    let menuOptionsWidth:CGFloat = 140
    let optionsHeight:CGFloat = 40
    let iconWidth:CGFloat = 40
    let menuVerticalMargin: CGFloat = 10
    
    var message: TransactionMessage? = nil
    
    public enum VerticalPosition: Int {
        case Top
        case Bottom
    }
    
    public enum HorizontalPosition: Int {
        case Center
        case Right
        case Left
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(message: TransactionMessage?, leftTopCorner: CGPoint, rightBottomCorner: CGPoint, delegate: MessageOptionsDelegate) {
        super.init(frame: CGRect.zero)
        
        self.delegate = delegate
        self.message = message
        
        guard let message = message else {
            return
        }
        
        let incoming = message.isIncoming()
        let coordinates = getCoordinates(leftTopCorner: leftTopCorner, rightBottomCorner: rightBottomCorner)
        let messageOptions = getActionsMenuOptions()
        let optionsCount = messageOptions.count

        let (menuRect, verticalPosition, horizontalPosition) = getMenuRectAndPosition(coordinates: coordinates, optionsCount: optionsCount, incoming: incoming)
        self.frame = menuRect
        
        let backColor = incoming ? UIColor.Sphinx.OldReceivedMsgBG : UIColor.Sphinx.OldSentMsgBG
        addBackLayer(frame: menuRect, backColor: backColor, verticalPosition: verticalPosition, horizontalPosition: horizontalPosition)
        addMenuOptions(options: messageOptions)
    }
    
    func getCoordinates(leftTopCorner: CGPoint, rightBottomCorner: CGPoint) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        return (leftTopCorner.x, rightBottomCorner.x, leftTopCorner.y, rightBottomCorner.y)
    }
    
    func getMenuRectAndPosition(coordinates: (x1: CGFloat, x2: CGFloat, y1: CGFloat, y2: CGFloat), optionsCount: Int, incoming: Bool) -> (CGRect, VerticalPosition, HorizontalPosition) {
        let screenSize = WindowsManager.getWindowSize()
        let margin: CGFloat = incoming ? 4 : 6
        
        let newX1 = incoming ? coordinates.x1 + margin : coordinates.x1
        let newX2 = incoming ? coordinates.x2 : coordinates.x2 - margin
        
        let menuOptionsHeight:CGFloat = CGFloat(optionsCount) * optionsHeight + (menuVerticalMargin * 2)
        
        var horizontalPosition = HorizontalPosition.Center
        var centerX = newX1 + ((newX2 - newX1) / 2) - (menuOptionsWidth / 2)
        var y:CGFloat = 0
        
        if (centerX < 0) {
            horizontalPosition = HorizontalPosition.Left
            centerX = 15
        } else if (centerX + menuOptionsWidth > screenSize.width - 15) {
            horizontalPosition = HorizontalPosition.Right
            centerX = (screenSize.width - menuOptionsWidth - 15)
        }
        
        var verticalPosition = VerticalPosition.Top
        
        if screenSize.height - coordinates.y2 > coordinates.y1 && !KeyboardHandlerViewController.keyboardVisible {
            y = coordinates.y2
            verticalPosition = VerticalPosition.Bottom
        } else {
            y = coordinates.y1 - menuOptionsHeight
            verticalPosition = VerticalPosition.Top
        }
        
        let menuRect = CGRect(x: centerX, y: y, width: menuOptionsWidth, height: menuOptionsHeight)
        return (menuRect, verticalPosition, horizontalPosition)
    }
    
    func getActionsMenuOptions() -> [(tag: TransactionMessage.MessageActionsItem, icon: String?, iconImage: String?, label: String)] {
        guard let message = message else {
            return []
        }
        return message.getActionsMenuOptions()
    }
    
    func addMenuOptions(options: [(tag: TransactionMessage.MessageActionsItem, icon: String?, iconImage: String?, label: String)]) {
        var index = 0
        for (tag, icon, iconImage, label) in options {
            let y = menuVerticalMargin + CGFloat(index) * optionsHeight
            
            let shouldShowSeparator = index < options.count - 1
            let optionView = MessageOptionView(frame: CGRect(x: 0, y: y, width: self.frame.size.width, height: optionsHeight))
            
            let color = getColorFor(tag)
            let option = MessageOptionView.Option(icon: icon, iconImage: iconImage, title: label, tag: tag.rawValue, color: color, showLine: shouldShowSeparator)
            optionView.configure(option: option, delegate: self)
            
            self.addSubview(optionView)
            
            index = index + 1
        }
    }
    
    func getColorFor(_ tag: TransactionMessage.MessageActionsItem) -> UIColor {
        switch(tag) {
        case .Delete:
            return UIColor.Sphinx.BadgeRed
        default:
            return UIColor.Sphinx.Text
        }
    }
    
    func addBackLayer(frame: CGRect, backColor: UIColor, verticalPosition: VerticalPosition, horizontalPosition: HorizontalPosition) {
        let layerFrame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        let menuBubbleLayer = CAShapeLayer()
        menuBubbleLayer.path = getMenuBubblePath(rect: layerFrame, verticalPosition: verticalPosition, horizontalPosition: horizontalPosition).cgPath
        menuBubbleLayer.frame = layerFrame
        menuBubbleLayer.fillColor = backColor.resolvedCGColor(with: self)
        menuBubbleLayer.strokeColor = UIColor.Sphinx.MessageOptionDivider.resolvedCGColor(with: self)
        
        self.layer.addSublayer(menuBubbleLayer)
    }
    
    func getMenuBubblePath(rect: CGRect, verticalPosition: VerticalPosition, horizontalPosition: HorizontalPosition) -> UIBezierPath {
        let curveSize: CGFloat = 3
        let halfCurveSize = curveSize/2
        
        let width = rect.size.width
        let height = rect.size.height - menuVerticalMargin
        let adjustedY = menuVerticalMargin
        
        var arrowPosition = width / 2
        if horizontalPosition == .Left {
            arrowPosition = width / 4
        } else if horizontalPosition == .Right {
            arrowPosition = width / 4 * 3
        }
        
        let arrowWidth: CGFloat = 8
        let halfArrowWidth = arrowWidth / 2
        let arrowHeight: CGFloat = 5
        
        let bezierPath = UIBezierPath()
        
        bezierPath.move(to: CGPoint(x: width - curveSize, y: height))
        if verticalPosition == .Top {
            bezierPath.addLine(to: CGPoint(x: arrowPosition + halfArrowWidth, y: height))
            bezierPath.addLine(to: CGPoint(x: arrowPosition, y: height + arrowHeight))
            bezierPath.addLine(to: CGPoint(x: arrowPosition - halfArrowWidth, y: height))
            
        }
        bezierPath.addLine(to: CGPoint(x: curveSize, y: height))
        bezierPath.addCurve(to: CGPoint(x: 0, y: height - curveSize),
                            controlPoint1: CGPoint(x: halfCurveSize, y: height),
                            controlPoint2: CGPoint(x: 0, y: height - halfCurveSize))
        
        bezierPath.addLine(to: CGPoint(x: 0, y: curveSize + adjustedY))
        bezierPath.addCurve(to: CGPoint(x: curveSize, y: adjustedY),
                                    controlPoint1: CGPoint(x: 0, y: adjustedY + halfCurveSize),
                                    controlPoint2: CGPoint(x: halfCurveSize, y: adjustedY))
        if verticalPosition == .Bottom {
            bezierPath.addLine(to: CGPoint(x: arrowPosition - halfArrowWidth, y: adjustedY))
            bezierPath.addLine(to: CGPoint(x: arrowPosition, y: adjustedY - arrowHeight))
            bezierPath.addLine(to: CGPoint(x: arrowPosition + halfArrowWidth, y: adjustedY))
        }
        bezierPath.addLine(to: CGPoint(x: width - curveSize, y: adjustedY))
        bezierPath.addCurve(to: CGPoint(x: width, y: adjustedY + curveSize),
                            controlPoint1: CGPoint(x: width - halfCurveSize, y: adjustedY),
                            controlPoint2: CGPoint(x: width, y: adjustedY + halfCurveSize))

        bezierPath.addLine(to: CGPoint(x: width, y: height - curveSize))
        bezierPath.addCurve(to: CGPoint(x: width - curveSize, y: height),
                            controlPoint1: CGPoint(x: width, y: height - halfCurveSize),
                            controlPoint2: CGPoint(x: width - halfCurveSize, y: height))
        
        bezierPath.close()
        return bezierPath
    }
}

extension MessageOptionsView : MessageOptionViewDelegate {
    func didTapButton(tag: Int) {
        guard let message = message else {
            return
        }
        
        let option = TransactionMessage.MessageActionsItem(rawValue: tag)
        
        switch(option) {
        case .Copy:
            ClipboardHelper.copyToClipboard(text: message.getMessageContent(), message: "text.copied.clipboard".localized)
            break
        case .CopyLink:
            ClipboardHelper.copyToClipboard(text: message.messageContent?.stringFirstLink ?? "", message: "link.copied.clipboard".localized)
            break
        case .CopyPubKey:
            ClipboardHelper.copyToClipboard(text: message.messageContent?.stringFirstPubKey ?? "", message: "pub.key.copied.clipboard".localized)
            break
        case .CopyCallLink:
            ClipboardHelper.copyToClipboard(text: message.messageContent ?? "", message: "call.link.copied.clipboard".localized)
            break
        case .Delete:
            delegate?.shouldDeleteMessage()
            break
        case .Reply:
            delegate?.shouldReplayToMessage()
            break
        case .Save:
            delegate?.shouldSaveFile()
            break
        case .Boost:
            delegate?.shouldBoostMessage()
            break
        default:
            break
        }
        delegate?.shouldDismiss()
    }
}
