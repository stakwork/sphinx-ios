//
//  NewChatTableDataSource+PreloaderExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension NewChatTableDataSource {
    @objc func restorePreloadedMessages() {
        guard let chat = chat else {
            return
        }
        
        if let messagesStateArray = preloaderHelper.getMessageStateArray(for: chat.id) {
            messageTableCellStateArray = messagesStateArray
            updateSnapshot()
        }
    }
    
    @objc func saveMessagesToPreloader() {
        guard let chat = chat else {
            return
        }
        
        if let firstVisibleRow = tableView.indexPathsForVisibleRows?.last {
            preloaderHelper.add(
                messageStateArray: messageTableCellStateArray.subarray(size: firstVisibleRow.row + 10),
                for: chat.id
            )
        }
    }
    
    @objc func saveSnapshotCurrentState() {
        guard let chat = chat else {
            return
        }
        
        if let firstVisibleRow = tableView.indexPathsForVisibleRows?.first {
            
            let cellRectInTable = tableView.rectForRow(at: firstVisibleRow)
            let cellOffset = tableView.convert(cellRectInTable.origin, to: bottomView)
            
            preloaderHelper.save(
                bottomFirstVisibleRow: firstVisibleRow.row,
                bottomFirstVisibleRowOffset: cellOffset.y,
                bottomFirstVisibleRowUniqueID: dataSource.snapshot().itemIdentifiers.first?.getUniqueIdentifier(),
                numberOfItems: preloaderHelper.getPreloadedMessagesCount(for: chat.id),
                for: chat.id
            )
        }
        
        saveMessagesToPreloader()
    }
    
    @objc func restoreScrollLastPosition() {
        guard let chat = chat else {
            return
        }
        
        tableView.alpha = 1.0
        
        if let pinnedMessageId = pinnedMessageId {
            if let index = getTableCellStateFor(
                messageId: pinnedMessageId,
                and: nil
            )?.0 {
                tableView.scrollToRow(
                    at: IndexPath(row: index, section: 0),
                    at: .top,
                    animated: true
                )
            }
        } else {
            if let scrollState = preloaderHelper.getScrollState(
                for: chat.id,
                with: dataSource.snapshot().itemIdentifiers
            ) {
                let row = scrollState.bottomFirstVisibleRow
                let offset = scrollState.bottomFirstVisibleRowOffset
                
                if scrollState.shouldAdjustScroll && !loadingMoreItems {
                    
                    if tableView.numberOfRows(inSection: 0) > row {
                        
                        tableView.scrollToRow(
                            at: IndexPath(row: row, section: 0),
                            at: .top,
                            animated: false
                        )
                        
                        tableView.contentOffset.y = tableView.contentOffset.y + (offset + tableView.contentInset.top)
                    }
                }
                
                if scrollState.shouldPreventSetMessagesAsSeen {
                    return
                }
            }
        }
        
        if tableView.contentOffset.y <= Constants.kChatTableContentInset {
            delegate?.didScrollToBottom()
        }
    }
}

