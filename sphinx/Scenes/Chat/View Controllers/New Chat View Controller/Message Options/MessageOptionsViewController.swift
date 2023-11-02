//
//  MessageOptionsViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 10/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

@objc protocol MessageOptionsVCDelegate: class {
    func shouldDeleteMessage(message: TransactionMessage)
    func shouldReplyToMessage(message: TransactionMessage)
    func shouldBoostMessage(message: TransactionMessage)
    func shouldResendMessage(message: TransactionMessage)
    func shouldFlagMessage(message: TransactionMessage)
    func shouldShowThreadFor(message:TransactionMessage)
    func shouldTogglePinState(message: TransactionMessage, pin: Bool)
    func shouldReloadChat()
    func shouldToggleReadUnread(chat: Chat)
}

class MessageOptionsViewController: UIViewController {
    
    weak var delegate: MessageOptionsVCDelegate?
    
    var bubbleShapeLayers: [(CGRect, CAShapeLayer)] = [(CGRect, CAShapeLayer)]()
    var bubblePath: (CGRect, CGPath)? = nil
    
    var message: TransactionMessage? = nil
    var chat: Chat? = nil
    
    var purchaseAcceptMessage: TransactionMessage? = nil
    
    var isThreadRow: Bool = false
    
    static func instantiate(
        message: TransactionMessage?,
        chat: Chat?,
        purchaseAcceptMessage: TransactionMessage?,
        delegate: MessageOptionsVCDelegate?,
        isThreadRow: Bool
    ) -> MessageOptionsViewController {
        
        let viewController = StoryboardScene.Chat.messageOptionsViewController.instantiate()
        viewController.message = message
        viewController.chat = chat
        viewController.purchaseAcceptMessage = purchaseAcceptMessage
        viewController.delegate = delegate
        viewController.isThreadRow = isThreadRow
        
        return viewController
    }
    
    func setBubbleShapesData(bubbleShapeLayers: [(CGRect, CAShapeLayer)]) {
        self.bubbleShapeLayers = bubbleShapeLayers
    }
    
    func setBubblePath(bubblePath: (CGRect, CGPath)) {
        self.bubblePath = bubblePath
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        SoundsPlayer.playHaptic()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.view.addGestureRecognizer(tap)
        
        highlightMessage()
    }
    
    func highlightMessage() {
        let windowSize = WindowsManager.getWindowSize()
        let entireView = UIView(frame: CGRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height))
        let entireViewPath = UIBezierPath(rect: entireView.frame)

        var leftTopCorner = CGPoint(x: 0, y: 0)
        var rightBottomCorner = CGPoint(x: 0, y: 0)
        
        func saveRectPosition(bubbleRect: CGRect) {
            leftTopCorner.x = (leftTopCorner.x == 0) ? bubbleRect.origin.x : min(leftTopCorner.x, bubbleRect.origin.x)
            
            leftTopCorner.y = (leftTopCorner.y == 0) ? bubbleRect.origin.y : min(leftTopCorner.y, bubbleRect.origin.y)
            
            let newX2 = bubbleRect.origin.x + bubbleRect.size.width
            rightBottomCorner.x = (rightBottomCorner.x == 0) ? newX2 : max(rightBottomCorner.x, newX2)
            
            let newY2 = bubbleRect.origin.y + bubbleRect.size.height
            rightBottomCorner.y = (rightBottomCorner.y == 0) ? newY2 : max(rightBottomCorner.y, newY2)
        }
        
        if let bubblePath = bubblePath {
            let rectangleMessageRect = CGRect(x: bubblePath.0.origin.x,
                                              y: bubblePath.0.origin.y,
                                              width: bubblePath.0.width,
                                              height: bubblePath.0.height)
            
            saveRectPosition(bubbleRect: rectangleMessageRect)
            
            let messageViewPath = UIBezierPath(cgPath: bubblePath.1)
            messageViewPath.apply(CGAffineTransform(translationX: rectangleMessageRect.origin.x, y: rectangleMessageRect.origin.y))
            
            entireViewPath.append(messageViewPath)
        } else {
            for (rect, layer) in bubbleShapeLayers {
                let messageShapeLayer = layer
                let containerFrame = rect
                
                if let path = messageShapeLayer.path {
                    let rectangleMessageRect = CGRect(x: messageShapeLayer.frame.origin.x + containerFrame.origin.x,
                                                      y: messageShapeLayer.frame.origin.y + containerFrame.origin.y,
                                                      width: messageShapeLayer.frame.width,
                                                      height: messageShapeLayer.frame.height)
                    
                    saveRectPosition(bubbleRect: rectangleMessageRect)
                    
                    let messageViewPath = UIBezierPath(cgPath: path)
                    messageViewPath.apply(CGAffineTransform(translationX: rectangleMessageRect.origin.x, y: rectangleMessageRect.origin.y))
                    
                    entireViewPath.append(messageViewPath)
                }
            }
        }
        
