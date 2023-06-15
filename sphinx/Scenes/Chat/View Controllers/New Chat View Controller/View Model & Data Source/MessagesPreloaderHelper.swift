//
//  MessagesPreloaderHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

class MessagesPreloaderHelper {
    
    class var sharedInstance : MessagesPreloaderHelper {
        struct Static {
            static let instance = MessagesPreloaderHelper()
        }
        return Static.instance
    }
    
    struct ScrollState {
        var bottomFirstVisibleRow: Int
        var bottomFirstVisibleRowOffset: CGFloat
        var bottomFirstVisibleRowUniqueID: Int?
        var numberOfItems: Int
        var shouldAdjustScroll: Bool
        
        init(
            bottomFirstVisibleRow: Int,
            bottomFirstVisibleRowOffset: CGFloat,
            bottomFirstVisibleRowUniqueID: Int?,
            numberOfItems: Int,
            shouldAdjustScroll: Bool
        ) {
            self.bottomFirstVisibleRow = bottomFirstVisibleRow
            self.bottomFirstVisibleRowOffset = bottomFirstVisibleRowOffset
            self.bottomFirstVisibleRowUniqueID = bottomFirstVisibleRowUniqueID
            self.numberOfItems = numberOfItems
            self.shouldAdjustScroll = shouldAdjustScroll
        }
    }
    
    var chatMessages: [Int: [MessageTableCellState]] = [:]
    var chatLastPositions: [Int: ScrollState] = [:]
    
    var tribesData: [String: MessageTableCellState.TribeData] = [:]
    
    func add(
        messageStateArray: [MessageTableCellState],
        for chatId: Int
    ) {
        self.chatMessages[chatId] = messageStateArray
    }
    
    func getMessageStateArray(for chatId: Int) -> [MessageTableCellState]? {
        if let messageStateArray = chatMessages[chatId], messageStateArray.count > 0 {
            return messageStateArray
        }
        return nil
    }
    
    func save(
        bottomFirstVisibleRow: Int,
        bottomFirstVisibleRowOffset: CGFloat,
        bottomFirstVisibleRowUniqueID: Int?,
        numberOfItems: Int,
        for chatId: Int
    ) {
        self.chatLastPositions[chatId] = ScrollState(
            bottomFirstVisibleRow: bottomFirstVisibleRow,
            bottomFirstVisibleRowOffset: bottomFirstVisibleRowOffset,
            bottomFirstVisibleRowUniqueID: bottomFirstVisibleRowUniqueID,
            numberOfItems: numberOfItems,
            shouldAdjustScroll: true
        )
    }
    
    func getScrollState(
        for chatId: Int,
        with newItemIdentifiers: [MessageTableCellState]
    ) -> ScrollState? {
        
        if let scrollState = chatLastPositions[chatId] {
            
            if let firstItemBeforeUpdate = scrollState.bottomFirstVisibleRowUniqueID {
                
                let itemUniqueIdentifiers = newItemIdentifiers.map({ $0.getUniqueIdentifier() })
                let difference = itemUniqueIdentifiers.index(of: firstItemBeforeUpdate) ?? 0
                let destinationRow = scrollState.bottomFirstVisibleRow + difference
                let shouldAdjustScroll = destinationRow > 0 && scrollState.numberOfItems != newItemIdentifiers.count
                
                return ScrollState(
                    bottomFirstVisibleRow: destinationRow,
                    bottomFirstVisibleRowOffset: scrollState.bottomFirstVisibleRowOffset,
                    bottomFirstVisibleRowUniqueID: scrollState.bottomFirstVisibleRowUniqueID,
                    numberOfItems: scrollState.numberOfItems,
                    shouldAdjustScroll: shouldAdjustScroll
                )
            }
        }
        return nil
    }
}
