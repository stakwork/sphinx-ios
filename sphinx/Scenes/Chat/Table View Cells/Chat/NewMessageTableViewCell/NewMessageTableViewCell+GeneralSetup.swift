//
//  NewMessageTableViewCell+GeneralSetup.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewMessageTableViewCell {
    
    func setupViews() {
        bubbleOnlyText.layer.cornerRadius = 8.0
        bubbleAllView.layer.cornerRadius = 8.0
        
        paidAttachmentView.roundCorners(
            corners: [.bottomLeft, .bottomRight],
            radius: 8.0,
            viewBounds: CGRect(
                origin: CGPoint.zero,
                size: CGSize(
                    width: (UIScreen.main.bounds.width - 24.0) * 0.7,
                    height: 50.0
                )
            )
        )
        
        receivedArrow.drawReceivedBubbleArrow(color: UIColor.Sphinx.ReceivedMsgBG)
        sentArrow.drawSentBubbleArrow(color: UIColor.Sphinx.SentMsgBG)
        
        messageLabel.font = Constants.kMessageFont
    }
    
    func hideAllSubviews() {
        bubbleAllView.isHidden = true
        bubbleOnlyText.isHidden = true
        
        messageReplyView.isHidden = true
        sentPaidDetailsView.isHidden = true
        paidTextMessageView.isHidden = true
        directPaymentView.isHidden = true
        mediaContentView.isHidden = true
        fileDetailsView.isHidden = true
        audioMessageView.isHidden = true
        podcastAudioView.isHidden = true
        callLinkView.isHidden = true
        podcastBoostView.isHidden = true
        botResponseView.isHidden = true
        textMessageView.isHidden = true
        tribeLinkPreviewView.isHidden = true
        contactLinkPreviewView.isHidden = true
        linkPreviewView.isHidden = true
        messageBoostView.isHidden = true
        paidAttachmentView.isHidden = true
    }
}
