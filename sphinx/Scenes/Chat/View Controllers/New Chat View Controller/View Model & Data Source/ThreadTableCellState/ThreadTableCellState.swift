//
//  ThreadTableCellState.swift
//  sphinx
//
//  Created by Tomas Timinskas on 25/07/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

struct ThreadTableCellState {
    
    ///Constants
    let kAudioBubbleMargings: CGFloat = 78
    
    ///Messages Data
    var originalMessage: TransactionMessage! = nil
    var messageId: Int? = nil
    var threadMessages: [TransactionMessage] = []
    var owner: UserContact! = nil
    
    init(
        originalMessage: TransactionMessage,
        threadMessages: [TransactionMessage],
        owner: UserContact
    ) {
        self.originalMessage = originalMessage
        self.messageId = originalMessage.id
        self.threadMessages = threadMessages
        self.owner  = owner
    }
    
    lazy var threadMessagesState : ThreadLayoutState.ThreadMessages? = {
        let originalMessageDate = (originalMessage.date ?? Date())
        let timestamp = "\(originalMessageDate.getStringDate(format: "MMMM dd")) at \(originalMessageDate.getStringDate(format: "hh:mm a"))"
        let messageContent = originalMessage.bubbleMessageContentString ?? ""
        
        let orignalMessageThred = ThreadLayoutState.ThreadOriginalMessage(
            text: messageContent.replacingHightlightedChars,
            linkMatches: messageContent.stringLinks + messageContent.pubKeyMatches + messageContent.mentionMatches,
            highlightedMatches: messageContent.highlightedMatches,
            timestamp: timestamp,
            senderInfo: getSenderInfo(message: originalMessage)
        )
        
        var threadPeopleMap: [String: ThreadLayoutState.ThreadPeople] = [:]
        
        for message in threadMessages {
            let senderInfo = getSenderInfo(message: message)
            
            if let existingThreadMessage = threadPeopleMap[senderInfo.1] {
                continue
            } else {
                threadPeopleMap[senderInfo.1] = ThreadLayoutState.ThreadPeople(
                    senderIndo: senderInfo
                )
            }
        }
        
        let threadPeopleArray = threadPeopleMap.map { $0.value }
        
        return ThreadLayoutState.ThreadMessages(
            orignalThreadMessage: orignalMessageThred,
            threadPeople: threadPeopleArray.subarray(size: 6),
            threadPeopleCount: threadPeopleArray.count,
            repliesCount: threadMessages.count,
            lastReplyTimestamp: (threadMessages.last?.date ?? Date()).timeIntervalSince1970.getDayDiffString()
        )
    }()
    
    lazy var messageMedia: BubbleMessageLayoutState.MessageMedia? = {
        guard let message = originalMessage,
                message.isMediaAttachment() ||
                message.isGiphy() else
        {
            return nil
        }
        
        var urlAndKey = messageMediaUrlAndKey
        
        return BubbleMessageLayoutState.MessageMedia(
            url: urlAndKey.0,
            mediaKey: urlAndKey.1,
            isImage: message.isImage() || message.isDirectPayment(),
            isVideo: message.isVideo(),
            isGif: message.isGif(),
            isPdf: message.isPDF(),
            isGiphy: message.isGiphy(),
            isPaid: false,
            isPaymentTemplate: false
        )
    }()
    
    lazy var genericFile: BubbleMessageLayoutState.GenericFile? = {
        guard let message = originalMessage, message.isFileAttachment() else {
            return nil
        }
        
        return BubbleMessageLayoutState.GenericFile(
            url: message.getMediaUrlFromMediaToken(),
            mediaKey: message.mediaKey
        )
    }()
    
    lazy var audio: BubbleMessageLayoutState.Audio? = {
        guard let message = originalMessage, message.isAudio() else {
            return nil
        }
        
        let bubbleWidth = (UIScreen.main.bounds.width - kAudioBubbleMargings)
        
        return BubbleMessageLayoutState.Audio(
            url: message.getMediaUrlFromMediaToken(),
            mediaKey: message.mediaKey,
            bubbleWidth: bubbleWidth
        )
    }()
    
    lazy var messageMediaUrlAndKey: (URL?, String?) = {
        guard let message = originalMessage else {
            return (nil, nil)
        }
        
        var urlAndKey: (URL?, String?) = (nil, nil)
        
        if message.isMediaAttachment(){
            urlAndKey = (message.getMediaUrlFromMediaToken(), message.mediaKey)
        } else if message.isGiphy() {
            urlAndKey = (message.getGiphyUrl(), nil)
        }
        
        return urlAndKey
    }()
}

extension ThreadTableCellState {
    func getSenderInfo(
        message: TransactionMessage
    ) -> (UIColor, String, String?) {
        
        var senderInfo: (UIColor, String, String?) = (
            UIColor.Sphinx.SecondaryText,
            "Unknow",
            nil
        )
        
        let isSent = message.isOutgoing(ownerId: owner.id)
        
        if isSent {
            senderInfo = (
                owner.getColor(),
                owner.nickname ?? "Unknow",
                owner.avatarUrl
            )
        } else {
            senderInfo = (
                ChatHelper.getSenderColorFor(message: message),
                message.senderAlias ?? "Unknow",
                message.senderPic
            )
        }
        
        return senderInfo
    }
}

extension ThreadTableCellState : Hashable {

    static func == (lhs: ThreadTableCellState, rhs: ThreadTableCellState) -> Bool {
        let mutableLhs = lhs
        let mutableRhs = rhs
        
        return
            mutableLhs.originalMessage?.id      == mutableRhs.originalMessage?.id &&
            mutableLhs.threadMessages.count     == mutableRhs.threadMessages.count
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.originalMessage?.id)
    }
}
