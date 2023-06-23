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
        bubbleAllView.layer.cornerRadius = MessageTableCellState.kBubbleCornerRadius

        paidAttachmentView.roundCorners(
            corners: [.bottomLeft, .bottomRight],
            radius: MessageTableCellState.kBubbleCornerRadius,
            viewBounds: CGRect(
                origin: CGPoint.zero,
                size: CGSize(
                    width: (UIScreen.main.bounds.width - (MessageTableCellState.kRowLeftMargin + MessageTableCellState.kRowRightMargin)) * (MessageTableCellState.kBubbleWidthPercentage),
                    height: MessageTableCellState.kSendPaidContentButtonHeight
                )
            )
        )

        receivedArrow.drawReceivedBubbleArrow(color: UIColor.Sphinx.ReceivedMsgBG)
        sentArrow.drawSentBubbleArrow(color: UIColor.Sphinx.SentMsgBG)
    }
    
    func hideAllSubviews() {
        invoicePaymentView.isHidden = true
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
