//
//  Library
//
//  Created by Tomas Timinskas on 07/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import SwiftyJSON
import KYDrawerController

protocol MenuDelegate: class {
    func shouldOpenLeftMenu()
}

class ChatListViewController: RootViewController, ChatListHeaderDelegate {
    
    var rootViewController : RootViewController!
    
    private weak var delegate: MenuDelegate?
    
    var chatListDataSource : ChatListDataSource? = nil
    var chatListViewModel: ChatListViewModel!
    var chatViewModel: ChatViewModel!
    var socketManager = SphinxSocketManager.sharedInstance
    var onionConneter = SphinxOnionConnector.sharedInstance

    @IBOutlet weak var bottomBarContainer: UIView!
    @IBOutlet weak var chatListTableView: UITableView!
    @IBOutlet weak var headerView: ChatListHeader!
    @IBOutlet weak var searchBar: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchBarContainer: UIView!
    
    enum bottomBarButtons: Int {
        case receive = 0
        case transactions
        case code
        case send
    }
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading || onionConneter.isConnecting(), loadingWheel: headerView.loadingWheel, loadingWheelColor: UIColor.white, views: [chatListTableView, bottomBarContainer, searchBarContainer])
        }
    }
    
    var loadingRefresh = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loadingRefresh || onionConneter.isConnecting(), loadingWheel: headerView.loadingWheel, loadingWheelColor: UIColor.white)
        }
    }
    
    override var inputAccessoryView: UIView? { return nil }
    override var canBecomeFirstResponder: Bool { return false }
    
    private let refreshControl = UIRefreshControl()
    private let newBubbleHelper = NewMessageBubbleHelper()
    
    var chatListObjectsArray = [ChatListCommonObject]()
    
    var shouldReloadFriends = true
    
    var userId = UserData.sharedInstance.getUserId()
    
    static func instantiate(rootViewController : RootViewController, delegate: MenuDelegate) -> ChatListViewController {
        let contactsService = ContactsService()
        let viewController = StoryboardScene.Chat.chatListViewController.instantiate()
        viewController.rootViewController = rootViewController
        viewController.delegate = delegate
        viewController.chatListViewModel = ChatListViewModel(contactsService: contactsService)
        viewController.chatViewModel = ChatViewModel()
        viewController.contactsService = contactsService
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        
        chatListTableView.registerCell(ChatListTableViewCell.self)
        chatListTableView.registerCell(AddContactTableViewCell.self)
        
        chatListTableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshOnPull(sender:)), for: .valueChanged)
        
        searchTextField.delegate = self
        
        listenForEvents()
        loading = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        rootViewController.setStatusBarColor(light: true)
        
        socketManager.setDelegate(delegate: self)
        updateContactsAndReload()
        configureHeader()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        headerView.showBalance()
        
        if shouldReloadFriends {
            loading = true
            loadFriendAndReload()
        } else {
            initialLoad()
        }
        handleDeepLinksAndPush()
    }
    
    func handleDeepLinksAndPush() {
        goToChat()
        handleLinkQueries()
    }
    
    func loadMessages() {
        headerView.updateBalance()
        updateContactsAndReload()
        
        self.chatListViewModel.syncMessages(progressCallback: { message in
            self.loading = false
            self.newBubbleHelper.showLoadingWheel(text: message)
        }) { (_,_) in
            self.updateContactsAndReload()
            self.finishLoading()
        }
    }
    
    func loadFriendAndReload() {
        guard let chatListViewModel = chatListViewModel else {
            return
        }
        loadingRefresh = true
        
        chatListViewModel.loadFriends() {
            self.userId = UserData.sharedInstance.getUserId()
            self.loadMessages()
        }
    }
    
    func goToChat() {
        if let chatId = UserDefaults.Keys.chatId.get(defaultValue: -1), let chat = Chat.getChatWith(id: chatId) {
            presentChatVC(object: chat, fromPush: true)
        }
        if let contactId = UserDefaults.Keys.contactId.get(defaultValue: -1), let contact = UserContact.getContactWith(id: contactId) {
            presentChatVC(object: contact, fromPush: true)
        }
        UserDefaults.Keys.contactId.removeValue()
        UserDefaults.Keys.chatId.removeValue()
    }
    
    func handleLinkQueries() {
        if DeepLinksHandlerHelper.didHandleLinkQuery(vc: self, rootViewController: rootViewController, delegate: self) {
            loading = false
        }
    }
    
    @objc func refreshOnPull(sender: UIRefreshControl) {
        loadFriendAndReload()
        loadingRefresh = false
    }
    
    func updateContactsAndReload(shouldReload: Bool = false) {
        if shouldReload {
            loadFriendAndReload()
            return
        }
        initialLoad()
    }
    
    func initialLoad(_ fromBackgroundReload: Bool = false) {
        chatListViewModel.updateContactsAndChats()
        chatListObjectsArray = contactsService.getChatListObjects(fromBackgroundReload)
        loadDataSource()
        
        refreshControl.endRefreshing()
    }
    
    func loadDataSource() {
        guard let tableView = chatListTableView  else {
            return
        }
        if chatListDataSource == nil {
            chatListDataSource = ChatListDataSource(tableView: tableView, delegate: self)
        }
        chatListDataSource?.setDataAndReload(chatListObjects: chatListObjectsArray)
    }
    
    func finishLoading() {
        newBubbleHelper.hideLoadingWheel()
        loading = false
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.navigationController?.present(alert, animated: true, completion: nil)
    }
    
    func leftMenuButtonTouched() {
        shouldReloadFriends = false
        delegate?.shouldOpenLeftMenu()
    }
    
    @IBAction func bottomBarButtonTouched(_ sender: UIButton) {
        switch (bottomBarButtons(rawValue: sender.tag)!) {
        case bottomBarButtons.receive:
            requestButtonTouched()
        case bottomBarButtons.transactions:
            historyButtonTouched()
        case bottomBarButtons.code:
            scannerTouched()
        case bottomBarButtons.send:
            sendButtonTouched()
        }
    }
    
    func scannerTouched() {
        let viewController = NewQRScannerViewController.instantiate(rootViewController: rootViewController)
        viewController.delegate = self
        viewController.currentMode = NewQRScannerViewController.Mode.ScanAndProcess
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.isNavigationBarHidden = true
        self.present(navigationController, animated: true)
    }
    
    func historyButtonTouched() {
        let viewController = HistoryViewController.instantiate(rootViewController: rootViewController)
        self.presentNavigationControllerWith(vc: viewController)
    }
    
    func sendButtonTouched() {
        let viewController = CreateInvoiceViewController.instantiate(viewModel: chatViewModel, delegate: self, paymentMode: CreateInvoiceViewController.paymentMode.send, rootViewController: rootViewController)
        self.presentNavigationControllerWith(vc: viewController)
    }
    
    func requestButtonTouched() {
        let viewController = CreateInvoiceViewController.instantiate(viewModel: chatViewModel, delegate: self, rootViewController: rootViewController)
        self.presentNavigationControllerWith(vc: viewController)
    }
}

extension ChatListViewController : PaymentInvoiceDelegate {
    func willDismissPresentedView(paymentCreated: Bool) {
        rootViewController.setStatusBarColor(light: true)
        headerView.updateBalance()
    }
}
