//
//  NewChatTableDataSource+PreloaderExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension NewChatTableDataSource {
    func restorePreloadedMessages() {
        if let messagesStateArray = preloaderHelper.getMessageStateArray(for: chat.id) {
            messageTableCellStateArray = messagesStateArray
            updateSnapshot()
        }
    }
    
    func saveMessagesToPreloader() {
        if let firstVisibleRow = tableView.indexPathsForVisibleRows?.last {
            preloaderHelper.add(
                messageStateArray: messageTableCellStateArray.subarray(size: max(firstVisibleRow.row + 5, 30)),
                for: chat.id
            )
        }
    }
    
    func saveSnapshotCurrentState() {
        saveMessagesToPreloader()
        
        if let firstVisibleRow = tableView.indexPathsForVisibleRows?.first {
            
            let cellRectInTable = tableView.rectForRow(at: firstVisibleRow)
            let cellOffset = tableView.convert(cellRectInTable.origin, to: bottomView)
            
            preloaderHelper.save(
                bottomFirstVisibleRow: firstVisibleRow.row,
                bottomFirstVisibleRowOffset: cellOffset.y,
                bottomFirstVisibleRowUniqueID: dataSource.snapshot().itemIdentifiers.first?.getUniqueIdentifier(),
                numberOfItems: dataSource.snapshot().numberOfItems,
                for: chat.id
            )
        }
    }
    
    func restoreScrollLastPosition() {
        loadingMoreItems = false
        
        if let scrollState = preloaderHelper.getScrollState(
            for: chat.id,
            with: dataSource.snapshot().itemIdentifiers
        ) {
            let row = scrollState.bottomFirstVisibleRow
            let offset = scrollState.bottomFirstVisibleRowOffset
            
            if scrollState.shouldAdjustScroll {
                
                tableView.scrollToRow(
                    at: IndexPath(row: row, section: 0),
                    at: .top,
                    animated: false
                )
                
                tableView.contentOffset.y = tableView.contentOffset.y + (offset + tableView.contentInset.top)
            }
            
            if scrollState.bottomFirstVisibleRow > 0 {
                return
            }
        }
        
        delegate?.didScrollToBottom()
    }
}

