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

class NewMessageTableViewCell: SwipableReplyCell {
    
    ///General views
    @IBOutlet weak var bubbleOnlyText: UIView!
    @IBOutlet weak var bubbleAllView: UIView!
    @IBOutlet weak var receivedArrow: UIView!
    @IBOutlet weak var sentArrow: UIView!
    
    @IBOutlet weak var chatAvatarContainerView: UIView!
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
        index: Int,
        message: String
    ) {
//        configureFor(direction: (index % 2 == 0) ? .Outgoing : .Incoming)
        
        
        configureFor(direction: .Outgoing)
        configureFor(groupingState: .Middle)
        
        let moreThanText = (index % 3 == 0)

        mediaContentView.isHidden = !moreThanText
        messageReplyView.isHidden = !moreThanText
        podcastAudioView.isHidden = !moreThanText
        callLinkView.isHidden = !moreThanText
        podcastBoostView.isHidden = !moreThanText
        messageBoostView.isHidden = !moreThanText
        paidAttachmentView.isHidden = !moreThanText
        
        tribeLinkPreviewView.isHidden = true
        contactLinkPreviewView.isHidden = true
        linkPreviewView.isHidden = true
        
        directPaymentView.isHidden = true
        fileDetailsView.isHidden = true
        audioMessageView.isHidden = true
        sentPaidDetailsView.isHidden = true
        paidTextMessageView.isHidden = true
        botResponseView.isHidden = true
        
//        textMessageView.isHidden = moreThanText
        
        messageLabel.text = message
        
        bubbleOnlyText.isHidden = moreThanText
        bubbleAllView.isHidden = !moreThanText
    }
    
}