        entireViewPath.usesEvenOddFillRule = true
        
        let entireViewLayer = CAShapeLayer()
        entireViewLayer.path = entireViewPath.cgPath
        entireViewLayer.fillRule = .evenOdd
        entireViewLayer.fillColor = UIColor.black.resolvedCGColor(with: self.view)
        entireView.layer.addSublayer(entireViewLayer)
        
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.mask = entireView
        view.addSubview(blurEffectView)
        
        addMenuView(leftTopCorner: leftTopCorner, rightBottomCorner: rightBottomCorner)
    }
    
    func addMessageBubbleBorder(messageViewPath: UIBezierPath) {
        let windowSize = WindowsManager.getWindowSize()
        let messagesView = UIView(frame: CGRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height))
        let messageLayer = CAShapeLayer()
        messageLayer.path = messageViewPath.cgPath
        messageLayer.fillRule = .evenOdd
        messageLayer.fillColor = UIColor.clear.resolvedCGColor(with: self.view)
        messageLayer.strokeColor = UIColor.Sphinx.MessageOptionDivider.resolvedCGColor(with: self.view)
        messagesView.layer.addSublayer(messageLayer)
        view.addSubview(messagesView)
    }
    
    func addMenuView(
        leftTopCorner: CGPoint,
        rightBottomCorner: CGPoint
    ) {
        let menuView = MessageOptionsView(
            message: message,
            chat: chat,
            leftTopCorner: leftTopCorner,
            rightBottomCorner: rightBottomCorner,
            isThreadRow: isThreadRow,
            delegate: self
        )
        self.view.addSubview(menuView)
    }
    
    func addMessageShadow(layer: CALayer) {
        layer.shadowColor = UIColor.white.resolvedCGColor(with: self.view)
        layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 3.0
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }

    @objc func viewTapped() {
        shouldDismissViewController()
    }
    
    func shouldDismissViewController(_ completion: (() -> ())? = nil) {
        SoundsPlayer.playHaptic()
        
        self.dismiss(animated: false, completion: {
            self.delegate?.shouldReloadChat()
            
            completion?()
        })
    }
}

extension MessageOptionsViewController : MessageOptionsDelegate {
    func shouldDismiss(completion: @escaping (() -> ())) {
        shouldDismissViewController(completion)
    }
    
    func shouldReplyToMessage() {
        if let message = message {
            delegate?.shouldReplyToMessage(message: message)
        }
    }
    
    func shouldDeleteMessage() {
        if let message = message {
            delegate?.shouldDeleteMessage(message: message)
        }
    }
    
    func shouldBoostMessage() {
        if let message = message {
            delegate?.shouldBoostMessage(message: message)
        }
    }
    
    func shouldSaveFile() {
        MediaDownloader.shouldSaveFile(
            message: message,
            purchaseAcceptMessage: purchaseAcceptMessage,
            completion: { success, alertMessage in
                self.showMediaSaveAlert(
                    success: success,
                    
                    alertMessage: alertMessage)
            }
        )
    }
    
    func shouldResendMessage() {
        if let message = message {
            delegate?.shouldResendMessage(message: message)
        }
    }
    
    func shouldFlagMessage() {
        if let message = message {
            delegate?.shouldFlagMessage(message: message)
        }
    }
    
    func shouldTogglePinState(pin: Bool) {
        if let message = message {
            delegate?.shouldTogglePinState(message: message, pin: pin)
        }
    }
    
    func showMediaSaveAlert(success: Bool, alertMessage: String) {
        DispatchQueue.main.async {
            NewMessageBubbleHelper().showGenericMessageView(text: alertMessage)
        }
    }
    
    func shouldShowThread() {
        if let message = message {
            delegate?.shouldShowThreadFor(message: message)
        }
    }
    
    //Unused Methods
    func shouldToggleReadUnread(chat: Chat) {
        delegate?.shouldToggleReadUnread(chat: chat)
    }
    
}
