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
        messageCellState: MessageTableCellState,
        delegate: NewMessageTableViewCellDelegate
    ) {
        hideAllSubviews()
        
        var mutableMessageCellState = messageCellState
        
        configureWith(
            deleted: mutableMessageCellState.deleted,
            direction: mutableMessageCellState.noBubble?.direction
        )
        
        configureWith(dateSeparator: mutableMessageCellState.dateSeparator)
        configureWith(groupMemberNotification: mutableMessageCellState.groupMemberNotification)
    }
    
    func configureWith(
        deleted: NoBubbleMessageLayoutState.Deleted?,
        direction: MessageTableCellState.MessageDirection?
    ) {
        if let deleted = deleted {
            deletedMessageView.configureWith(
                deleted: deleted,
                direction: direction ?? MessageTableCellState.MessageDirection.Outgoing
            )
            deletedMessageView.isHidden = false
        }
    }
    
    func configureWith(
        dateSeparator: NoBubbleMessageLayoutState.DateSeparator?
    ) {
        if let dateSeparator = dateSeparator {
            dateSeparatorView.configureWith(
                dateSeparator: dateSeparator
            )
            dateSeparatorView.isHidden = false
        }
    }
    
    func configureWith(
        groupMemberNotification: NoBubbleMessageLayoutState.GroupMemberNotification?
    ) {
        if let groupMemberNotification = groupMemberNotification {
            groupActionsView.configureWith(groupMemberNotification: groupMemberNotification)
            groupActionsView.isHidden = false
        }
    }
}
