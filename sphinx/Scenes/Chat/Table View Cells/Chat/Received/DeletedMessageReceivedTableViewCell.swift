//
//  DeletedMessageReceivedTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 29/06/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import UIKit

class DeletedMessageReceivedTableViewCell: CommonDeletedMessageTableViewCell, MessageRowProtocol {

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat)
    }
}
