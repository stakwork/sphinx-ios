//
//  Library
//
//  Created by Tomas Timinskas on 26/02/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class PaymentSentTableViewCell: CommonChatTableViewCell, MessageRowProtocol {
    
    static let kPaymentRowHeight: CGFloat = 65.0

    @IBOutlet weak var paymentLabel: UILabel!
    @IBOutlet weak var dot: UIView!
    @IBOutlet weak var topRightLineContainer: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        dot.layer.cornerRadius = dot.frame.size.height / 2
        dot.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        super.configureRow(messageRow: messageRow, contact: contact, chat: chat)
        
        commonConfigurationForMessages()
        
        let dateString = messageRow.transactionMessage.messageDate.getStringDate(format: "EEEE, MMM dd")
        let paidString = String(format: "invoice.paid.on".localized, "\(dateString)\(messageRow.transactionMessage.messageDate.daySuffix())")
        paymentLabel.text = paidString
        
        addSmallRightLine()
        
        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func addSmallRightLine() {
        topRightLineContainer.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        let lineFrame = CGRect(x: 0, y: 1, width: 3, height: topRightLineContainer.frame.size.height)
        let lineLayer = getVerticalDottedLine(color: UIColor.Sphinx.WashedOutReceivedText, frame: lineFrame)
        topRightLineContainer.layer.addSublayer(lineLayer)
    }
    
    public static func getRowHeight() -> CGFloat {
        return PaymentSentTableViewCell.kPaymentRowHeight
    }
}
