//
//  TransactionTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class TransactionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIView!
    
    @IBOutlet weak var paymentIcon: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var failedPaymentLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var dayOfWeekLabel: UILabel!
    @IBOutlet weak var dayOfMonthLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var errorMessageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func initialConfiguration() {
        paymentIcon.tintColorDidChange()
    }
    
    func configureCell(transaction: PaymentTransaction?) {
        guard let transaction = transaction else {
            return
        }
        
        self.contentView.backgroundColor = transaction.isIncoming() ? UIColor.Sphinx.TransactionBG : UIColor.Sphinx.HeaderBG
        
        let directionPmtImage = UIImage(
            named: transaction.isIncoming() ? "transaction-received-icon" : "transaction-sent-icon"
        )
        let failedPmtImage = UIImage(named: "transaction-warning-icon")
        
        paymentIcon.image = transaction.isFailed() ? failedPmtImage : directionPmtImage
        
        failedPaymentLabel.isHidden = !transaction.isFailed()
        
        let bottomViewVisible = transaction.isFailed() && transaction.expanded
        bottomView.isHidden = !bottomViewVisible
        errorMessageLabel.text = "\("transactions.failure-reason".localized) \(transaction.errorMessage ?? "-")"
        
        if let users = transaction.getUsers() {
            addressLabel.text = users
        } else {
            addressLabel.text = "-"
        }
        
        amountLabel.text = (transaction.amount ?? 0).formattedWithSeparator
                
        if let date = transaction.date {
            dayOfWeekLabel.text = date.getStringDate(format: "EEE")
            dayOfMonthLabel.text = date.getStringDate(format: "MMM dd")
            timeLabel.text = date.getStringDate(format: "hh:mm a")
        } else {
            dayOfWeekLabel.text = "-"
            dayOfMonthLabel.text = "-"
            timeLabel.text = "-"
        }
    }
    
}
