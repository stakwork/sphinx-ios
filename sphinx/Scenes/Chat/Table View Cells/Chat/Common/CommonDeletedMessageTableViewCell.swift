//
//  CommonDeletedMessageTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 29/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class CommonDeletedMessageTableViewCell: CommonChatTableViewCell {

    @IBOutlet weak var deletedLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        super.configureRow(messageRow: messageRow, contact: nil, chat: nil)
        
        commonConfigurationForMessages()
        
        if messageRow.isFlagged {
            deletedLabel.text = "chat-row.message-flagged".localized
        } else {
            deletedLabel.text = "chat-row.message-deleted".localized
        }
    }
    
    public static func getRowHeight() -> CGFloat {
        return 50
    }
}
