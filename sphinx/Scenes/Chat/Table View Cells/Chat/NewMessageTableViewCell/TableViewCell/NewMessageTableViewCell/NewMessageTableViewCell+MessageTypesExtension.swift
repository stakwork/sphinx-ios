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
        messageContent: BubbleMessageLayoutState.MessageContent?,
        searchingTerm: String?
    ) {
        urlRanges = []
        
        if let messageContent = messageContent {
            
            textMessageView.isHidden = false
            messageLabel.attributedText = nil
            messageLabel.text = nil
            
            if messageContent.linkMatches.isEmpty && messageContent.highlightedMatches.isEmpty && searchingTerm == nil {
                messageLabel.text = messageContent.text
                messageLabel.font = messageContent.font
            } else {
                let messageC = messageContent.text ?? ""
                
                let attributedString = NSMutableAttributedString(string: messageC)
                attributedString.addAttributes([NSAttributedString.Key.font: messageContent.font], range: messageC.nsRange)
                
                ///Highlighted text formatting
                let highlightedNsRanges = messageContent.highlightedMatches.map {
                    return $0.range
                }
                
                for (index, nsRange) in highlightedNsRanges.enumerated() {
                    
                    ///Subtracting the previous matches delimiter characters since they have been removed from the string
                    let substractionNeeded = index * 2
                    let adaptedRange = NSRange(location: nsRange.location - substractionNeeded, length: nsRange.length - 2)
                    
                    attributedString.addAttributes(
                        [
                            NSAttributedString.Key.foregroundColor: UIColor.Sphinx.HighlightedText,
                            NSAttributedString.Key.backgroundColor: UIColor.Sphinx.HighlightedTextBackground,
                            NSAttributedString.Key.font: messageContent.highlightedFont
                        ],
                        range: adaptedRange
                    )
                }
                
                ///Links formatting
                for match in messageContent.linkMatches {
                    
                    attributedString.addAttributes(
                        [
                            NSAttributedString.Key.foregroundColor: UIColor.Sphinx.PrimaryBlue,
                            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
                            NSAttributedString.Key.font: messageContent.font
                        ],
                        range: match.range
                    )
                    
                    urlRanges.append(match.range)
                }
                
                ///Search term formatting
                let term = searchingTerm ?? ""
                let searchingTermRange = (messageC.lowercased() as NSString).range(of: term.lowercased())
                attributedString.addAttributes(
                    [
                        NSAttributedString.Key.backgroundColor: UIColor.Sphinx.PrimaryGreen
                    ], 
                    range: searchingTermRange
                )
                
                messageLabel.attributedText = attributedString
                messageLabel.isUserInteractionEnabled = true
            }
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(labelTapped(gesture:)))
            
            if urlRanges.isEmpty {
                messageLabel.removeGestureRecognizer(tap)
            } else {
                messageLabel.addGestureRecognizer(tap)
            }
            
            urlRanges = ChatHelper.removeDuplicatedContainedFrom(urlRanges: urlRanges)
            
            if let messageId = messageId, messageContent.shouldLoadPaidText {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    self.delegate?.shouldLoadTextDataFor(
                        messageId: messageId,
                        and: self.rowIndex
                    )
                }
            }
        }
    }
    
    func configureWith(
        threadMessages: BubbleMessageLayoutState.ThreadMessages?,
        originalMessageMedia: BubbleMessageLayoutState.MessageMedia?,
        originalMessageGenericFile: BubbleMessageLayoutState.GenericFile?,
        originalMessageAudio: BubbleMessageLayoutState.Audio?,
        threadOriginalMsgMediaData: MessageTableCellState.MediaData?,
        bubble: BubbleMessageLayoutState.Bubble,
        mediaDelegate: MediaMessageViewDelegate,
        audioDelegate: AudioMessageViewDelegate
    ) {
        if let threadMessages = threadMessages {
            setMediaContentHeightTo(height: 170.0)
            
            messageThreadView.configureWith(
                threadMessages: threadMessages,
                originalMessageMedia: originalMessageMedia,
                originalMessageGenericFile: originalMessageGenericFile,
                originalMessageAudio: originalMessageAudio,
                mediaData: threadOriginalMsgMediaData,
                bubble: bubble,
                mediaDelegate: mediaDelegate,
                audioDelegate: audioDelegate
            )
            
            messageThreadViewContainer.isHidden = false
        } else {
            setMediaContentHeightTo(
                height: (UIScreen.main.bounds.width - MessageTableCellState.kRowLeftMargin - MessageTableCellState.kRowRightMargin) * 0.7
            )
        }
    }
    
    func setMediaContentHeightTo(
        height: CGFloat
    ) {
        if mediaContentHeightConstraint.constant != height {
            mediaContentHeightConstraint.constant = height
        }
    }
    
    func configureWith(
        threadLastReply: BubbleMessageLayoutState.ThreadLastReply?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let threadLastReply = threadLastReply {
            threadLastReplyHeader.configureWith(threadLastReply: threadLastReply)
            threadLastReplyHeader.isHidden = false
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
        messageMedia: BubbleMessageLayoutState.MessageMedia?,
        mediaData: MessageTableCellState.MediaData?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let messageMedia = messageMedia {
            
            mediaContentView.configureWith(
                messageMedia: messageMedia,
                mediaData: mediaData,
                isThreadOriginalMsg: false,
                bubble: bubble,
                and: self
            )
            
            mediaContentView.isHidden = false
            
            if let messageId = messageId, mediaData == nil {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
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
                    } else if messageMedia.isGiphy {
                        self.delegate?.shouldLoadGiphyDataFor(
                            messageId: messageId,
                            and: self.rowIndex
                        )
                    }
                }
            }
        }
    }
    
    func configureWith(
        genericFile: BubbleMessageLayoutState.GenericFile?,
        mediaData: MessageTableCellState.MediaData?
    ) {
        if let _ = genericFile {
            
            fileDetailsView.configureWith(
                mediaData: mediaData,
                and: self
            )
            
            fileDetailsView.isHidden = false
            
            if let messageId = messageId, mediaData == nil {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    self.delegate?.shouldLoadFileDataFor(
                        messageId: messageId,
                        and: self.rowIndex
                    )
                }
            }
        }
    }
    
    func configureWith(
        botHTMLContent: BubbleMessageLayoutState.BotHTMLContent?,
        botWebViewData: MessageTableCellState.BotWebViewData?
    ) {
        if let botHTMLContent = botHTMLContent {
            
            botResponseView.configureWith(
                botHTMLContent: botHTMLContent,
                botWebViewData: botWebViewData
            )
            botResponseView.isHidden = false
            botResponseView.messageId = self.messageId
            
            if let botWebViewData = botWebViewData {
                botResponseViewHeightConstraint.constant = botWebViewData.height
                botResponseView.layoutIfNeeded()
            } else if let messageId = messageId {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    self.delegate?.shouldLoadBotWebViewDataFor(
                        messageId: messageId,
                        and: self.rowIndex
                    )
                }
            }
        }
    }
    
    func configureWith(
        audio: BubbleMessageLayoutState.Audio?,
        mediaData: MessageTableCellState.MediaData?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let audio = audio {
            audioMessageView.configureWith(
                audio: audio,
                mediaData: mediaData,
                isThreadOriginalMsg: false,
                bubble: bubble,
                and: self
            )
            audioMessageView.isHidden = false
            
            if let messageId = messageId, mediaData == nil {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    self.delegate?.shouldLoadAudioDataFor(
                        messageId: messageId,
                        and: self.rowIndex
                    )
                }
            }
        }
    }
    
    func configureWith(
        podcastComment: BubbleMessageLayoutState.PodcastComment?,
        mediaData: MessageTableCellState.MediaData?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let podcastComment = podcastComment {
            podcastAudioView.configureWith(
                podcastComment: podcastComment,
                mediaData: mediaData,
                bubble: bubble,
                and: self
            )
            podcastAudioView.isHidden = false
            
            if let messageId = messageId, mediaData == nil {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    self.delegate?.shouldPodcastCommentDataFor(
                        messageId: messageId,
                        and: self.rowIndex
                    )
                }
            }
        }
    }
    
    func configureWith(
        payment: BubbleMessageLayoutState.Payment?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let payment = payment {
            invoicePaymentView.configureWith(payment: payment, and: bubble)
            invoicePaymentView.isHidden = false
            
            rightPaymentDot.isHidden = bubble.direction.isIncoming()
            leftPaymentDot.isHidden = bubble.direction.isOutgoing()
        } else {
            rightPaymentDot.isHidden = true
            leftPaymentDot.isHidden = true
        }
    }
    
    func configureWith(
        invoice: BubbleMessageLayoutState.Invoice?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let invoice = invoice {
            invoiceView.configureWith(invoice: invoice, bubble: bubble, and: self)
            invoiceView.isHidden = false
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
        tribeData: MessageTableCellState.TribeData?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let _ = tribeLink {
            if let tribeData = tribeData {
                tribeLinkPreviewView.configureWith(tribeData: tribeData, and: bubble, delegate: self)
                tribeLinkPreviewView.isHidden = false
            } else if let messageId = messageId {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    self.delegate?.shouldLoadTribeInfoFor(
                        messageId: messageId,
                        and: self.rowIndex
                    )
                }
            }
        }
    }
    
    func configureWith(
        webLink: BubbleMessageLayoutState.WebLink?,
        linkData: MessageTableCellState.LinkData?
    ) {
        if let _ = webLink {
            if let linkData = linkData {
                if !linkData.failed {
                    linkPreviewView.configureWith(linkData: linkData, delegate: self)
                    linkPreviewView.isHidden = false
                }
            } else if let messageId = messageId {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    self.delegate?.shouldLoadLinkDataFor(
                        messageId: messageId,
                        and: self.rowIndex
                    )
                }
            }
        }
    }
}
