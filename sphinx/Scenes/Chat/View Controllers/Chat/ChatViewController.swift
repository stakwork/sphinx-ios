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
    
    var chatDataSource : ChatDataSource? = nil
    var socketManager = SphinxSocketManager.sharedInstance
    var audioHelper = AudioRecorderHelper()
    let messageBubbleHelper = NewMessageBubbleHelper()
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var chatHeaderView: ChatHeaderView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var scrollDownLabel: UILabel!
    @IBOutlet weak var webAppContainerView: UIView!
    
    var unseenMessagesCount = 0
    
    var processingPR : TransactionMessage?
    var processingPRCell : InvoiceReceivedTableViewCell?
    var webAppVC : WebAppViewController? = nil
    
    var podcastPlayerHelper: PodcastPlayerHelper? = nil
    
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
    var preventFetching = false
    
    func updateViewChat(updatedChat: Chat?) {
        if let updatedChat = updatedChat {
            if let contact = self.contact, let vcChat = contact.getConversation(), updatedChat.id == vcChat.id {
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
        preventFetching: Bool = false,
        contactsService: ContactsService,
        rootViewController: RootViewController
    ) -> ChatViewController {
        let viewController = StoryboardScene.Chat.chatViewController.instantiate()
        
        viewController.contact = contact
        viewController.chat = chat ?? contact?.getConversation()
        viewController.preventFetching = preventFetching
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
        
        podcastPlayerHelper = chat?.getPodcastPlayer()
        
        chatHeaderView.configure(chat: chat, contact: contact, contactsService: contactsService, delegate: self)
        
        accessoryView.delegate = self
        chat?.setChatMessagesAsSeen()
        updateChatInfo()
        
        ChatHelper.registerCellsForChat(tableView: chatTableView)
        chatDataSource = ChatDataSource(tableView: chatTableView, delegate: self, cellDelegate: self)
        
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
        
        if !firstLoad {
            accessoryView.show()
        }
        addObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent {
            accessoryView.removeKeyboardObservers()
            CoreDataManager.sharedManager.saveContext()
        }
        
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
        chat?.setChatMessagesAsSeen()
        reloadAndScroll(newMessageCount: newMessageCount)
        loading = false
    }
    
    func reloadAndScroll(newMessageCount: Int = 0) {
        if newMessageCount > 0 {
            chatDataSource?.setDataAndReload(contact: contact, chat: chat)
            scrollAfterInsert(count: newMessageCount)
        }
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5) {
            self.loading = false
        }
    }
    
    func initialLoad(forceReload: Bool = false) {
        chatDataSource?.setDataAndReload(contact: contact, chat: chat, forceReload: forceReload)
        scrollChatToBottom(animated: false)
    }
        
    func fetchNewData() {
        if preventFetching {
            preventFetching = false
            return
        }
        
        DispatchQueue.global().async {
            self.chatListViewModel.syncMessages(chatId: self.chat?.id, progressCallback: { _ in }) { (chatNewMessagesCount, _, _) in
                DispatchQueue.main.async {
                    self.reloadMessages(newMessageCount: chatNewMessagesCount)
                }
            }
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
}

