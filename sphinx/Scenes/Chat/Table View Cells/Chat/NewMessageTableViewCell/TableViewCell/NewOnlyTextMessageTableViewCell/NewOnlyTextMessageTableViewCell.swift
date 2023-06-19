//
//  NewOnlyTextMessageTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 08/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class NewOnlyTextMessageTableViewCell: CommonNewMessageTableViewCell, ChatTableViewCellProtocol {
    
    weak var delegate: NewMessageTableViewCellDelegate!
    
    var rowIndex: Int!
    var messageId: Int?
    
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
    
    var urlRanges = [NSRange]()

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
    }
    
    func configureWith(
        messageCellState: MessageTableCellState,
        mediaData: MessageTableCellState.MediaData?,
        tribeData: MessageTableCellState.TribeData?,
        uploadProgressData: MessageTableCellState.UploadProgressData?,
        delegate: NewMessageTableViewCellDelegate,
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
        configureWith(messageContent: mutableMessageCellState.messageContent)
        
        ///Header and avatar
        configureWith(avatarImage: mutableMessageCellState.avatarImage)
        configureWith(bubble: bubble)
    }
    
    @objc func labelTapped(
        gesture: UITapGestureRecognizer
    ) {
        if let label = gesture.view as? UILabel, let text = label.text {
            for range in urlRanges {
                if gesture.didTapAttributedTextInLabel(
                    label,
                    inRange: range
                ) {
                    let link = (text as NSString).substring(with: range)
                    delegate?.didTapOnLink(link)                    
                }
            }
        }
    }
    
    override func didLongPressOnCell() {
        if let messageId = messageId {
            delegate?.didLongPressOnCellWith(
                messageId: messageId,
                and: rowIndex,
                bubbleViewRect: bubbleOnlyText.frame
            )
        }
    }
}
