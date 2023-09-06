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
        threadOriginalMsgMediaData: MessageTableCellState.MediaData?,
        tribeData: MessageTableCellState.TribeData?,
        linkData: MessageTableCellState.LinkData?,
        botWebViewData: MessageTableCellState.BotWebViewData?,
        uploadProgressData: MessageTableCellState.UploadProgressData?,
        delegate: NewMessageTableViewCellDelegate?,
        searchingTerm: String?,
        indexPath: IndexPath
    )
}

protocol NewMessageTableViewCellDelegate: class {
    //Loading content in background
    func shouldLoadTribeInfoFor(messageId: Int, and rowIndex: Int)
    func shouldLoadImageDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadPdfDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadFileDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadVideoDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadGiphyDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadTextDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadLinkDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadBotWebViewDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadAudioDataFor(messageId: Int, and rowIndex: Int)
    func shouldPodcastCommentDataFor(messageId: Int, and rowIndex: Int)
    
    //Actions handling
    ///Message reply
    func didTapMessageReplyFor(messageId: Int, and rowIndex: Int)
    ///Avatar view
    func didTapAvatarViewFor(messageId: Int, and rowIndex: Int)
    ///Call Links
    func didTapCallLinkCopyFor(messageId: Int, and rowIndex: Int)
    func didTapCallJoinAudioFor(messageId: Int, and rowIndex: Int)
    func didTapCallJoinVideoFor(messageId: Int, and rowIndex: Int)
    ///Media
    func didTapMediaButtonFor(messageId: Int, and rowIndex: Int, isThreadOriginalMsg: Bool)
    func didTapFileDownloadButtonFor(messageId: Int, and rowIndex: Int)
    ///Link Previews
    func didTapTribeButtonFor(messageId: Int, and rowIndex: Int)
    func didTapContactButtonFor(messageId: Int, and rowIndex: Int)
    func didTapOnLinkButtonFor(messageId: Int, and rowIndex: Int)
    ///Tribe actions
    func didTapDeleteTribeButtonFor(messageId: Int, and rowIndex: Int)
    func didTapApproveRequestButtonFor(messageId: Int, and rowIndex: Int)
    func didTapRejectRequestButtonFor(messageId: Int, and rowIndex: Int)
    ////Label Links
    func didTapOnLink(_ link: String)
    ///Paid Content
    func didTapPayButtonFor(messageId: Int, and rowIndex: Int)
    ///Audio
    func didTapPlayPauseButtonFor(messageId: Int, and rowIndex: Int)
    ///Podcast CLip
    func didTapClipPlayPauseButtonFor(messageId: Int, and rowIndex: Int, atTime time: Double)
    func shouldSeekClipFor(messageId: Int, and rowIndex: Int, atTime time: Double)
    ///Invoices
    func didTapInvoicePayButtonFor(messageId: Int, and rowIndex: Int)
    ///Menu Long Press
    func didLongPressOn(cell: UITableViewCell, with messageId: Int, bubbleViewRect: CGRect)
    ///Reply on Swipe
    func shouldReplyToMessageWith(messageId: Int, and rowIndex: Int)
}

class NewMessageTableViewCell: CommonNewMessageTableViewCell, ChatTableViewCellProtocol {
    
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
    @IBOutlet weak var botResponseViewHeightConstraint: NSLayoutConstraint!
    
    ///First Container
    @IBOutlet weak var messageReplyView: NewMessageReplyView! 
    @IBOutlet weak var threadLastReplyHeader: ThreadLastMessageHeader!
    @IBOutlet weak var messageThreadViewContainer: UIView!
    @IBOutlet weak var messageThreadView: MessageThreadView!
    
    ///Second Container
    @IBOutlet weak var invoicePaymentView: InvoicePaymentView!
    @IBOutlet weak var invoiceView: InvoiceView!
    @IBOutlet weak var sentPaidDetailsView: SentPaidDetails!
    @IBOutlet weak var paidTextMessageView: UIView!
    @IBOutlet weak var directPaymentView: DirectPaymentView!
    @IBOutlet weak var mediaContentView: MediaMessageView!
    @IBOutlet weak var mediaContentHeightConstraint: NSLayoutConstraint!
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
    
