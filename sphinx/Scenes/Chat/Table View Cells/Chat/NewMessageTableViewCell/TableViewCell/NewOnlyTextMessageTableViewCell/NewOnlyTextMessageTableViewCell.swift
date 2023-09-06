//
//  NewOnlyTextMessageTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 08/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class NewOnlyTextMessageTableViewCell: CommonNewMessageTableViewCell, ChatTableViewCellProtocol {
    
    ///General views
    @IBOutlet weak var bubbleOnlyText: UIView!
    @IBOutlet weak var receivedArrow: UIView!
    @IBOutlet weak var sentArrow: UIView!
    
    @IBOutlet weak var chatAvatarContainerView: UIView!
    @IBOutlet weak var chatAvatarView: ChatAvatarView!
    @IBOutlet weak var sentMessageMargingView: UIView!
    @IBOutlet weak var receivedMessageMarginView: UIView!
    @IBOutlet weak var statusHeaderViewContainer: UIView!
    @IBOutlet weak var statusHeaderView: StatusHeaderView!
    
    ///Constraints
    @IBOutlet weak var bubbleWidthConstraint: NSLayoutConstraint!
    
    ///Thirs Container
    @IBOutlet weak var textMessageView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messageLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabelTrailingConstraint: NSLayoutConstraint!
    
    ///Invoice Lines
    @IBOutlet weak var leftLineContainer: UIView!
    @IBOutlet weak var rightLineContainer: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupViews()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setupViews() {
        bubbleOnlyText.layer.cornerRadius = MessageTableCellState.kBubbleCornerRadius

        receivedArrow.drawReceivedBubbleArrow(color: UIColor.Sphinx.ReceivedMsgBG)
        sentArrow.drawSentBubbleArrow(color: UIColor.Sphinx.SentMsgBG)
        
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
        var mutableMessageCellState = messageCellState
        
        guard let bubble = mutableMessageCellState.bubble else {
            return
        }
        
        self.delegate = delegate
        self.rowIndex = indexPath.row
        self.messageId = mutableMessageCellState.messageId
        
        if let statusHeader = mutableMessageCellState.statusHeader {
            configureWith(statusHeader: statusHeader)
        }
        
        ///Text message content
        configureWith(
            messageContent: mutableMessageCellState.messageContent,
            searchingTerm: searchingTerm
        )
        
        ///Header and avatar
        configureWith(avatarImage: mutableMessageCellState.avatarImage)
        configureWith(bubble: bubble)
        
        ///Invoice Lines
        configureWith(invoiceLines: mutableMessageCellState.invoicesLines)
    }

    override func getBubbleView() -> UIView? {
        return bubbleOnlyText
    }
}
