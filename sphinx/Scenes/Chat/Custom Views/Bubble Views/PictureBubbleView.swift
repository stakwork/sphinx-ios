//
//  PictureBubbleView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 29/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import SDWebImageFLPlugin

class PictureBubbleView: CommonBubbleView {
    
    @IBOutlet private var contentView: UIView!
    
    public static let kImageLayer = "image-layer"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("PictureBubbleView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func clearBubbleView() {
        clearSubview(view: contentView)
    }
    
    func getBubbleColors(messageRow: TransactionMessageRow) -> (CGColor, CGColor) {
        if messageRow.isIncoming() {
            return (UIColor.Sphinx.OldReceivedMsgBG.resolvedCGColor(with: self), UIColor.Sphinx.ReceivedBubbleBorder.resolvedCGColor(with: self))
        } else {
            return (UIColor.Sphinx.OldSentMsgBG.resolvedCGColor(with: self), UIColor.Sphinx.SentBubbleBorder.resolvedCGColor(with: self))
        }
    }
    
    func showIncomingPictureBubble(messageRow: TransactionMessageRow,
                                   size: CGSize,
                                   image: UIImage? = nil,
                                   gifData: Data? = nil,
                                   contentMode: CALayerContentsGravity = .resizeAspectFill) {
        
        clearSubview(view: contentView)
        
        let bubbleColors = getBubbleColors(messageRow: messageRow)

        let bezierPath = getIncomingBezierPath(size: size,
                                               bubbleMargin: Constants.kBubbleReceivedArrowMargin,
                                               consecutiveBubbles: getConsecutiveBubble(messageRow: messageRow),
                                               consecutiveMessages: messageRow.transactionMessage.consecutiveMessages)
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        let layer = CAShapeLayer()
        layer.path = bezierPath.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        layer.fillColor = bubbleColors.0
        layer.strokeColor = bubbleColors.1
        layer.name = CommonBubbleView.kBubbleLayerName

        addMessageShadow(layer: layer)
        contentView.layer.addSublayer(layer)
        
        let imageOrGifAvailable = image != nil || gifData != nil
        
        guard imageOrGifAvailable else {
            if messageRow.transactionMessage.isPaidAttachment() {
                let placeholderName = messageRow.transactionMessage.isVideo() ?
                    "paidVideoBlurredPlaceholder"
                    : "paidImageBlurredPlaceholder"
                
                addStaticImageInBubble(
                    image: UIImage(named: placeholderName),
                    frame: rect,
                    path: bezierPath,
                    contentMode: contentMode,
                    strokeColor: bubbleColors.1
                )
            }
            return
        }
        
        addStaticImageInBubble(
            image: image,
            gifData: gifData,
            frame: rect,
            path: bezierPath,
            contentMode: contentMode,
            strokeColor: bubbleColors.1
        )
        
        if messageRow.transactionMessage.isVideo() {
            addVideoLayerBubble(frame: rect, path: bezierPath)
        }
    }
    
    func showOutgoingPictureBubble(messageRow: TransactionMessageRow,
                                   size: CGSize,
                                   image: UIImage? = nil,
                                   gifData: Data? = nil,
                                   contentMode: CALayerContentsGravity = .resizeAspectFill) {
        
        clearSubview(view: contentView)

        let bubbleColors = getBubbleColors(messageRow: messageRow)
        
        let bezierPath = getOutgoingBezierPath(size: size,
                                               bubbleMargin: 6,
                                               consecutiveBubbles: getConsecutiveBubble(messageRow: messageRow),
                                               consecutiveMessages: messageRow.transactionMessage.consecutiveMessages)
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let layer = CAShapeLayer()
        layer.path = bezierPath.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        layer.fillColor = bubbleColors.0
        layer.strokeColor = bubbleColors.1
        layer.name = CommonBubbleView.kBubbleLayerName
        
        addMessageShadow(layer: layer)
        contentView.layer.addSublayer(layer)
        
        let imageOrGifAvailable = image != nil || gifData != nil
        
        if imageOrGifAvailable {
            addStaticImageInBubble(image: image, gifData: gifData, frame: rect, path: bezierPath, contentMode: contentMode, strokeColor: bubbleColors.1)
            
            if messageRow.transactionMessage.isVideo() {
                addVideoLayerBubble(frame: rect, path: bezierPath)
            }
        }
    }
    
    func getConsecutiveBubble(messageRow: TransactionMessageRow) -> ConsecutiveBubbles {
        let isDirectPayment = messageRow.isDirectPayment
        let isBoosted = messageRow.isBoosted
        let isReply = messageRow.isReply
        let isPaidAttachment = messageRow.isPaidAttachment
        let attachmentHasText = messageRow.transactionMessage.hasMessageContent() && !isDirectPayment
        
        if messageRow.isIncoming() {
            return ConsecutiveBubbles(previousBubble: isDirectPayment || isReply, nextBubble: attachmentHasText || isPaidAttachment || isBoosted)
        } else {
            return ConsecutiveBubbles(previousBubble: isDirectPayment || isReply, nextBubble: attachmentHasText || isBoosted)
        }
    }
    
    func addAnimatedImageInBubble(data: Data) {
        if let animation = data.createGIFAnimation(), let layer = self.getImageLayer() {
            layer.contents = nil
            layer.add(animation, forKey: "contents")
        }
    }
    
    func addStaticImageInBubble(image: UIImage? = nil, gifData: Data? = nil, frame: CGRect, path: UIBezierPath, contentMode: CALayerContentsGravity = .resizeAspectFill, strokeColor: CGColor) {
        addImageInBubble(image: image?.cgImage, gifData: gifData, frame: frame, path: path, contentMode: contentMode, strokeColor: strokeColor)
    }
    
    func addImageInBubble(image: CGImage? = nil, gifData: Data? = nil, frame: CGRect, path: UIBezierPath, contentMode: CALayerContentsGravity = .resizeAspectFill, strokeColor: CGColor) {
        let imageLayer = CAShapeLayer()
        imageLayer.contentsGravity = contentMode
        imageLayer.frame = frame
        imageLayer.strokeColor = strokeColor
        imageLayer.name = PictureBubbleView.kImageLayer
        
        if let gifData = gifData, let animation = gifData.createGIFAnimation() {
            imageLayer.contents = nil
            imageLayer.add(animation, forKey: "contents")
        } else if let image = image {
            imageLayer.contents = image
            imageLayer.removeAllAnimations()
        }

        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        imageLayer.mask = maskLayer
        
        addMessageShadow(layer: imageLayer)
        contentView.layer.addSublayer(imageLayer)
    }
    
    func getImageLayer() -> CAShapeLayer? {
        for layer in contentView.layer.sublayers ?? []  {
            if layer.name == PictureBubbleView.kImageLayer {
                if let layer = layer as? CAShapeLayer {
                    return layer
                }
            }
        }
        return nil
    }
    
    func addVideoLayerBubble(frame: CGRect, path: UIBezierPath) {
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.frame = frame

        layer.fillColor = UIColor.black.withAlphaComponent(0.5).resolvedCGColor(with: self)
        
        contentView.layer.addSublayer(layer)
    }
}

