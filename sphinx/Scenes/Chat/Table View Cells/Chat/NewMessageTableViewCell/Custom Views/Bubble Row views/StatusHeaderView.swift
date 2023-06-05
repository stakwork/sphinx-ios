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
    
    func configureFor(
        direction:  NewMessageTableViewCell.MessageDirection
    ) {
        let outgoing = direction == .Outgoing
        
        receivedStatusHeader.isHidden = outgoing
        sentStatusHeader.isHidden = !outgoing
        sentFailureHeader.isHidden = true
    }
}
