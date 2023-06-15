//
//  NewChatTableDataSource.swift
//  sphinx
//
//  Created by Tomas Timinskas on 31/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import CoreData

protocol NewChatTableDataSourceDelegate : class {
    func configureNewMessagesIndicatorWith(newMsgCount: Int)
    func didScrollToBottom()
    func didScrollOutOfBottomArea()
    
    func shouldGoToAttachmentViewFor(messageId: Int, isPdf: Bool)
    func shouldGoToVideoPlayerFor(messageId: Int, with data: Data)
    
    func didTapOnContactWith(pubkey: String, and routeHint: String?)
    func didTapOnTribeWith(joinLink: String)
    
    func didDeleteTribe()
    func didUpdateChat(_ chat: Chat)
    
    func didLongPressOnCellWith(messageId: Int, and rowIndex: Int, bubbleViewRect: CGRect)
    func shouldShowLeaderboardFor(messageId: Int)
}

class NewChatTableDataSource : NSObject {
    
    weak var delegate: NewChatTableDataSourceDelegate?
    
    var tableView : UITableView!
    var headerImage: UIImage?
    var bottomView: UIView?
    
    var chat: Chat!
    
    var messagesResultsController: NSFetchedResultsController<TransactionMessage>!
    var currentDataSnapshot: DataSourceSnapshot!
    var dataSource: DataSource!
    
    var messageTableCellStateArray: [MessageTableCellState] = []
    var preloaderHelper = MessagesPreloaderHelper.sharedInstance
    
    var cachedMedia: [Int: MessageTableCellState.MediaData] = [:]
    
    var loadingMoreItems = false
    var scrolledAtBottom = false
    
    let bubbleHelper = NewMessageBubbleHelper()
    
    init(
        chat: Chat,
        tableView: UITableView,
        headerImageView: UIImageView?,
        bottomView: UIView,
        delegate: NewChatTableDataSourceDelegate?
    ) {
        super.init()
        
        self.chat = chat
        self.tableView = tableView
        self.headerImage = headerImageView?.image
        self.bottomView = bottomView
        self.delegate = delegate
        
        configureTableView()
        configureDataSource()
    }    
    
    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200.0
        tableView.contentInset.top = Constants.kMargin
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        tableView.delegate = self
        tableView.contentInsetAdjustmentBehavior = .never
        
        tableView.registerCell(NewMessageTableViewCell.self)
        tableView.registerCell(MessageNoBubbleTableViewCell.self)
        tableView.registerCell(NewOnlyTextMessageTableViewCell.self)
    }
}
