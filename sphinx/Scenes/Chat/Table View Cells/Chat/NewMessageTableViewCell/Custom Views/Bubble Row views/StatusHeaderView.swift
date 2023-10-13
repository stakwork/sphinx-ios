//
//  StatusHeaderView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class StatusHeaderView: UIView {
    
    @IBOutlet private var contentView: UIView!

    @IBOutlet weak var receivedStatusHeader: UIStackView!
    @IBOutlet weak var receivedSenderLabel: UILabel!
    @IBOutlet weak var receivedDateLabel: UILabel!
    @IBOutlet weak var receivedLockIcon: UILabel!
    
    @IBOutlet weak var sentStatusHeader: UIStackView!
    @IBOutlet weak var sentDateLabel: UILabel!
    @IBOutlet weak var sentLockIcon: UILabel!
    @IBOutlet weak var sentLightningIcon: UILabel!
    
    @IBOutlet weak var sentFailureHeader: UIStackView!
    @IBOutlet weak var sentErrorMessage: UILabel!
    @IBOutlet weak var sentErrorIcon: UILabel!
    
    @IBOutlet weak var uploadingHeader: UIStackView!
    @IBOutlet weak var uploadingLabel: UILabel!
    
    @IBOutlet weak var expiredInvoiceSentHeader: UIStackView!
    @IBOutlet weak var expiredInvoiceSentLabel: UILabel!
    
    @IBOutlet weak var expiredInvoiceReceivedHeader: UIStackView!
    @IBOutlet weak var expiredInvoiceReceivedLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("StatusHeaderView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func configureWith(
        direction:  MessageTableCellState.MessageDirection
    ) {
        let outgoing = direction == .Outgoing
        
        receivedStatusHeader.isHidden = outgoing
        sentStatusHeader.isHidden = !outgoing
    }
    
    func configureWith(
        statusHeader: BubbleMessageLayoutState.StatusHeader,
        uploadProgressData: MessageTableCellState.UploadProgressData?
    ) {
        if let senderName = statusHeader.senderName {
            receivedSenderLabel.isHidden = false
            receivedSenderLabel.text =
            senderName
        } else {
            receivedSenderLabel.isHidden = true
        }
        
        receivedSenderLabel.textColor = statusHeader.color
        
        sentLightningIcon.isHidden = !statusHeader.showBoltIcon
        
        sentLockIcon.isHidden = !statusHeader.showLockIcon
        receivedLockIcon.isHidden = !statusHeader.showLockIcon
        
        sentFailureHeader.isHidden = !statusHeader.showFailedContainer
        sentErrorMessage.text = statusHeader.errorMessage
        
        receivedDateLabel.text = statusHeader.timestamp
        sentDateLabel.text = statusHeader.timestamp
        
        expiredInvoiceSentHeader.isHidden = !statusHeader.showExpiredSent
        expiredInvoiceReceivedHeader.isHidden = !statusHeader.showExpiredReceived
        configureWith(expirationTimestamp: statusHeader.expirationTimestamp)
        
        if let uploadProgressData = uploadProgressData, uploadProgressData.progress < 100 {
            uploadingHeader.isHidden = false
            uploadingLabel.text = String(format: "uploaded.progress".localized, uploadProgressData.progress)
        } else {
            uploadingHeader.isHidden = true
        }
    }
    
    func configureWith(
        expirationTimestamp: String?
    ) {
        if let expirationTimestamp = expirationTimestamp {
            expiredInvoiceSentLabel.text = expirationTimestamp
            expiredInvoiceReceivedLabel.text = expirationTimestamp
        } else {
            expiredInvoiceSentLabel.text = "expired.invoice".localized
            expiredInvoiceReceivedLabel.text = "expired.invoice".localized
        }
    }
}
