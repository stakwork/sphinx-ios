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
        if let _ = threadUUID {
            return
        }
        
        guard let chat = chat else {
            return
        }
        
        if let messagesStateArray = preloaderHelper.getMessageStateArray(for: chat.id) {
            messageTableCellStateArray = messagesStateArray
            updateSnapshot()
        }
    }
    
    func saveMessagesToPreloader() {
        guard let chat = chat else {
            return
        }
        
        if let _ = threadUUID {
            return
        }
        
        if let firstVisibleRow = tableView.indexPathsForVisibleRows?.last {
            preloaderHelper.add(
                messageStateArray: messageTableCellStateArray.subarray(size: firstVisibleRow.row + 10),
                for: chat.id
            )
        }
    }
    
    func saveSnapshotCurrentState() {
        guard let chat = chat else {
            return
        }
        
        if let _ = threadUUID {
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
    
    func restoreScrollLastPosition() {
        guard let chat = chat else {
            return
        }
        
        if let _ = threadUUID {
            return
        }
        
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
        
        if tableView.contentOffset.y <= Constants.kChatTableContentInset {
            delegate?.didScrollToBottom()
        }
    }
}

