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
    
    var chat: Chat!
    
    var messagesResultsController: NSFetchedResultsController<TransactionMessage>!
    var currentDataSnapshot: DataSourceSnapshot!
    var dataSource: DataSource!
    
    var messageTableCellStateArray: [MessageTableCellState] = []
    
    init(
        chat: Chat,
        tableView: UITableView
    ) {
        super.init()
        
        self.chat = chat
        self.tableView = tableView
        
        registerCells()
        configureDataSource()
        configureResultsController()
    }
    
    func registerCells() {
        tableView.registerCell(NewMessageTableViewCell.self)
        tableView.registerCell(MessageNoBubbleTableViewCell.self)
    }
}
