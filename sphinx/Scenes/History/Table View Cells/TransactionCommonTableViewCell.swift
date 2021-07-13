//
//  TransactionCommonTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 31/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class TransactionCommonTableViewCell : UITableViewCell {
    
    @IBOutlet weak var arrowImageView: UIImageView!
    @IBOutlet weak var transactionImageView: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    var transaction : PaymentTransaction?
    
    func initialConfiguration() {
        arrowImageView.tintColorDidChange()
        transactionImageView.tintColorDidChange()
    }
    
    func configureCell(transaction: PaymentTransaction?) {
        guard let transaction = transaction else {
            return
        }
        
        self.transaction = transaction
        
        let userId = UserData.sharedInstance.getUserId()
        
        if let users = transaction.getUsers() {
            addressLabel.text = users
        } else if let paymentRequest = transaction.paymentRequest, let message = TransactionMessage.getInvoiceWith(paymentRequestString: paymentRequest) {
            if message.senderId == userId {
                addressLabel.text = message.getMessageReceiverNickname()
            } else {
                addressLabel.text = message.getMessageSenderNickname()
            }
        } else if let paymentHash = transaction.paymentHash, let message = TransactionMessage.getInvoiceWith(paymentRequestString: paymentHash) {
            if message.senderId == userId {
                addressLabel.text = message.getMessageReceiverNickname()
            } else {
                addressLabel.text = message.getMessageSenderNickname()
            }
        } else {
            addressLabel.text = "-"
        }
        
        dateLabel.text = ""
        
        if let date = transaction.date {
            dateLabel.text = date.getStringDate(format: "EEE MMM dd, hh:mm a")
        }
        
        unitLabel.text = "sat"
        amountLabel.text = (transaction.amount ?? 0).formattedWithSeparator
    }
}
