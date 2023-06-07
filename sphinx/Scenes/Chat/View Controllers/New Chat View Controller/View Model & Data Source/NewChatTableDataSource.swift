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
    
    var cachedImages: [String: UIImage] = [:]
    
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
        tableView.contentInset = UIEdgeInsets(top: Constants.kMargin, left: 0, bottom: Constants.kMargin, right: 0)
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        tableView.registerCell(NewMessageTableViewCell.self)
        tableView.registerCell(MessageNoBubbleTableViewCell.self)
    }
}
