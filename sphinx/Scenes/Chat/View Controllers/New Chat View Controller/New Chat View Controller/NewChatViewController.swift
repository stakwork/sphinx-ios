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
    
    enum ViewMode: Int {
        case Standard
        case MessageMenu
        case Search
    }
    
    var viewMode = ViewMode.Standard
    var macros = [MentionOrMacroItem]()
    var isOnionChat : Bool = false
    
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        get {
            return [.bottom, .right]
        }
    }
    
    func getDemoContact()->UserContact{
        let contact = UserContact()
        contact.id = 21000000
        contact.nickname = "Satoshi Nakamoto"
        contact.nodeAlias = "Satoshi Nakamoto"
        contact.avatarUrl = "https://i.etsystatic.com/10433030/r/il/95cf98/2698300717/il_1080xN.2698300717_qt5w.jpg"
        return contact
    }
    
    static func instantiate(
        contactId: Int? = nil,
        chatId: Int? = nil,
        chatListViewModel: ChatListViewModel? = nil,
        threadUUID: String? = nil,
        isOnionChat: Bool = false
    ) -> NewChatViewController {
        let viewController = StoryboardScene.Chat.newChatViewController.instantiate()
        
        if let chatId = chatId {
            viewController.chat = Chat.getChatWith(id: chatId)
        }
        
        if let contactId = contactId {
            viewController.contact = UserContact.getContactWith(id: contactId)
        }
        
        viewController.isOnionChat = isOnionChat
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
        do_onion_things()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.isMovingFromParent {
            chatTableDataSource?.saveSnapshotCurrentState()
            chatTableDataSource?.stopListeningToResultsController()

            chat?.setOngoingMessage(text: bottomView.getMessage())

            SphinxSocketManager.sharedInstance.setDelegate(delegate: nil)

            stopPlayingClip()
        }
        
        NotificationCenter.default.removeObserver(self, name: .webViewImageClicked, object: nil)
    }
    
    func do_onion_things(){
        isOnionChat ? run_onion_message_sandbox_example() : ()
        bottomView.messageFieldView.isOnionChat = self.isOnionChat
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            context.parent = CoreDataManager.sharedManager.persistentContainer.viewContext
            
            let chat = Chat(context: context)
            chat.id = -1
            self.chat = chat
            let placeholderAvatar = "https://website.sphinx.chat/wp-content/uploads/2021/11/Sphinx-Logo-V1-600px.png"
            let contact = UserContact.createObject(id: 0, publicKey: "0", nodeAlias: nil, nickname: nil, avatarUrl: placeholderAvatar, isOwner: true, fromGroup: false, blocked: false, status: 0, contactKey: nil, notificationSound: nil, privatePhoto: false, tipAmount: 0, routeHint: nil, inviteString: nil, welcomeMessage: nil, inviteStatus: 0, date: Date())
            //contact.avatarUrl = "https://website.sphinx.chat/wp-content/uploads/2021/11/Sphinx-Logo-V1-600px.png"
            chat.conversationContact = contact
            chat.saveChat()
            self.chatViewModel = NewChatViewModel(chat: chat, contact: contact)
            let ds = NewChatTableDataSource(
                chat: self.chat,
                contact: self.contact,
                tableView: self.chatTableView,
                headerImageView: nil,
                bottomView: self.bottomView,
                headerView: self.headerView,
                webView: self.botWebView,
                delegate: self
            )
            self.chatViewModel.setDataSource(ds)
        })
        
        NotificationCenter.default.addObserver(forName: .onOnionMessageReceived, object: nil, queue: OperationQueue.main) { (n: Notification) in
            let object = n.object
            if let message = object as? TransactionMessage{
                print(message)
                if let ds = self.chatViewModel.chatDataSource{
                    message.senderId = 402
                    ds.messagesArray.append(message)
                    ds.forceReload()
                }
            }
            print("onion message received")
        }
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
                bubbleViewRect: messageMenuData.bubbleRect
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
    
    func run_onion_message_sandbox_example(){
        let test_mnemonic1 = CrypterManager.sharedInstance.test_mnemonic1
        var seed : String? = nil
        do{
            seed = try mnemonicToSeed(mnemonic: test_mnemonic1)
        }
        catch{
            
        }
        guard let seed = seed else{
            AlertHelper.showAlert(title: "Onion Message Example Error:", message: "Failed to generate example seed.")
            return
        }
        print(seed)
        CrypterManager.sharedInstance.setupOnionMessengerMqtt(seed: seed)
    }
    
    func setupData() {
        if(isOnionChat == true){
//            let demoContact = getDemoContact()
//            let demoChat = demoContact.getFakeChat()
//            headerView.configureHeaderWith(chat: demoChat, contact: demoContact, andDelegate: self,searchDelegate: self)
        }
        else{
            headerView.configureHeaderWith(
                chat: chat,
                contact: contact,
                andDelegate: self,
                searchDelegate: self
            )
        }
        
        
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
}
