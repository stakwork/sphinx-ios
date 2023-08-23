//
//  Sphinx
//
//  Created by Tomas Timinskas on 27/02/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class PaymentInvoiceView: UIView {
    
//    public static let kInvoiceBottomBubbleHeight:CGFloat = 75
//    public static let kInvoiceMessageSideMargin:CGFloat = 30
//    public static let kInvoiceLabelTopMargin:CGFloat = 23
//    public static let kInvoiceMessageBottomMargin:CGFloat = 65
//
//    @IBOutlet private var contentView: UIView!
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setup()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        setup()
//    }
//
//    private func setup() {
//        Bundle.main.loadNibNamed("PaymentInvoiceView", owner: self, options: nil)
//        addSubview(contentView)
//        contentView.frame = self.bounds
//        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
//    }
//
//    func showIncomingDirectPaymentBubble(messageRow: TransactionMessageRow, size: CGSize, hasImage: Bool) {
//        showOutgoingPaidInvoiceBubble(messageRow: messageRow, size: size, hasImage: hasImage)
//    }
//
//    func showOutgoingDirectPaymentBubble(messageRow: TransactionMessageRow, size: CGSize, hasImage: Bool) {
//        showIncomingPaidInvoiceBubble(messageRow: messageRow, size: size, hasImage: hasImage)
//    }
//
//    func showIncomingPaidInvoiceBubble(messageRow: TransactionMessageRow, size: CGSize, hasImage: Bool = false) {
//        clearSubview(view: contentView)
//
//        let consecutiveBubbles = ConsecutiveBubbles(previousBubble: false, nextBubble: hasImage)
//        let bezierPath = getOutgoingBezierPath(size: size, bubbleMargin: 6, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: messageRow.transactionMessage.consecutiveMessages)
//
//        let layer = CAShapeLayer()
//        layer.path = bezierPath.cgPath
//        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
//        layer.fillColor = UIColor.Sphinx.OldSentMsgBG.resolvedCGColor(with: self)
//        layer.strokeColor = UIColor.Sphinx.SentBubbleBorder.resolvedCGColor(with: self)
//        layer.name = CommonBubbleView.kBubbleLayerName
//
//        if messageRow.transactionMessage.isDirectPayment() {
//            layer.name = CommonBubbleView.kBubbleLayerName
//        }
//
//        addMessageShadow(layer: layer)
//        contentView.layer.addSublayer(layer)
//    }
//
//    func removePaidBubbleLayerName() {
//        for sublayer in contentView.layer.sublayers ?? [] {
//            if sublayer.name == CommonBubbleView.kBubbleLayerName {
//               sublayer.name = nil
//            }
//        }
//    }
//
//    func showOutgoingPaidInvoiceBubble(messageRow: TransactionMessageRow, size: CGSize, hasImage: Bool = false) {
//        clearSubview(view: contentView)
//
//        let consecutiveBubbles = ConsecutiveBubbles(previousBubble: false, nextBubble: hasImage)
//        let bezierPath = getIncomingBezierPath(size: size, bubbleMargin: Constants.kBubbleReceivedArrowMargin, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: messageRow.transactionMessage.consecutiveMessages)
//
//        let layer = CAShapeLayer()
//        layer.path = bezierPath.cgPath
//        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
//        layer.fillColor = UIColor.Sphinx.OldReceivedMsgBG.resolvedCGColor(with: self)
//        layer.strokeColor = UIColor.Sphinx.ReceivedBubbleBorder.resolvedCGColor(with: self)
//        layer.name = CommonBubbleView.kBubbleLayerName
//
//        if messageRow.transactionMessage.isDirectPayment() {
//            layer.name = CommonBubbleView.kBubbleLayerName
//        }
//
//        addMessageShadow(layer: layer)
//        contentView.layer.addSublayer(layer)
//    }
//
//    func showIncomingExpiredInvoiceBubble(messageRow: TransactionMessageRow, bubbleWidth: CGFloat) {
//        showExpiredInvoiceBubble(messageRow: messageRow, bubbleWidth: bubbleWidth, incoming: true)
//    }
//
//    func showOutgoingExpiredInvoiceBubble(messageRow: TransactionMessageRow, bubbleWidth: CGFloat) {
//        showExpiredInvoiceBubble(messageRow: messageRow, bubbleWidth: bubbleWidth, incoming: false)
//    }
//
//    func showExpiredInvoiceBubble(messageRow: TransactionMessageRow, bubbleWidth: CGFloat, incoming: Bool) {
//        clearSubview(view: contentView)
//
//        let bubbleHeight = ExpiredInvoiceCommonChatTableViewCell.kExpiredBubbleHeight
//
//        let consecutiveBubbles = ConsecutiveBubbles(previousBubble: false, nextBubble: false)
//        let size = CGSize(width: bubbleWidth, height: bubbleHeight)
//        let bezierPath : UIBezierPath?
//        if incoming {
//            bezierPath = getIncomingBezierPath(size: size, bubbleMargin: Constants.kBubbleReceivedArrowMargin, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: messageRow.transactionMessage.consecutiveMessages)
//        } else {
//            bezierPath = getOutgoingBezierPath(size: size, bubbleMargin: 6, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: messageRow.transactionMessage.consecutiveMessages)
//        }
//
//        let layer = CAShapeLayer()
//        layer.path = bezierPath!.cgPath
//        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
//        layer.fillColor = (incoming ? UIColor.Sphinx.OldReceivedMsgBG : UIColor.Sphinx.OldSentMsgBG).resolvedCGColor(with: self)
//        layer.strokeColor = (incoming ? UIColor.Sphinx.ReceivedBubbleBorder : UIColor.Sphinx.SentBubbleBorder).resolvedCGColor(with: self)
//        layer.name = CommonBubbleView.kBubbleLayerName
//
//        contentView.layer.addSublayer(layer)
//    }

}
