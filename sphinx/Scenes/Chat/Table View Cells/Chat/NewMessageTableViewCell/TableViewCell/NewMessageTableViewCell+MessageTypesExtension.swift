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
        urlRanges = []
        
        if let messageContent = messageContent {
            if messageContent.linkMatches.isEmpty {
                messageLabel.attributedText = nil
                
                messageLabel.text = messageContent.text
                messageLabel.font = messageContent.font
            } else {
                let attributedString = NSMutableAttributedString(string: messageContent.text ?? "")
                
                for match in messageContent.linkMatches {
                    
                    attributedString.setAttributes(
                        [
                            NSAttributedString.Key.foregroundColor: UIColor.Sphinx.PrimaryBlue,
                            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
                        ],
                        range: match.range
                    )
                    
                    urlRanges.append(match.range)
                }
                
                messageLabel.attributedText = attributedString
                messageLabel.isUserInteractionEnabled = true
            }
            
            textMessageView.isHidden = false
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(labelTapped(gesture:)))
        
        if urlRanges.isEmpty {
            messageLabel.removeGestureRecognizer(tap)
        } else {
            messageLabel.addGestureRecognizer(tap)
        }
    }
    
    func configureWith(
        messageReply: BubbleMessageLayoutState.MessageReply?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let messageReply = messageReply {
            messageReplyView.configureWith(messageReply: messageReply, and: bubble, delegate: self)
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
            callLinkView.configureWith(callLink: callLink, and: self)
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
        messageMedia: BubbleMessageLayoutState.MessageMedia?
    ) {
        if let messageMedia = messageMedia {
            mediaContentView.configureWith(messageMedia: messageMedia, and: self)
            mediaContentView.isHidden = false
            
            if let messageId = messageId, messageMedia.loading {
                DispatchQueue.global(qos: .userInitiated).async {
                    if messageMedia.isImage {
                        self.delegate?.shouldLoadImageDataFor(
                            messageId: messageId,
                            and: self.rowIndex
                        )
                    } else if messageMedia.isPdf {
                        self.delegate?.shouldLoadPdfDataFor(
                            messageId: messageId,
                            and: self.rowIndex
                        )
                    } else if messageMedia.isVideo {
                        self.delegate?.shouldLoadVideoDataFor(
                            messageId: messageId,
                            and: self.rowIndex
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
            contactLinkPreviewView.configureWith(contactLink: contactLink, and: bubble, delegate: self)
            contactLinkPreviewView.isHidden = false
        }
    }
    
    func configureWith(
        tribeLink: BubbleMessageLayoutState.TribeLink?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let tribeLink = tribeLink {
            if let tribeLinkLoaded = tribeLink.tribeLinkLoaded {
                tribeLinkPreviewView.configureWith(tribeLink: tribeLinkLoaded, and: bubble, delegate: self)
                tribeLinkPreviewView.isHidden = false
            } else if let messageId = messageId {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.delegate?.shouldLoadTribeInfoFor(
                        messageId: messageId,
                        and: self.rowIndex
                    )
                }
            }
        }
    }
}

extension NewMessageTableViewCell {
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
                    
                    if link.stringLinks.count > 0, let url = URL(string: link.withProtocol(protocolString: "http")) {
                        UIApplication.shared.open(
                            url,
                            options: [:],
                            completionHandler: nil
                        )
                    }
                }
            }
        }
    }
}
