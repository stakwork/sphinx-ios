//
//  Library
//
//  Created by Tomas Timinskas on 26/02/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class MessageBubbleView: CommonBubbleView {
    
    public static let kBubbleSentLeftMargin: CGFloat = 90
    public static let kBubbleSentRightMargin: CGFloat = 9
    public static let kBubbleReceivedLeftMargin: CGFloat = 56
    public static let kBubbleReceivedRightMargin: CGFloat = 45
    public static let kBubbleAttachmentMinimumWidht: CGFloat = 211
    public static let kMessageLabelTag : Int = 123
    
    @IBOutlet var contentView: UIView!
    
    var messageRow: TransactionMessageRow? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("MessageBubbleView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func getSubviews() -> [UIView] {
        if let contentView = contentView {
            return contentView.subviews
        }
        return []
    }
    
    func clearBubbleView() {
        clearSubview(view: contentView)
    }
    
    public static func getLabelMargin(messageRow: TransactionMessageRow) -> CGFloat {
        return messageRow.isEmojisMessage() ? Constants.kEmojisLabelMargins : Constants.kLabelMargins
    }
    
    public static func getLabelAttributes(messageRow: TransactionMessageRow, maxBubbleWidth: CGFloat, bubbleMargin: CGFloat, labelMargin: CGFloat = Constants.kLabelMargins, textColorAndFont: (String, UIColor, UIFont)) -> (UILabel, CGSize, CGFloat) {
        let label =  UILabel()
        label.numberOfLines = 0
        label.text = textColorAndFont.0
        label.textColor = textColorAndFont.1
        label.font = textColorAndFont.2
        
        let (labelSize, bubbleSize) = getLabelAndBubbleSize(messageRow: messageRow, maxBubbleWidth: maxBubbleWidth, bubbleMargin: bubbleMargin, labelMargin: labelMargin)
        label.frame.size = labelSize
        
        return (label, bubbleSize, bubbleMargin)
    }
    
    public static func getLabelAndBubbleSize(messageRow: TransactionMessageRow, maxBubbleWidth: CGFloat, bubbleMargin: CGFloat = Constants.kBubbleSentArrowMargin, labelMargin: CGFloat = Constants.kLabelMargins) -> (CGSize, CGSize) {
        
        let labelAttributes = messageRow.getMessageAttributes()
        let constraintRect = CGSize(width: maxBubbleWidth - (labelMargin * 2) - bubbleMargin, height: .greatestFiniteMagnitude)
        
        let boundingBox = labelAttributes.0.boundingRect(with: constraintRect,
                                                         options: .usesLineFragmentOrigin,
                                                         attributes: [.font: labelAttributes.2],
                                                         context: nil)
        
        var labelSize = CGSize(width: ceil(boundingBox.width),
                               height: ceil(boundingBox.height))
        
        if labelAttributes.0.isEmpty {
            labelSize = CGSize.zero
        }
        
        
        let bottomBubblePadding = messageRow.isBoosted ? Constants.kReactionsViewHeight : 0
        let bubbleHeight = (labelSize.height > 0) ? labelSize.height + (labelMargin * 2) + bottomBubblePadding : bottomBubblePadding + labelMargin
        
        let bubbleSize = CGSize(width: labelSize.width + (labelMargin * 2) + bubbleMargin,
                                height: bubbleHeight)
        
        return (labelSize, bubbleSize)
    }
    
    func getBubbleColors(messageRow: TransactionMessageRow, incoming: Bool) -> (CGColor, CGColor) {
        let canBeDecrypted = messageRow.canBeDecrypted()
        
        if incoming {
            return canBeDecrypted ? (UIColor.Sphinx.OldReceivedMsgBG.resolvedCGColor(with: self), UIColor.Sphinx.ReceivedBubbleBorder.resolvedCGColor(with: self)) : (UIColor.Sphinx.OldReceivedMsgBG.resolvedCGColor(with: self), UIColor.Sphinx.SecondaryRed.resolvedCGColor(with: self))
        } else {
            return (UIColor.Sphinx.OldSentMsgBG.resolvedCGColor(with: self), UIColor.Sphinx.SentBubbleBorder.resolvedCGColor(with: self))
        }
    }
    
    func getBubbleSize(messageRow: TransactionMessageRow, bubbleSize: CGSize, fixedWidth: CGFloat? = nil, minimumWidth: CGFloat) -> CGSize {
        var bubbleWidth =  fixedWidth ?? bubbleSize.width
        bubbleWidth = (minimumWidth > bubbleWidth) ? minimumWidth : bubbleWidth
        
        let topPadding: CGFloat = messageRow.isPaidSentMessage ? Constants.kPaidMessageTopPadding : 0
        let linkPreviewHeight = CommonChatTableViewCell.getBubbleLinkPreviewHeight(messageRow: messageRow)
        let bubbleHeight = bubbleSize.height + linkPreviewHeight
        let size = CGSize(width: bubbleWidth, height: bubbleHeight + topPadding)
        
        return size
    }
    
    func showIncomingMessageBubble(messageRow: TransactionMessageRow, minimumWidth: CGFloat = 0.0) -> (UILabel, CGSize) {
        let hasLinks = (messageRow.shouldShowLinkPreview() || messageRow.shouldShowTribeLinkPreview() || messageRow.shouldShowPubkeyPreview())
        let fixedWidth: CGFloat? = hasLinks ? CommonBubbleView.getBubbleMaxWidth(message: messageRow.transactionMessage) : nil
        return showIncomingMessageBubble(messageRow: messageRow, fixedBubbleWidth: fixedWidth, minimumWidth: minimumWidth)
    }
    
    func showIncomingMessageBubble(messageRow: TransactionMessageRow, fixedBubbleWidth: CGFloat?, minimumWidth: CGFloat = 0.0) -> (UILabel, CGSize) {
        self.messageRow = messageRow
        
        clearBubbleView()

        let bubbleMaxWidth = fixedBubbleWidth ?? CommonBubbleView.getBubbleMaxWidth(message: messageRow.transactionMessage)
        let textColorAndFont = messageRow.getMessageAttributes()
        let bubbleColors = getBubbleColors(messageRow: messageRow, incoming: true)
        
        let labelMargin = MessageBubbleView.getLabelMargin(messageRow: messageRow)
        let (label, bubbleEstimatedSize, bubbleMargin) = MessageBubbleView.getLabelAttributes(messageRow: messageRow,
                                                                                              maxBubbleWidth: bubbleMaxWidth,
                                                                                              bubbleMargin: Constants.kBubbleReceivedArrowMargin,
                                                                                              labelMargin: labelMargin,
                                                                                              textColorAndFont: textColorAndFont)
        
        let bubbleSize = getBubbleSize(messageRow: messageRow,
                                       bubbleSize: bubbleEstimatedSize,
                                       fixedWidth: fixedBubbleWidth,
                                       minimumWidth: minimumWidth)
        
        let messageBezierPath = getIncomingBezierPath(size: bubbleSize,
                                                      bubbleMargin: bubbleMargin,
                                                      consecutiveBubbles: getConsecutiveBubble(messageRow: messageRow),
                                                      consecutiveMessages: messageRow.getConsecutiveMessages())

        let comingMessageLayer = CAShapeLayer()
        comingMessageLayer.path = messageBezierPath.cgPath
        comingMessageLayer.frame = CGRect(x: 0,
                                          y: 0,
                                          width: bubbleSize.width,
                                          height: bubbleSize.height)
        
        comingMessageLayer.fillColor = bubbleColors.0
        comingMessageLayer.strokeColor = bubbleColors.1
        comingMessageLayer.lineWidth = 1
        comingMessageLayer.name = CommonBubbleView.kBubbleLayerName

        label.frame.origin = CGPoint(x: Constants.kBubbleReceivedArrowMargin + labelMargin, y: labelMargin)

        addMessageShadow(layer: comingMessageLayer)
        contentView.layer.addSublayer(comingMessageLayer)
        contentView.addSubview(label)
        
        return (label, bubbleSize)
    }
    
    func showOutgoingMessageBubble(messageRow: TransactionMessageRow, minimumWidth: CGFloat = 0.0) -> (UILabel, CGSize) {
        let hasLinks = (messageRow.shouldShowLinkPreview() || messageRow.shouldShowTribeLinkPreview() || messageRow.shouldShowPubkeyPreview())
        let fixedWidth: CGFloat? = hasLinks ? CommonBubbleView.getBubbleMaxWidth(message: messageRow.transactionMessage) : nil
        return showOutgoingMessageBubble(messageRow: messageRow, fixedBubbleWidth: fixedWidth, minimumWidth: minimumWidth)
    }
    
    func showOutgoingMessageBubble(messageRow: TransactionMessageRow, fixedBubbleWidth: CGFloat?, minimumWidth: CGFloat = 0.0) -> (UILabel, CGSize)  {
        self.messageRow = messageRow
        
        clearBubbleView()

        let bubbleMaxWidth = fixedBubbleWidth ?? CommonBubbleView.getBubbleMaxWidth(message: messageRow.transactionMessage)
        let textColorAndFont = messageRow.getMessageAttributes()
        let bubbleColors = getBubbleColors(messageRow: messageRow, incoming: false)
        
        let labelMargin = MessageBubbleView.getLabelMargin(messageRow: messageRow)
        let (label, bubbleEstimatedSize, bubbleMargin) = MessageBubbleView.getLabelAttributes(messageRow: messageRow,
                                                                                              maxBubbleWidth: bubbleMaxWidth,
                                                                                              bubbleMargin: Constants.kBubbleSentArrowMargin,
                                                                                              labelMargin: labelMargin,
                                                                                              textColorAndFont: textColorAndFont)
        
        let bubbleSize = getBubbleSize(messageRow: messageRow,
                                       bubbleSize: bubbleEstimatedSize,
                                       fixedWidth: fixedBubbleWidth,
                                       minimumWidth: minimumWidth)
        
        let messageBezierPath = getOutgoingBezierPath(size: bubbleSize,
                                                      bubbleMargin: bubbleMargin,
                                                      consecutiveBubbles: getConsecutiveBubble(messageRow: messageRow),
                                                      consecutiveMessages: messageRow.getConsecutiveMessages())

        let outgoingMessageLayer = CAShapeLayer()
        outgoingMessageLayer.path = messageBezierPath.cgPath
        outgoingMessageLayer.frame = CGRect(x: 0,
                                            y: 0,
                                            width: bubbleSize.width,
                                            height: bubbleSize.height)

        outgoingMessageLayer.fillColor = bubbleColors.0
        outgoingMessageLayer.strokeColor = bubbleColors.1
        outgoingMessageLayer.lineWidth = 1
        outgoingMessageLayer.name = CommonBubbleView.kBubbleLayerName
        
        let topPadding: CGFloat = messageRow.isPaidSentMessage ? Constants.kPaidMessageTopPadding : 0
        label.frame.origin = CGPoint(x: labelMargin, y: labelMargin + topPadding)
        label.tag = MessageBubbleView.kMessageLabelTag

        addMessageShadow(layer: outgoingMessageLayer)
        contentView.layer.addSublayer(outgoingMessageLayer)
        contentView.addSubview(label)
        
        return (label, bubbleSize)
    }
    
    func showIncomingMessageWebViewBubble(messageRow: TransactionMessageRow) -> CGSize {
        self.messageRow = messageRow
        
        clearBubbleView()

        let labelMargin = Constants.kLabelMargins
        let webViewHeight = messageRow.transactionMessage.getWebViewHeight() ?? MessageWebViewTableViewCell.kMessageWebViewRowHeight
        let bubbleWidth = MessageWebViewTableViewCell.kMessageWebViewBubbleWidth + (Constants.kLabelMargins * 2)
        let bubbleSize = CGSize(width: bubbleWidth, height: webViewHeight + (labelMargin * 2))
        let bubbleColors = getBubbleColors(messageRow: messageRow, incoming: true)
        let messageBezierPath = getIncomingBezierPath(size: bubbleSize,
                                                      bubbleMargin: Constants.kBubbleReceivedArrowMargin,
                                                      consecutiveBubbles: getConsecutiveBubble(messageRow: messageRow),
                                                      consecutiveMessages: messageRow.getConsecutiveMessages())

        let comingMessageLayer = CAShapeLayer()
        comingMessageLayer.path = messageBezierPath.cgPath
        comingMessageLayer.frame = CGRect(x: 0,
                                          y: 0,
                                          width: bubbleSize.width,
                                          height: bubbleSize.height)
        
        comingMessageLayer.fillColor = bubbleColors.0
        comingMessageLayer.strokeColor = bubbleColors.1
        comingMessageLayer.lineWidth = 1
        comingMessageLayer.name = CommonBubbleView.kBubbleLayerName

        addMessageShadow(layer: comingMessageLayer)
        contentView.layer.addSublayer(comingMessageLayer)
        
        return bubbleSize
    }
    
    func getConsecutiveBubble(messageRow: TransactionMessageRow) -> ConsecutiveBubbles {
        if messageRow.isPodcastLive {
            return ConsecutiveBubbles(previousBubble: false, nextBubble: false)
        }
        
        let isReply = messageRow.isReply
        let isPaidAttachment = messageRow.isPaidAttachment
        let isMediaAttachment = messageRow.isMediaAttachment
        let isPodcastComment = messageRow.isPodcastComment
        let hasLinkBubble = messageRow.shouldShowTribeLinkPreview() || messageRow.shouldShowPubkeyPreview()
        let previousBubble = isMediaAttachment || isReply || isPodcastComment
        
        if messageRow.isIncoming() {
            return ConsecutiveBubbles(previousBubble: previousBubble, nextBubble: isPaidAttachment || hasLinkBubble)
        } else {
            return ConsecutiveBubbles(previousBubble: previousBubble, nextBubble: hasLinkBubble)
        }
    }
}
