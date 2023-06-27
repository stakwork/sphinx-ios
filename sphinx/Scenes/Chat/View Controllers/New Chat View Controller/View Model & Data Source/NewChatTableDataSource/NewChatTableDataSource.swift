//
//  NewChatTableDataSource.swift
//  sphinx
//
//  Created by Tomas Timinskas on 31/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import CoreData
import WebKit

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
    
    func didLongPressOn(cell: UITableViewCell, with messageId: Int, bubbleViewRect: CGRect)
    func shouldShowLeaderboardFor(messageId: Int)
    
    func shouldReplyToMessage(message: TransactionMessage)
    func shouldOpenActivityVCFor(url: URL)
    
    func shouldPayInvoiceFor(messageId: Int)
    
    func isOnStandardMode() -> Bool
}

class NewChatTableDataSource : NSObject {
    
    ///Delegate
    weak var delegate: NewChatTableDataSourceDelegate?
    
    ///View references
    var tableView : UITableView!
    var headerImage: UIImage?
    var bottomView: UIView!
    var webView: WKWebView!
    
    ///Chat
    var chat: Chat?
    var contact: UserContact?
    
    ///Data Source related
    var messagesResultsController: NSFetchedResultsController<TransactionMessage>!
    var additionMessagesResultsController: NSFetchedResultsController<TransactionMessage>!
    
    var currentDataSnapshot: DataSourceSnapshot!
    var dataSource: DataSource!
    
    ///Helpers
    var preloaderHelper = MessagesPreloaderHelper.sharedInstance
    let linkPreviewsLoader = CustomSwiftLinkPreview.sharedInstance
    let bubbleHelper = NewMessageBubbleHelper()
    let audioPlayerHelper = AudioPlayerHelper()
    var podcastPlayerController = PodcastPlayerController.sharedInstance
    
    ///Messages Data
    var messagesArray: [TransactionMessage] = []
    var messageTableCellStateArray: [MessageTableCellState] = []
    var mediaCached: [Int: MessageTableCellState.MediaData] = [:]
    var botsWebViewData: [Int: MessageTableCellState.BotWebViewData] = [:]
    var uploadingProgress: [Int: MessageTableCellState.UploadProgressData] = [:]
    
    ///Scroll and pagination
    var messagesCount = 0
    var loadingMoreItems = false
    var scrolledAtBottom = false
    
    ///WebView Loading
    let webViewSemaphore = DispatchSemaphore(value: 1)
    var webViewLoadingCompletion: ((CGFloat?) -> ())? = nil
    
    init(
        chat: Chat?,
        contact: UserContact?,
        tableView: UITableView,
        headerImageView: UIImageView?,
        bottomView: UIView,
        webView: WKWebView,
        delegate: NewChatTableDataSourceDelegate?
    ) {
        super.init()
        
        self.chat = chat
        self.contact = contact
        
        self.tableView = tableView
        self.headerImage = headerImageView?.image
        self.bottomView = bottomView
        self.webView = webView
        
        self.delegate = delegate
        
        configureTableView()
        configureDataSource()
    }
    
    func isFinalDS() -> Bool {
        return self.chat != nil
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
