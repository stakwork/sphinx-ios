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
    
    lazy var threadHeaderHeight: CGFloat? = {
        guard let headerMessageCellState = messageTableCellStateArray.last else {
            return nil
        }
        
        let kDifference:CGFloat = 56.0
        
        return ThreadHeaderTableViewCell.getCellHeightWith(
            messageCellState: headerMessageCellState,
            mediaData: nil
        ) - kDifference
    }()
    
    func getHeaderHeight() -> CGFloat? {
        guard let _ = messageTableCellStateArray.last else {
            return nil
        }
        
        return threadHeaderHeight
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
                self.toggleHeader()
                self.tableView.alpha = 1.0
            })
       })
    }
    
    func calculateHeightAndReloadHeader() {
        let headerHeightDifference = round(tableView.frame.height - tableView.contentSize.height - tableView.contentInset.top + headerDifference)
        
        if headerHeightDifference > 0 {
            self.headerDifference = headerHeightDifference
        } else if headerHeightDifference < 0 {
            self.headerDifference = 0
        }
        
        self.reloadHeaderRow()
    }
    
    func toggleHeader() {
        let headerExpanded = ((tableView.contentSize.height + tableView.contentInset.top) - tableView.frame.height) > 1
        self.delegate?.shouldToggleThreadHeader(expanded: headerExpanded)
    }
    
    override func makeCellProvider(
        for tableView: UITableView
    ) -> DataSource.CellProvider {
        { (tableView, indexPath, dataSourceItem) -> UITableViewCell in
            return self.getThreadCellFor(
                dataSourceItem: dataSourceItem,
                indexPath: indexPath
            )
        }
    }
}
