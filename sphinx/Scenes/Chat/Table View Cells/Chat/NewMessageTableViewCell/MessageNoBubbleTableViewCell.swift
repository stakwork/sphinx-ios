//
//  MessageNoBubbleTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class MessageNoBubbleTableViewCell: UITableViewCell, ChatTableViewCellProtocol {

    @IBOutlet weak var dateSeparatorView: DateSeparatorView!
    @IBOutlet weak var deletedMessageView: DeletedMessageView!
    @IBOutlet weak var groupActionsView: GroupActionsView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        hideAllSubviews()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func hideAllSubviews() {
        dateSeparatorView.isHidden = true
        deletedMessageView.isHidden = true
        groupActionsView.isHidden = true
    }
    
    func configureWith(
        messageCellState: MessageTableCellState
    ) {
        hideAllSubviews()
        
        var mutableMessageCellState = messageCellState
        
        configureWith(
            deleted: mutableMessageCellState.deleted,
            direction: mutableMessageCellState.noBubble?.direction
        )
    }
    
    func configureWith(
        deleted: NoBubbleMessageLayoutState.Deleted?,
        direction: MessageTableCellState.MessageDirection?
    ) {
        if let deleted = deleted {
            deletedMessageView.isHidden = false
            
            deletedMessageView.configureWith(
                deleted: deleted,
                direction: direction ?? MessageTableCellState.MessageDirection.Outgoing
            )
        }
    }
}
