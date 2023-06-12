//
//  NewMessageTableViewCell+MessageExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 06/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewMessageTableViewCell {
    
    func configureWith(
        messageContent: BubbleMessageLayoutState.MessageContent?
    ) {
        if let messageContent = messageContent {
            messageLabel.text = messageContent.text
            messageLabel.font = messageContent.font
            
            textMessageView.isHidden = false
        }
    }
    
    func configureWith(
        messageReply: BubbleMessageLayoutState.MessageReply?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let messageReply = messageReply {
            messageReplyView.configureWith(messageReply: messageReply, and: bubble)
            messageReplyView.isHidden = false
        }
    }
    
    func configureWith(
        directPayment: BubbleMessageLayoutState.DirectPayment?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let directPayment = directPayment {
            directPaymentView.configureWith(directPayment: directPayment, and: bubble)
            directPaymentView.isHidden = false
        }
    }
    
    func configureWith(
        callLink: BubbleMessageLayoutState.CallLink?
    ) {
        if let callLink = callLink {
            callLinkView.configureWith(callLink: callLink)
            callLinkView.isHidden = false
        }
    }
    
    func configureWith(
        podcastBoost: BubbleMessageLayoutState.PodcastBoost?
    ) {
        if let podcastBoost = podcastBoost {
            podcastBoostView.configureWith(podcastBoost: podcastBoost)
            podcastBoostView.isHidden = false
        }
    }
    
    func configureWith(
        messageMedia: BubbleMessageLayoutState.MessageMedia?,
        and messageId: Int?
    ) {
        if let messageMedia = messageMedia {
            mediaContentView.configureWith(messageMedia: messageMedia)
            mediaContentView.isHidden = false
            
            if let messageId = messageId, messageMedia.loading {
                DispatchQueue.global(qos: .userInitiated).async {
                    if messageMedia.isImage {
                        self.delegate?.shouldLoadImageDataFor(
                            url: messageMedia.url,
                            with: messageId
                        )
                    } else if messageMedia.isPdf {
                        self.delegate?.shouldLoadPdfDataFor(
                            url: messageMedia.url,
                            with: messageId
                        )
                    } else if messageMedia.isVideo {
                        self.delegate?.shouldLoadVideoDataFor(
                            url: messageMedia.url,
                            with: messageId
                        )
                    }
                }
            }
        }
    }
    
    func configureWith(
        boosts: BubbleMessageLayoutState.Boosts?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let boosts = boosts {
            messageBoostView.configureWith(boosts: boosts, and: bubble)
            messageBoostView.isHidden = false
        }
    }
    
    func configureWith(
        contactLink: BubbleMessageLayoutState.ContactLink?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let contactLink = contactLink {
            contactLinkPreviewView.configureWith(contactLink: contactLink, and: bubble)
            contactLinkPreviewView.isHidden = false
        }
    }
    
    func configureWith(
        tribeLink: BubbleMessageLayoutState.TribeLink?,
        and bubble: BubbleMessageLayoutState.Bubble,
        messageId: Int?
    ) {
        if let tribeLink = tribeLink {
            if let tribeLinkLoaded = tribeLink.tribeLinkLoaded {
                tribeLinkPreviewView.configureWith(tribeLink: tribeLinkLoaded, and: bubble)
                tribeLinkPreviewView.isHidden = false
            } else if let messageId = messageId {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.delegate?.shouldLoadTribeInfoFor(link: tribeLink.link, with: messageId)
                }
            }
        }
    }
}
