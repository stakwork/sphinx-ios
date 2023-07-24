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
        mediaContentHeightConstraint.constant = (UIScreen.main.bounds.width - MessageTableCellState.kRowLeftMargin - MessageTableCellState.kRowRightMargin) * 0.7
        
        bubbleAllView.layer.cornerRadius = MessageTableCellState.kBubbleCornerRadius
        leftPaymentDot.layer.cornerRadius = leftPaymentDot.frame.height / 2
        rightPaymentDot.layer.cornerRadius = rightPaymentDot.frame.height / 2

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
        
        let lineFrame = CGRect(x: 0.0, y: 0, width: 3, height: contentView.frame.size.height)
        
        let rightLineLayer = rightLineContainer.getVerticalDottedLine(color: UIColor.Sphinx.WashedOutReceivedText, frame: lineFrame)
        rightLineContainer.layer.addSublayer(rightLineLayer)
        
        let leftLineLayer = leftLineContainer.getVerticalDottedLine(color: UIColor.Sphinx.WashedOutReceivedText, frame: lineFrame)
        leftLineContainer.layer.addSublayer(leftLineLayer)
    }
    
    func hideAllSubviews() {
        invoicePaymentView.isHidden = true
        invoiceView.isHidden = true
        messageReplyView.isHidden = true
        messageThreadViewContainer.isHidden = true
        threadLastReplyHeader.isHidden = true
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
