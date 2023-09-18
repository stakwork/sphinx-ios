//
//  MessageNoBubbleTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class MessageNoBubbleTableViewCell: UITableViewCell, ChatTableViewCellProtocol {
    
    weak var delegate: NewMessageTableViewCellDelegate?
    
    var rowIndex: Int!
    var messageId: Int?

    @IBOutlet weak var dateSeparatorView: DateSeparatorView!
    @IBOutlet weak var deletedMessageView: DeletedMessageView!
    @IBOutlet weak var groupActionsView: GroupActionsView!
    
    @IBOutlet weak var leftLineContainer: UIView!
    @IBOutlet weak var rightLineContainer: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        hideAllSubviews()
        setupViews()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func hideAllSubviews() {
        dateSeparatorView.isHidden = true
        deletedMessageView.isHidden = true
        groupActionsView.isHidden = true
    }
    
    func setupViews() {
        let lineFrame = CGRect(x: 0.0, y: 0, width: 3, height: contentView.frame.size.height)
        
        let rightLineLayer = rightLineContainer.getVerticalDottedLine(color: UIColor.Sphinx.WashedOutReceivedText, frame: lineFrame)
        rightLineContainer.layer.addSublayer(rightLineLayer)
        
        let leftLineLayer = leftLineContainer.getVerticalDottedLine(color: UIColor.Sphinx.WashedOutReceivedText, frame: lineFrame)
        leftLineContainer.layer.addSublayer(leftLineLayer)
    }
    
    func configureWith(
        messageCellState: MessageTableCellState,
        mediaData: MessageTableCellState.MediaData?,
        threadOriginalMsgMediaData: MessageTableCellState.MediaData?,
        tribeData: MessageTableCellState.TribeData?,
        linkData: MessageTableCellState.LinkData?,
        botWebViewData: MessageTableCellState.BotWebViewData?,
        uploadProgressData: MessageTableCellState.UploadProgressData?,
        delegate: NewMessageTableViewCellDelegate?,
        searchingTerm: String?,
        indexPath: IndexPath
    ) {
        hideAllSubviews()
        
        var mutableMessageCellState = messageCellState
        
        self.rowIndex = indexPath.row
        self.messageId = mutableMessageCellState.message?.id
        self.delegate = delegate
        
        configureWith(
            deleted: mutableMessageCellState.deleted,
            direction: mutableMessageCellState.noBubble?.direction
        )
        
        ///Date separator
        configureWith(dateSeparator: mutableMessageCellState.dateSeparator)
        
        ///Group notifications
        configureWith(groupMemberNotification: mutableMessageCellState.groupMemberNotification)
        configureWith(groupKickRemovedOrDeclined: mutableMessageCellState.groupKickRemovedOrDeclined)
        configureWith(groupMemberRequest: mutableMessageCellState.groupMemberRequest)
        
        ///Invoice Lines
        configureWith(invoiceLines: mutableMessageCellState.invoicesLines)
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
            groupActionsView.configureWith(
                groupMemberNotification: groupMemberNotification
            )
            groupActionsView.isHidden = false
        }
    }
    
    func configureWith(
        groupKickRemovedOrDeclined: NoBubbleMessageLayoutState.GroupKickRemovedOrDeclined?
    ) {
        if let groupKickRemovedOrDeclined = groupKickRemovedOrDeclined {
            groupActionsView.configureWith(
                groupKickRemovedOrDeclined: groupKickRemovedOrDeclined,
                andDelegate: self
            )
            groupActionsView.isHidden = false
        }
    }
    
    func configureWith(
        groupMemberRequest: NoBubbleMessageLayoutState.GroupMemberRequest?
    ) {
        if let groupMemberRequest = groupMemberRequest {
            groupActionsView.configureWith(
                groupMemberRequest: groupMemberRequest,
                andDelegate: self
            )
            groupActionsView.isHidden = false
        }
    }
    
    func configureWith(
        invoiceLines: BubbleMessageLayoutState.InvoiceLines
    ) {
        switch (invoiceLines.linesState) {
        case .None:
            leftLineContainer.isHidden = true
            rightLineContainer.isHidden = true
            break
        case .Left:
            leftLineContainer.isHidden = false
            rightLineContainer.isHidden = true
            break
        case .Right:
            leftLineContainer.isHidden = true
            rightLineContainer.isHidden = false
            break
        case .Both:
            leftLineContainer.isHidden = false
            rightLineContainer.isHidden = false
            break
        }
    }
}
