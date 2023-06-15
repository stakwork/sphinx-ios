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
    
    func configureWith(
        messageCellState: MessageTableCellState,
        mediaData: MessageTableCellState.MediaData?,
        tribeData: MessageTableCellState.TribeData?,
        delegate: NewMessageTableViewCellDelegate,
        indexPath: IndexPath
    )
}

protocol NewMessageTableViewCellDelegate: class {
    //Loading content in background
    func shouldLoadTribeInfoFor(messageId: Int, and rowIndex: Int)
    func shouldLoadImageDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadPdfDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadVideoDataFor(messageId: Int, and rowIndex: Int)
    
    //Actions handling
    func didTapMessageReplyFor(messageId: Int, and rowIndex: Int)
    ///Call Links
    func didTapCallLinkCopyFor(messageId: Int, and rowIndex: Int)
    func didTapCallJoinAudioFor(messageId: Int, and rowIndex: Int)
    func didTapCallJoinVideoFor(messageId: Int, and rowIndex: Int)
    ///Media
    func didTapMediaButtonFor(messageId: Int, and rowIndex: Int)
    ///Link Previews
    func didTapTribeButtonFor(messageId: Int, and rowIndex: Int)
    func didTapContactButtonFor(messageId: Int, and rowIndex: Int)
    ///Tribe actions
    func didTapDeleteTribeButtonFor(messageId: Int, and rowIndex: Int)
    func didTapApproveRequestButtonFor(messageId: Int, and rowIndex: Int)
    func didTapRejectRequestButtonFor(messageId: Int, and rowIndex: Int)
    ///Label Links
    func didTapOnLink(_ link: String)
}

class NewMessageTableViewCell: SwipableReplyCell, ChatTableViewCellProtocol {
    
    weak var delegate: NewMessageTableViewCellDelegate!
    
    var rowIndex: Int!
    var messageId: Int?
    
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
    @IBOutlet weak var paidTextMessageView: UIView! // PENDING
    @IBOutlet weak var directPaymentView: DirectPaymentView!
    @IBOutlet weak var mediaContentView: MediaMessageView!
    @IBOutlet weak var fileDetailsView: FileDetailsView! // PENDING
    @IBOutlet weak var audioMessageView: AudioMessageView! // PENDING
    @IBOutlet weak var podcastAudioView: PodcastAudioView! // PENDING
    @IBOutlet weak var callLinkView: JoinVideoCallView!
    @IBOutlet weak var podcastBoostView: PodcastBoostView!
    @IBOutlet weak var botResponseView: BotResponseView! // PENDING
    
    ///Thirs Container
    @IBOutlet weak var textMessageView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messageLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabelTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var tribeLinkPreviewView: TribeLinkPreviewView!
    @IBOutlet weak var contactLinkPreviewView: ContactLinkPreviewView!
    @IBOutlet weak var linkPreviewView: NewLinkPreviewView! // PENDING
    
    ///Forth Container
    @IBOutlet weak var messageBoostView: NewMessageBoostView!
    @IBOutlet weak var paidAttachmentView: PaidAttachmentView! // PENDING
    
    var urlRanges = [NSRange]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupViews()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureWith(
        messageCellState: MessageTableCellState,
        mediaData: MessageTableCellState.MediaData?,
        tribeData: MessageTableCellState.TribeData?,
        delegate: NewMessageTableViewCellDelegate,
        indexPath: IndexPath
    ) {
        
        hideAllSubviews()
        
        var mutableMessageCellState = messageCellState
        
        guard let bubble = mutableMessageCellState.bubble else {
            return
        }
        
        self.rowIndex = indexPath.row
        self.messageId = mutableMessageCellState.message?.id
        self.delegate = delegate
        
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
        configureWith(messageMedia: mutableMessageCellState.messageMedia, mediaData: mediaData)
        
        //Bottom view
        configureWith(boosts: mutableMessageCellState.boosts, and: bubble)
        configureWith(contactLink: mutableMessageCellState.contactLink, and: bubble)
        configureWith(tribeLink: mutableMessageCellState.tribeLink, tribeData: tribeData, and: bubble)
        
        ///Header and avatar
        configureWith(avatarImage: mutableMessageCellState.avatarImage)
        configureWith(bubble: bubble)
    }
    
}
