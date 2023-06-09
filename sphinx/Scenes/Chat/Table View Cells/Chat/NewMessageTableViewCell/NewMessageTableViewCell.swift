//
//  NewMessageTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 31/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import Foundation

extension NewMessageTableViewCell {
    public enum MessageDirection {
        case Incoming
        case Outgoing
    }
    
    public enum GroupingState {
        case Isolated
        case First
        case Middle
        case Last
    }
}

protocol ChatTableViewCellProtocol: class {
    var contentView: UIView { get }
    
    func configureWith(messageCellState: MessageTableCellState)
}

class NewMessageTableViewCell: SwipableReplyCell, ChatTableViewCellProtocol {
    
    ///General views
    @IBOutlet weak var bubbleAllView: UIView!
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
    
    ///First Container
    @IBOutlet weak var messageReplyView: NewMessageReplyView!
    
    ///Second Container
    @IBOutlet weak var sentPaidDetailsView: SentPaidDetails!
    @IBOutlet weak var paidTextMessageView: UIView!
    @IBOutlet weak var directPaymentView: DirectPaymentView!
    @IBOutlet weak var mediaContentView: MediaMessageView!
    @IBOutlet weak var fileDetailsView: FileDetailsView!
    @IBOutlet weak var audioMessageView: AudioMessageView!
    @IBOutlet weak var podcastAudioView: PodcastAudioView!
    @IBOutlet weak var callLinkView: JoinVideoCallView!
    @IBOutlet weak var podcastBoostView: PodcastBoostView!
    @IBOutlet weak var botResponseView: BotResponseView!
    
    ///Thirs Container
    @IBOutlet weak var textMessageView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messageLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabelTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var tribeLinkPreviewView: TribeLinkPreviewView!
    @IBOutlet weak var contactLinkPreviewView: ContactLinkPreviewView!
    @IBOutlet weak var linkPreviewView: NewLinkPreviewView!
    
    ///Forth Container
    @IBOutlet weak var messageBoostView: NewMessageBoostView!
    @IBOutlet weak var paidAttachmentView: PaidAttachmentView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupViews()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureWith(
        messageCellState: MessageTableCellState
    ) {
        hideAllSubviews()
        
        var mutableMessageCellState = messageCellState
        
        guard let bubble = mutableMessageCellState.bubble else {
            return
        }
        
        ///Bubble Width
        configureWidthWith(messageCellState: mutableMessageCellState)
        
        ///Status Header
        configureWith(statusHeader: mutableMessageCellState.statusHeader)
        
        ///Message content
        configureWith(messageContent: mutableMessageCellState.messageContent)
        
        ///Message Reply
        configureWith(messageReply: mutableMessageCellState.messageReply, and: bubble)
        
        ///Other message types
        configureWith(directPayment: mutableMessageCellState.directPayment, and: bubble)
        configureWith(callLink: mutableMessageCellState.callLink)
        configureWith(podcastBoost: mutableMessageCellState.podcastBoost)
        
        //Bottom view
        configureWith(boosts: mutableMessageCellState.boosts, and: bubble)
        configureWith(contactLink: mutableMessageCellState.contactLink, and: bubble)
        
        ///Header and avatar
        configureWith(avatarImage: mutableMessageCellState.avatarImage)
        configureWith(bubble: bubble)
    }
    
}
