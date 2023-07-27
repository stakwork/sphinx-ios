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
        if isThread {
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
        if isThread {
            return
        }
        
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
    
    func saveSnapshotCurrentState() {
        if isThread {
            return
        }
        
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
    
    func restoreScrollLastPosition() {
        if isThread {
            scrollToTop()
            return
        }
        
        guard let chat = chat else {
            return
        }
        
        tableView.alpha = 1.0
        
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
    
    func scrollToTop() {
        if firstLoad {
            ///Scroll to bottom just if it's first load of the view
            DelayPerformedHelper.performAfterDelay(seconds: 0.2, completion: {
                self.tableView.scrollToBottom(animated: false)
                
                DelayPerformedHelper.performAfterDelay(seconds: 0.1, completion: {
                    self.tableView.alpha = 1.0
                    self.newMsgIndicator.isHidden = false
                })
            })
            firstLoad = false
        }
    }
}

