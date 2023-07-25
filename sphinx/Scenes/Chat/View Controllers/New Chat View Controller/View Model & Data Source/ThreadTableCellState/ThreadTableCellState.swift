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
    static let kRowHeight: CGFloat = 128.0
    
    ///Messages Data
    var originalMessage: TransactionMessage! = nil
    var threadMessages: [TransactionMessage] = []
    var owner: UserContact! = nil
    
    init(
        originalMessage: TransactionMessage,
        threadMessages: [TransactionMessage],
        owner: UserContact
    ) {
        self.originalMessage = originalMessage
        self.threadMessages = threadMessages
        self.owner  = owner
    }
    
    lazy var threadMessagesState : ThreadLayoutState.ThreadMessages? = {
        let originalMessageDate = (originalMessage.date ?? Date())
        let timestamp = "\(originalMessageDate.getStringDate(format: "MMMM dd")) at \(originalMessageDate.getStringDate(format: "hh:mm a"))"
        
        let orignalMessageThred = ThreadLayoutState.ThreadOriginalMessage(
            text: originalMessage.bubbleMessageContentString ?? "",
            timestamp: timestamp,
            senderInfo: getSenderInfo(message: originalMessage)
        )
        
        var threadMessagesMap: [String: ThreadLayoutState.ThreadMessage] = [:]
        
        for message in threadMessages {
            let senderInfo = getSenderInfo(message: message)
            
            if let existingThreadMessage = threadMessagesMap[senderInfo.1] {
                threadMessagesMap[senderInfo.1] = ThreadLayoutState.ThreadMessage(
                    senderIndo: senderInfo,
                    repliesCount: existingThreadMessage.repliesCount + 1
                )
            } else {
                threadMessagesMap[senderInfo.1] = ThreadLayoutState.ThreadMessage(
                    senderIndo: senderInfo,
                    repliesCount: 1
                )
            }
        }
        
        let threadMessagesArray = threadMessagesMap.map { $0.value }
        
        return ThreadLayoutState.ThreadMessages(
            orignalThreadMessage: orignalMessageThred,
            threadMessages: threadMessagesArray,
            repliesCount: threadMessages.count,
            lastReplyTimestamp: (threadMessages.last?.date ?? Date()).timeIntervalSince1970.getDayDiffString()
        )
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
        var mutableLhs = lhs
        var mutableRhs = rhs
        
        return
            mutableLhs.originalMessage?.id      == mutableRhs.originalMessage?.id &&
            mutableLhs.threadMessages.count     == mutableRhs.threadMessages.count
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.originalMessage?.id)
    }
}