    ///Invoice Lines
    @IBOutlet weak var leftLineContainer: UIView!
    @IBOutlet weak var rightLineContainer: UIView!
    @IBOutlet weak var leftPaymentDot: UIView!
    @IBOutlet weak var rightPaymentDot: UIView!
    
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
        
        guard let bubble = mutableMessageCellState.bubble else {
            return
        }
        
        self.rowIndex = indexPath.row
        self.messageId = mutableMessageCellState.message?.id
        self.originalMessageId = mutableMessageCellState.threadOriginalMessage?.id
        self.delegate = delegate
        
        ///Swipe Reply
        configureSwipeWith(swipeReply: mutableMessageCellState.swipeReply)
        
        ///Bubble Width
        configureWidthWith(messageCellState: mutableMessageCellState)
        
        ///Status Header
        configureWith(statusHeader: mutableMessageCellState.statusHeader, uploadProgressData: uploadProgressData)
        
        ///Message content
        configureWith(
            messageContent: mutableMessageCellState.messageContent,
            searchingTerm: searchingTerm
        )
        
        ///Message Reply
        configureWith(messageReply: mutableMessageCellState.messageReply, and: bubble)
        
        ///Thread
        configureWith(
            threadMessages: mutableMessageCellState.threadMessagesState,
            originalMessageMedia: mutableMessageCellState.threadOriginalMessageMedia,
            originalMessageGenericFile: mutableMessageCellState.threadOriginalMessageGenericFile,
            originalMessageAudio: mutableMessageCellState.threadOriginalMessageAudio,
            threadOriginalMsgMediaData: threadOriginalMsgMediaData,
            bubble: bubble,
            mediaDelegate: self,
            audioDelegate: self
        )
        configureWith(threadLastReply: mutableMessageCellState.threadLastReplyHeader, and: bubble)
        
        ///Paid Content
        configureWith(paidContent: mutableMessageCellState.paidContent, and: bubble)
        
        ///Message types
        configureWith(payment: mutableMessageCellState.payment, and: bubble)
        configureWith(invoice: mutableMessageCellState.invoice, and: bubble)
        configureWith(directPayment: mutableMessageCellState.directPayment, and: bubble)
        configureWith(callLink: mutableMessageCellState.callLink)
        configureWith(podcastBoost: mutableMessageCellState.podcastBoost)
        configureWith(messageMedia: mutableMessageCellState.messageMedia, mediaData: mediaData, and: bubble)
        configureWith(genericFile: mutableMessageCellState.genericFile, mediaData: mediaData)
        configureWith(botHTMLContent: mutableMessageCellState.botHTMLContent, botWebViewData: botWebViewData)
        configureWith(audio: mutableMessageCellState.audio, mediaData: mediaData, and: bubble)
        configureWith(podcastComment: mutableMessageCellState.podcastComment, mediaData: mediaData, and: bubble)
        
        ///Bottom view
        configureWith(boosts: mutableMessageCellState.boosts, and: bubble)
        configureWith(contactLink: mutableMessageCellState.contactLink, and: bubble)
        configureWith(tribeLink: mutableMessageCellState.tribeLink, tribeData: tribeData, and: bubble)
        configureWith(webLink: mutableMessageCellState.webLink, linkData: linkData)
        
        ///Avatar
        configureWith(avatarImage: mutableMessageCellState.avatarImage)
        
        ///Direction and grouping
        configureWith(bubble: bubble, threadMessages: mutableMessageCellState.threadMessagesState)
        
        ///Invoice Lines
        configureWith(invoiceLines: mutableMessageCellState.invoicesLines)
    }
    
    override func getBubbleView() -> UIView? {
        return bubbleAllView
    }
}
