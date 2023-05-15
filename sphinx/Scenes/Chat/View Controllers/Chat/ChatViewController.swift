//
//  Library
//
//  Created by Tomas Timinskas on 27/02/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import Starscream
import GiphyUISDK

class ChatViewController: KeyboardHandlerViewController {
    
    var rootViewController : RootViewController!
    var contactsService: ContactsService!
    var chatViewModel: ChatViewModel!
    var chatListViewModel: ChatListViewModel!
    
    var chatMentionAutocompleteDataSource : ChatMentionAutocompleteDataSource? = nil
    var chatDataSource : ChatDataSource? = nil
    var socketManager = SphinxSocketManager.sharedInstance
    var audioHelper = AudioRecorderHelper()
    let messageBubbleHelper = NewMessageBubbleHelper()
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var chatHeaderView: ChatHeaderView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var scrollDownLabel: UILabel!
    @IBOutlet weak var webAppContainerView: UIView!
    
    var processingPR : TransactionMessage?
    var processingPRCell : InvoiceReceivedTableViewCell?
    var webAppVC : WebAppViewController? = nil
    
    var firstLoad = true
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.Sphinx.Text, view: view)
        }
    }
    
    var keysLoading = false {
        didSet {
            chatHeaderView.keysLoading = keysLoading
        }
    }
    
    var userId = UserData.sharedInstance.getUserId()
    
    var contact: UserContact?
    var chat: Chat?
    var preventLoading = false
    
    func updateViewChat(updatedChat: Chat?) {
        if let updatedChat = updatedChat {
            if let contact = self.contact, let vcChat = contact.getChat(), updatedChat.id == vcChat.id {
                self.chat = updatedChat
            }
            
            if let vcChat = self.chat, updatedChat.id == vcChat.id {
                self.chat = updatedChat
            }
            self.chatDataSource?.chat = self.chat
        }
    }
    
    static func instantiate(
        contact: UserContact? = nil,
        chat: Chat? = nil,
        contactsService: ContactsService,
        rootViewController: RootViewController
    ) -> ChatViewController {
        let viewController = StoryboardScene.Chat.chatViewController.instantiate()
        
        viewController.contact = contact
        viewController.chat = chat ?? contact?.getChat()
        viewController.rootViewController = rootViewController
        viewController.contactsService = contactsService
        viewController.chatViewModel = ChatViewModel()
        viewController.chatListViewModel = ChatListViewModel(contactsService: contactsService)
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rootViewController.setStatusBarColor(light: false)
        configureVideoCallManager()
        addShadows()
        
//        chatHeaderView.configureWith(chat: chat, contact: contact, contactsService: contactsService, delegate: self)
        chatHeaderView.configureWith(chat: chat, contact: contact, delegate: self)
        
        accessoryView.delegate = self
        updateChatInfo()
        
        ChatHelper.registerCellsForChat(tableView: chatTableView)
        chatDataSource = ChatDataSource(tableView: chatTableView, delegate: self, cellDelegate: self)
        configureMentionAutocompleteTableView()
        
        chatHeaderView.checkRoute()
    }
    
    func addShadows() {
        headerView.addShadow(offset: CGSize(width: 0, height: 3), opacity: 0.2)
        
        scrollDownContainer.layer.cornerRadius = 10
        scrollDownContainer.addShadow(offset: CGSize(width: 1.0, height: 1.0), opacity: 0.2)
        scrollDownContainer.isHidden = true
    }
    
    override func orientationDidChanged() {
        chatTableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if preventLoading {
           preventLoading = false
           return
        }
        
        UserDefaults.Keys.chatId.removeValue()
        socketManager.setDelegate(delegate: self)
        loadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        if firstLoad == false {
            accessoryView.show()
        }
        addObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent {
            accessoryView.removeKeyboardObservers()
            
            PodcastPlayerController.sharedInstance.removeFromDelegatesWith(
                key: PodcastDelegateKeys.ChatSmallPlayerBar.rawValue
            )
        }
        setLastReadMessage()
        CustomAudioPlayer.sharedInstance.stopAndReset()
        API.sharedInstance.cleanMessagesRequest()
        removeObservers()
    }
    
    func keyboardWillShow(_ notification: Notification) {
        keyboardWillShowHandler(notification, tableView: chatTableView)
    }
    
    func keyboardWillHide(_ notification: Notification) {
        keyboardWillHideHandler(notification, tableView: chatTableView)
    }
    
    func updateChatInfo() {
        accessoryView.updateFromChat(chat)
        
        chat?.updateTribeInfo() {
            self.chatHeaderView.setChatInfo()
            self.loadPodcastFeed()
        }
        
        if chat?.isStatusPending() ?? false {
            NewMessageBubbleHelper().showGenericMessageView(text: "waiting.admin.approval".localized)
        }
    }
    
    
    func loadData(showLoadingWheel: Bool = true) {
        chatHeaderView.setChatInfo()
        initialLoad()
        fetchNewData()
    }
    
    func reloadMessages(newMessageCount: Int = 0) {
        reloadAndScroll(newMessageCount: newMessageCount)
        loading = false
    }
    
    func reloadAndScroll(newMessageCount: Int = 0) {
        if newMessageCount > 0 {
            chatDataSource?.setDataAndReload(contact: contact, chat: chat)
        }
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5) {
            self.loading = false
        }
    }
    
    func initialLoad(forceReload: Bool = false) {
        chatDataSource?.setDataAndReload(contact: contact, chat: chat, forceReload: forceReload)
        
        if let chat = chat,
           let tablePosition = GroupsManager.sharedInstance.getChatLastRead(chatID: chat.id) {
            
            chatTableView.scrollToOffset(yPosition: tablePosition.1)
            
            let isPositionAtBottom = chatTableView.isPositionAtBottom(
                yPosition: tablePosition.1,
                accessoryViewHeight: accessoryView.viewContentSize().height
            )
            
            scrollDownLabel.text = chat.unseenMessagesCountLabel
            scrollDownContainer.isHidden = isPositionAtBottom
        } else {
            scrollChatToBottom(animated: false)
            didScrollToBottom()
        }
    }
        
    func fetchNewData() {
        chatListViewModel.tribeUUID = chat?.uuid
        DispatchQueue.global().async {
            self.chatListViewModel.syncMessages(chatId: self.chat?.id, progressCallback: { _ in }) { (chatNewMessagesCount, _) in
                DispatchQueue.main.async {
                    self.reloadMessages(newMessageCount: chatNewMessagesCount)
                    self.chatListViewModel.getChatBadges(chat: self.chat)
                }
            }
        }
    }
    
    func setLastReadMessage(){
        if let dataSource = chatDataSource,
           let tablePosition = dataSource.getTableViewPosition(),
           let valid_chat = chat
        {
            GroupsManager.sharedInstance.setChatLastRead(chatID: valid_chat.id, tablePosition: tablePosition)
        }
    }
    
    func toggleWebAppContainer() {
        let shouldShow = webAppContainerView.isHidden
        
        if shouldShow {
            if let chat = chat, webAppVC == nil {
                webAppVC = WebAppViewController.instantiate(chat: chat)
            }
            addChildVC(child: webAppVC!, container: webAppContainerView)
        }
        
        toggleBottomBar(show: !shouldShow)
        chatHeaderView.toggleWebAppIcon(showChatIcon: shouldShow)
        webAppContainerView.isHidden = !webAppContainerView.isHidden
    }
    
    func toggleBottomBar(show: Bool) {
        if show {
            accessoryView.show()
        } else {
            accessoryView.hide()
        }
    }
    
    @IBAction func scrollDownButtonTouched() {
        scrollChatToBottom()
    }
    
    func configureMentionAutocompleteTableView(){
        mentionAutoCompleteTableView.isHidden = true
        chatMentionAutocompleteDataSource = ChatMentionAutocompleteDataSource(tableView: mentionAutoCompleteTableView,delegate:self)
        mentionAutoCompleteTableView.delegate = chatMentionAutocompleteDataSource
        mentionAutoCompleteTableView.dataSource = chatMentionAutocompleteDataSource
    }
}


extension ChatViewController:ChatMentionAutocompleteDelegate{
    func processAutocomplete(text: String) {
        print(text)
        NotificationCenter.default.post(name: NSNotification.Name.autocompleteMention, object: text)
    }
    
    
}
