//
//  Library
//
//  Created by Tomas Timinskas on 26/04/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class ExpiredInvoiceCommonChatTableViewCell {
    
//    @IBOutlet weak var bubbleWidthConstraint: NSLayoutConstraint!
//    
//    public static var kExpiredBubbleHeight: CGFloat = 60
//    public static var kExpiredBubbleMinimumWidth: CGFloat = 160
//    public static var kAmountLabelSideMargins: CGFloat = 115
//    
//    public static func getExpiredInvoiceBubbleWidth(messageRow: TransactionMessageRow) -> CGFloat {
//        let amountBubbleWidth = ExpiredInvoiceSentTableViewCell.getAmountLabelWidth(messageRow: messageRow) + ExpiredInvoiceSentTableViewCell.kAmountLabelSideMargins
//        let bubbleWidth = (amountBubbleWidth < ExpiredInvoiceSentTableViewCell.kExpiredBubbleMinimumWidth) ? ExpiredInvoiceSentTableViewCell.kExpiredBubbleMinimumWidth : amountBubbleWidth
//        return bubbleWidth
//    }
//    
//    public static func getAmountLabelWidth(messageRow: TransactionMessageRow) -> CGFloat {
//        let amountString = messageRow.getAmountString()
//        let labelWidth = UILabel.getLabelSize(width: .greatestFiniteMagnitude, text: amountString, font: UIFont.getAmountFont()).width
//        return labelWidth
//    }
//    
//    func drawDiagonalLine(lineContainer: UIView, incoming: Bool) {
//        let bezierPath = UIBezierPath()
//        bezierPath.move(to: CGPoint(x: 0, y: 25))
//        bezierPath.addLine(to: CGPoint(x: 25, y: 0))
//        
//        let whiteLineLayer = CAShapeLayer()
//        whiteLineLayer.path = bezierPath.cgPath
//        whiteLineLayer.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
//        whiteLineLayer.lineWidth = 5
//        whiteLineLayer.strokeColor = (incoming ? UIColor.Sphinx.OldReceivedMsgBG : UIColor.Sphinx.OldSentMsgBG).resolvedCGColor(with: self)
//        
//        let redLineLayer = CAShapeLayer()
//        redLineLayer.path = bezierPath.cgPath
//        redLineLayer.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
//        redLineLayer.lineWidth = 1
//        redLineLayer.strokeColor = UIColor.Sphinx.PrimaryRed.resolvedCGColor(with: self)
//        
//        lineContainer.layer.addSublayer(whiteLineLayer)
//        lineContainer.layer.addSublayer(redLineLayer)
//    }
}
