//
//  NewChatTableDataSource.swift
//  sphinx
//
//  Created by Tomas Timinskas on 31/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import CoreData

class NewChatTableDataSource : NSObject {
    
    var tableView : UITableView!
    var headerImage: UIImage?
    
    var chat: Chat!
    
    var messagesResultsController: NSFetchedResultsController<TransactionMessage>!
    var currentDataSnapshot: DataSourceSnapshot!
    var dataSource: DataSource!
    
    var messageTableCellStateArray: [MessageTableCellState] = []
    var preloaderHelper = MessagesPreloaderHelper.sharedInstance
    
    var cachedMedia: [Int: MessageTableCellState.MediaData] = [:]
    var tribeLinks: [Int: MessageTableCellState.LinkTribe] = [:]
    
    init(
        chat: Chat,
        tableView: UITableView,
        headerImageView: UIImageView?
    ) {
        super.init()
        
        self.chat = chat
        self.tableView = tableView
        self.headerImage = headerImageView?.image
        
        configureTableView()
        configureDataSource()
        configureResultsController()
    }    
    
    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200.0
        tableView.contentInset.top = Constants.kMargin
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        tableView.registerCell(NewMessageTableViewCell.self)
        tableView.registerCell(MessageNoBubbleTableViewCell.self)
        tableView.registerCell(NewOnlyTextMessageTableViewCell.self)
    }
}
