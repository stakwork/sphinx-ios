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
    ///New msgs indicator
    func configureNewMessagesIndicatorWith(newMsgCount: Int)
    
    ///Scrolling
    func didScrollToBottom()
    func didScrollOutOfBottomArea()
    
    ///Attachments
    func shouldGoToAttachmentViewFor(
        messageId: Int,
        isPdf: Bool,
        webViewImageURL:URL?
    )
    func shouldGoToVideoPlayerFor(messageId: Int, with data: Data)
    
    ///LinkPreviews
    func didTapOnContactWith(pubkey: String, and routeHint: String?)
    func didTapOnTribeWith(joinLink: String)
    
    ///Tribes
    func didDeleteTribe()
    
    ///First messages / Socket
    func didUpdateChat(_ chat: Chat)
    
    ///Message menu
    func didLongPressOn(cell: UITableViewCell, with messageId: Int, bubbleViewRect: CGRect, isThreadRow: Bool)
    
    ///Leaderboard
    func shouldShowLeaderboardFor(messageId: Int)
    
    ///Message reply
    func shouldReplyToMessage(message: TransactionMessage)
    
    ///File download
    func shouldOpenActivityVCFor(url: URL)
    
    ///Invoices
    func shouldPayInvoiceFor(messageId: Int)
    
    ///Calls
    func shouldDismissKeyboard()
    
    ///Messages search
    func isOnStandardMode() -> Bool
    func didFinishSearchingWith(matchesCount: Int, index: Int)
    func shouldToggleSearchLoadingWheel(active: Bool)
    
    ///Threads
    func shouldShowThreadFor(message: TransactionMessage)
    func shouldReloadThreadHeaderView()
    
    func shouldToggleThreadHeader(
        expanded: Bool,
        messageCellState: MessageTableCellState,
        mediaData: MessageTableCellState.MediaData?
    )
}

class NewChatTableDataSource : NSObject {
    
    ///Delegate
    weak var delegate: NewChatTableDataSourceDelegate?
    
    ///View references
    var tableView : UITableView!
    var headerImage: UIImage?
    var headerView: UIView!
    var bottomView: UIView!
    var webView: WKWebView!
    
    ///Chat
    var chat: Chat?
    var contact: UserContact?
    var owner: UserContact? = nil
    var pinnedMessageId: Int? = nil
    
    ///Data Source related
    var messagesResultsController: NSFetchedResultsController<TransactionMessage>!
    var additionMessagesResultsController: NSFetchedResultsController<TransactionMessage>!
    
    var currentDataSnapshot: DataSourceSnapshot!
    var dataSource: DataSource!
    
    ///Helpers
    var preloaderHelper = MessagesPreloaderHelper.sharedInstance
    let linkPreviewsLoader = CustomSwiftLinkPreview.sharedInstance
    let messageBubbleHelper = NewMessageBubbleHelper()
    let audioPlayerHelper = AudioPlayerHelper()
    var podcastPlayerController = PodcastPlayerController.sharedInstance
    
    ///Messages Data
    var messagesArray: [TransactionMessage] = []
    var messageTableCellStateArray: [MessageTableCellState] = []
    var mediaCached: [Int: MessageTableCellState.MediaData] = [:]
    var botsWebViewData: [Int: MessageTableCellState.BotWebViewData] = [:]
    var uploadingProgress: [Int: MessageTableCellState.UploadProgressData] = [:]
    
    var searchingTerm: String? = nil
    var searchMatches: [(Int, MessageTableCellState)] = []
    var currentSearchMatchIndex: Int = 0
    var isLastSearchPage = false
    
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
        headerView: UIView,
        webView: WKWebView,
        delegate: NewChatTableDataSourceDelegate?
    ) {
        super.init()
        
        self.chat = chat
        self.contact = contact
        self.owner = UserContact.getOwner()
        
        self.tableView = tableView
        self.headerImage = headerImageView?.image
        self.bottomView = bottomView
        self.headerView = headerView
        self.webView = webView
        
        self.delegate = delegate
        
        configureTableView()
        configureDataSource()
        processChatAliases()
    }
    
    func processChatAliases() {
        DispatchQueue.global(qos: .background).async {
            self.chat?.processAliases()
        }
    }
    
    func isFinalDS() -> Bool {
        return self.chat != nil
    }
    
    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200.0
        tableView.delegate = self
        tableView.contentInsetAdjustmentBehavior = .never
        configureTableTransformAndInsets()
        
        tableView.registerCell(NewMessageTableViewCell.self)
        tableView.registerCell(MessageNoBubbleTableViewCell.self)
        tableView.registerCell(NewOnlyTextMessageTableViewCell.self)
        tableView.registerCell(ThreadHeaderTableViewCell.self)
    }
    
    func configureTableTransformAndInsets() {
        tableView.contentInset.top = Constants.kMargin
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
    }
    
    func configureTableCellTransformOn(cell: ChatTableViewCellProtocol?) {
        cell?.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
    }
    
    func getMediaDataFor(messageId: Int?) -> MessageTableCellState.MediaData? {
        guard let messageId = messageId else {
            return nil
        }
        return self.mediaCached[messageId]
    }
    
    func makeCellProvider(
        for tableView: UITableView
    ) -> DataSource.CellProvider {
        { [weak self] (tableView, indexPath, dataSourceItem) -> UITableViewCell? in
            return self?.getCellFor(
                dataSourceItem: dataSourceItem,
                indexPath: indexPath
            )
        }
    }
}
