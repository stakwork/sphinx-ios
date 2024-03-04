//
//  ThreadTableDataSource.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/08/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import WebKit
import CoreData

class ThreadTableDataSource : NewChatTableDataSource {
    
    var threadUUID: String!
    var isHeaderExpanded = false
    var headerDifference: CGFloat = 0
    var numberOfRows: Int = 0
    
    init(
        chat: Chat?,
        contact: UserContact?,
        threadUUID: String,
        tableView: UITableView,
        headerImageView: UIImageView?,
        bottomView: UIView,
        headerView: UIView,
        webView: WKWebView,
        delegate: NewChatTableDataSourceDelegate?
    ) {
        
        self.threadUUID = threadUUID
        
        super.init(
            chat: chat,
            contact: contact,
            tableView: tableView,
            headerImageView: headerImageView,
            bottomView: bottomView,
            headerView: headerView,
            webView: webView,
            delegate: delegate
        )
    }
    
    override func configureTableTransformAndInsets() {
        tableView.contentInset.top = Constants.kMargin
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
    }
    
    override func configureTableCellTransformOn(cell: ChatTableViewCellProtocol?) {
        cell?.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
    }
    
    override func loadMoreItems() {
        ///Nothing to do
    }
    
    override func restorePreloadedMessages() {
        ///Nothing to do
    }

    override func saveMessagesToPreloader() {
        ///Nothing to do
    }

    override func saveSnapshotCurrentState() {
    }
    
    override func restoreScrollLastPosition() {
        DelayPerformedHelper.performAfterDelay(seconds: 0.2, completion: {
            
            self.calculateHeightAndReloadHeader()
            
            DelayPerformedHelper.performAfterDelay(seconds: 0.2, completion: {
                self.tableView.alpha = 1.0
                self.toggleHeader()
            })
       })
    }
    
    func didChangeTableContent() -> Bool {
        if numberOfRows != tableView.numberOfRows(inSection: 0) {
            numberOfRows = tableView.numberOfRows(inSection: 0)
            return true
        }
        return false
    }
    
    func calculateHeightAndReloadHeader() {
        if !didChangeTableContent() {
            return
        }
        
        let contentSizeHeight = (tableView.contentSize.height - headerDifference) + tableView.contentInset.top
        let headerHeightDifference = round(tableView.frame.height - contentSizeHeight)
        
        if headerHeightDifference > 0 && headerDifference != headerHeightDifference {
            headerDifference = headerHeightDifference
            reloadHeaderRow()
        }
    }
    
    func toggleHeader() {
        if let lastVisibleRow = tableView.indexPathsForVisibleRows?.last {
            let lastRow = tableView.numberOfRows(inSection: 0) - 1
            
            if let threadeHeaderMessageState = messageTableCellStateArray.last, threadeHeaderMessageState.isThreadHeaderMessage {
                
                let mediaData = (threadeHeaderMessageState.messageId != nil) ? self.mediaCached[threadeHeaderMessageState.messageId!] : nil
                
                if lastVisibleRow.row < lastRow {
                    delegate?.shouldToggleThreadHeader(
                        expanded: true,
                        messageCellState: threadeHeaderMessageState,
                        mediaData: mediaData
                    )
                } else {
                    let topOffset = tableView.contentSize.height - tableView.contentOffset.y - tableView.frame.height
                    let headerRowOffset = (tableView.cellForRow(at: lastVisibleRow)?.frame.height ?? 0) - topOffset
                    
                    if headerRowOffset < 56 {
                        delegate?.shouldToggleThreadHeader(
                            expanded: true,
                            messageCellState: threadeHeaderMessageState,
                            mediaData: mediaData
                        )
                    } else {
                        delegate?.shouldToggleThreadHeader(
                            expanded: false,
                            messageCellState: threadeHeaderMessageState,
                            mediaData: mediaData
                        )
                    }
                }
            }
        }
    }
    
    override func makeCellProvider(
        for tableView: UITableView
    ) -> DataSource.CellProvider {
        { [weak self] (tableView, indexPath, dataSourceItem) -> UITableViewCell? in
            guard let self else {
                return nil
            }
            
            return self.getThreadCellFor(
                dataSourceItem: dataSourceItem,
                indexPath: indexPath
            )
        }
    }
}
