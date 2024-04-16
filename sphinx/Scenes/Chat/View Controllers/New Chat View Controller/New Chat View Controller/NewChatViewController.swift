//
//  NewChatViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 10/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import CoreData
import WebKit

class NewChatViewController: NewKeyboardHandlerViewController {
    
    @IBOutlet weak var bottomView: NewChatAccessoryView!
    @IBOutlet weak var headerView: NewChatHeaderView!
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var newMsgsIndicatorView: NewMessagesIndicatorView!
    @IBOutlet weak var botWebView: WKWebView!
    @IBOutlet weak var botWebViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var chatTableViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var mentionsAutocompleteTableView: UITableView!
    @IBOutlet weak var webAppContainerView: UIView!
    @IBOutlet weak var chatTableHeaderHeightConstraint: NSLayoutConstraint!

    var contact: UserContact?
    var chat: Chat?
    var threadUUID: String? = nil
    
    var isThread: Bool {
        get {
            return threadUUID != nil
        }
    }
    
    var messageMenuData: MessageTableCellState.MessageMenuData? = nil
    
    var contactResultsController: NSFetchedResultsController<UserContact>!
    var chatResultsController: NSFetchedResultsController<Chat>!
    
    var chatViewModel: NewChatViewModel!
    var chatListViewModel: ChatListViewModel? = nil
    
    var chatTableDataSource: NewChatTableDataSource? = nil
    var chatMentionAutocompleteDataSource : ChatMentionAutocompleteDataSource? = nil
    let messageBubbleHelper = NewMessageBubbleHelper()
    
    var webAppVC : WebAppViewController? = nil
    var isAppUrl = false
    
    enum ViewMode: Int {
        case Standard
        case MessageMenu
        case Search
    }
    
    var viewMode = ViewMode.Standard
    var macros = [MentionOrMacroItem]()
    
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        get {
            return [.bottom, .right]
        }
    }
    
    static func instantiate(
        contactId: Int? = nil,
        chatId: Int? = nil,
        chatListViewModel: ChatListViewModel? = nil,
        threadUUID: String? = nil
    ) -> NewChatViewController {
        let viewController = StoryboardScene.Chat.newChatViewController.instantiate()
        
        if let chatId = chatId {
            viewController.chat = Chat.getChatWith(id: chatId)
        }
        
        if let contactId = contactId {
            viewController.contact = UserContact.getContactWith(id: contactId)
        }
        
        viewController.threadUUID = threadUUID
        viewController.chatListViewModel = chatListViewModel
        
        viewController.chatViewModel = NewChatViewModel(
            chat: viewController.chat,
            contact: viewController.contact,
            threadUUID: threadUUID
        )
        
        viewController.popOnSwipeEnabled = true
        
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayouts()
        setDelegates()
        setupData()
        configureFetchResultsController()
        configureTableView()
        initializeMacros()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        headerView.checkRoute()
        chatTableDataSource?.startListeningToResultsController()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        fetchTribeData()
        loadReplyableMeesage()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.isMovingFromParent {
            chatTableDataSource?.saveSnapshotCurrentState()
            chatTableDataSource?.stopListeningToResultsController()

            SphinxSocketManager.sharedInstance.setDelegate(delegate: nil)

            stopPlayingClip()
        }
        
        NotificationCenter.default.removeObserver(self, name: .webViewImageClicked, object: nil)
    }
    
    func stopPlayingClip() {
        let podcastPlayerController = PodcastPlayerController.sharedInstance
        podcastPlayerController.removeFromDelegatesWith(key: PodcastDelegateKeys.ChatDataSource.rawValue)
        podcastPlayerController.pausePlayingClip()
    }
    
    override func didToggleKeyboard() {
        shouldAdjustTableViewTopInset()
        
        if let messageMenuData = messageMenuData {
            showMessageMenuFor(
                messageId: messageMenuData.messageId,
                indexPath: messageMenuData.indexPath,
                bubbleViewRect: messageMenuData.bubbleRect, isThreadRow: self.isThread
            )
            self.messageMenuData = nil
        }
    }
    
    func shouldAdjustTableViewTopInset() {
        if isThread {
           return
        }
        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
            let newInset = Constants.kChatTableContentInset + abs(self.chatTableView.frame.origin.y)
            self.chatTableView.contentInset.bottom = newInset
            self.chatTableView.verticalScrollIndicatorInsets.bottom = newInset
        })
    }
    
    func showThread(
        threadID: String
    ){
        let chatVC = NewChatViewController.instantiate(
            contactId: self.contact?.id,
            chatId: self.chat?.id,
            chatListViewModel: chatListViewModel,
            threadUUID: threadID
        )
        
        self.view.endEditing(true)
        
        navigationController?.pushViewController(
            chatVC,
            animated: true
        )
    }
    
    func setTableViewHeight() {
        let windowInsets = getWindowInsets()
        let tableHeight = UIScreen.main.bounds.height - (windowInsets.bottom + windowInsets.top) - (headerView.bounds.height) - (bottomView.bounds.height)
        
        chatTableViewHeightConstraint.constant = tableHeight
        chatTableView.layoutIfNeeded()
    }
    
    func setupLayouts() {
        headerView.superview?.bringSubviewToFront(headerView)
        
        bottomView.addShadow(location: .top, color: UIColor.black, opacity: 0.1)
        
        if !isThread {
            headerView.addShadow(location: .bottom, color: UIColor.black, opacity: 0.1)
        }
        
        botWebViewWidthConstraint.constant = ((UIScreen.main.bounds.width - (MessageTableCellState.kRowLeftMargin + MessageTableCellState.kRowRightMargin)) * MessageTableCellState.kBubbleWidthPercentage) - (MessageTableCellState.kLabelMargin * 2)
        botWebView.layoutIfNeeded()
        
    }
    
    func setupData() {
        headerView.configureHeaderWith(
            chat: chat,
            contact: contact,
            andDelegate: self,
            searchDelegate: self
        )
        
        configurePinnedMessageView()
        configureThreadHeaderAndBottomView()
        
        bottomView.updateFieldStateFrom(chat)
        showPendingApprovalMessage()
    }
    
    func configureThreadHeaderAndBottomView() {
        if
            let _ = self.threadUUID
        {
            headerView.showThreadHeaderView()
            bottomView.setupForThreads(with: self)
        }
    }
    
    func setDelegates() {
        bottomView.setDelegates(
            messageFieldDelegate: self,
            searchDelegate: self
        )
        
        SphinxSocketManager.sharedInstance.setDelegate(delegate: self)
    }
    
    private func loadReplyableMeesage() {
        if let replyableMessage = ChatTrackingHandler.shared.getReplyableMessageFor(chatId: chat?.id) {
            chatViewModel.replyingTo = replyableMessage
            
            bottomView.configureReplyViewFor(
                message: replyableMessage,
                withDelegate: self
            )
            
            shouldAdjustTableViewTopInset()
        } else {
            bottomView.resetReplyView()
        }
    }
}
