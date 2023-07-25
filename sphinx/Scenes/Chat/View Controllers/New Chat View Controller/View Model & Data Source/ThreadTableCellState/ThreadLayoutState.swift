//
//  ThreadMessageLayoutState.swift
//  sphinx
//
//  Created by Tomas Timinskas on 25/07/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

struct ThreadLayoutState {
    
    struct ThreadMessages {
        var orignalThreadMessage: ThreadOriginalMessage
        var threadMessages: [ThreadMessage]
        var repliesCount: Int
        var lastReplyTimestamp: String
        
        init(
            orignalThreadMessage: ThreadOriginalMessage,
            threadMessages: [ThreadMessage],
            repliesCount: Int,
            lastReplyTimestamp: String
        ) {
            self.orignalThreadMessage = orignalThreadMessage
            self.threadMessages = threadMessages
            self.repliesCount = repliesCount
            self.lastReplyTimestamp = lastReplyTimestamp
        }
    }
    
    struct ThreadOriginalMessage {
        var text: String
        var timestamp: String
        var senderInfo: (UIColor, String, String?)
        
        init(
            text: String,
            timestamp: String,
            senderInfo: (UIColor, String, String?)
        ) {
            self.text = text
            self.timestamp = timestamp
            self.senderInfo = senderInfo
        }
    }
    
    struct ThreadMessage {
        var senderIndo: (UIColor, String, String?)
        var repliesCount: Int
        
        init(
            senderIndo: (UIColor, String, String?),
            repliesCount: Int
        ) {
            self.senderIndo = senderIndo
            self.repliesCount = repliesCount
        }
    }
}
