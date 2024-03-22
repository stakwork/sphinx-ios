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
        var threadPeople: [ThreadPeople]
        var threadPeopleCount: Int
        var repliesCount: Int
        var lastReplyTimestamp: String
        
        init(
            orignalThreadMessage: ThreadOriginalMessage,
            threadPeople: [ThreadPeople],
            threadPeopleCount: Int,
            repliesCount: Int,
            lastReplyTimestamp: String
        ) {
            self.orignalThreadMessage = orignalThreadMessage
            self.threadPeople = threadPeople
            self.threadPeopleCount = threadPeopleCount
            self.repliesCount = repliesCount
            self.lastReplyTimestamp = lastReplyTimestamp
        }
    }
    
    struct ThreadOriginalMessage {
        var text: String
        var linkMatches: [NSTextCheckingResult]
        var highlightedMatches: [NSTextCheckingResult]
        var timestamp: String
        var senderInfo: (UIColor, String, String?)
        
        init(
            text: String,
            linkMatches: [NSTextCheckingResult],
            highlightedMatches: [NSTextCheckingResult],
            timestamp: String,
            senderInfo: (UIColor, String, String?)
        ) {
            self.text = text
            self.linkMatches = linkMatches
            self.highlightedMatches = highlightedMatches
            self.timestamp = timestamp
            self.senderInfo = senderInfo
        }
    }
    
    struct ThreadPeople {
        var senderIndo: (UIColor, String, String?)
        
        init(
            senderIndo: (UIColor, String, String?)
        ) {
            self.senderIndo = senderIndo
        }
    }
}
