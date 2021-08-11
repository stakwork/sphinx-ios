//
//  DashboardRootViewController.swift
//  DashboardRootViewController
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit


class DashboardRootViewController: RootViewController {
    @IBOutlet weak var bottomBarContainer: UIView!
    @IBOutlet weak var headerView: ChatListHeader!
    @IBOutlet weak var searchBar: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchBarContainer: UIView!
    @IBOutlet weak var mainContentContainerView: UIView!
    
    @IBOutlet weak var dashboardNavigationTabs: CustomSegmentedControl! {
        didSet {
            dashboardNavigationTabs.setButtonTitles([
                "dashboard.tabs.feed".localized,
                "dashboard.tabs.friends".localized,
                "dashboard.tabs.tribes".localized,
            ])
            dashboardNavigationTabs.delegate = self
        }
    }
    

    internal var rootViewController: RootViewController!
    internal weak var leftMenuDelegate: MenuDelegate?

    internal let onionConnector = SphinxOnionConnector.sharedInstance
    internal let socketManager = SphinxSocketManager.sharedInstance
    internal let refreshControl = UIRefreshControl()
    internal let newBubbleHelper = NewMessageBubbleHelper()

    
    internal lazy var feedsListViewController = {
        FeedsListViewController.instantiate()
    }()
    
    internal lazy var chatsListViewModel: ChatListViewModel = {
        ChatListViewModel(contactsService: contactsService)
    }()
    
    internal lazy var contactChatsContainerViewController: ChatsContainerViewController = {
        ChatsContainerViewController.instantiate(
            chats: chatsListViewModel.contactChats,
            chatsListDelegate: self
        )
    }()
    
    internal lazy var tribeChatsContainerViewController: ChatsContainerViewController = {
        ChatsContainerViewController.instantiate(
            chats: chatsListViewModel.tribeChats,
            chatsListDelegate: self
        )
    }()
    
    
    internal var activeTab: DashboardTab = .feed {
        didSet {
            let newViewController = mainContentViewController(forActiveTab: activeTab)
            let oldViewController = mainContentViewController(forActiveTab: oldValue)

            oldViewController.removeFromParent()
            
            addChildVC(
                child: newViewController,
                container: mainContentContainerView
            )
            
            loadDataOnTabChange(to: activeTab)
        }
    }

    
    var isLoading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(
                loading: isLoading || onionConnector.isConnecting(),
                loadingWheel: headerView.loadingWheel,
                loadingWheelColor: UIColor.white,
                views: [
                    searchBarContainer,
                    mainContentContainerView,
                    bottomBarContainer,
                ]
            )
        }
    }
}
    

// MARK: - Instantiation
extension DashboardRootViewController {

    static func instantiate(
        rootViewController: RootViewController,
        leftMenuDelegate: MenuDelegate
    ) -> DashboardRootViewController {
        let viewController = StoryboardScene.Dashboard.dashboardRootViewController.instantiate()
        
        viewController.rootViewController = rootViewController
        viewController.leftMenuDelegate = leftMenuDelegate
        
        return viewController
    }
}


// MARK: -  Lifecycle Methods
extension DashboardRootViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = true
        searchTextField.delegate = self
        activeTab = .feed
        
        listenForEvents()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        rootViewController.setStatusBarColor(light: true)
        socketManager.setDelegate(delegate: self)
        
        configureHeader()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        headerView.showBalance()
    }
}


// MARK: -  Public Methods
extension DashboardRootViewController {
    
    //    public func goToChat() {
    //        if let chatId = UserDefaults.Keys.chatId.get(defaultValue: -1), let chat = Chat.getChatWith(id: chatId) {
    //            presentChatVC(object: chat, fromPush: true)
    //        }
    //        if let contactId = UserDefaults.Keys.contactId.get(defaultValue: -1), let contact = UserContact.getContactWith(id: contactId) {
    //            presentChatVC(object: contact, fromPush: true)
    //        }
    //        UserDefaults.Keys.contactId.removeValue()
    //        UserDefaults.Keys.chatId.removeValue()
    //    }
}


// MARK: -  Action Handling
extension DashboardRootViewController {

    @IBAction func bottomBarButtonTouched(_ sender: UIButton) {
        guard let button = BottomBarButton(rawValue: sender.tag) else {
            preconditionFailure()
        }
        
        switch button {
        case .receiveSats:
            requestSatsButtonTouched()
        case .transactionsHistory:
            transactionsHistoryButtonTouched()
        case .scanQRCode:
            scanQRCodeButtonTouched()
        case .sendSats:
            sendSatsButtonTouched()
        }
    }
    
    
    func scanQRCodeButtonTouched() {
        let viewController = NewQRScannerViewController.instantiate(
            rootViewController: rootViewController
        )
        
        viewController.delegate = self
        viewController.currentMode = .ScanAndProcess
        
        let navigationController = UINavigationController(
            rootViewController: viewController
        )
        
        navigationController.isNavigationBarHidden = true
        present(navigationController, animated: true)
    }
    
    
    func transactionsHistoryButtonTouched() {
        let viewController = HistoryViewController.instantiate(
            rootViewController: rootViewController
        )
        
        presentNavigationControllerWith(vc: viewController)
    }
    
    
    func sendSatsButtonTouched() {
        let viewController = CreateInvoiceViewController.instantiate(
            viewModel: ChatViewModel(),
            delegate: self,
            paymentMode: CreateInvoiceViewController.paymentMode.send,
            rootViewController: rootViewController
        )

        presentNavigationControllerWith(vc: viewController)
    }
    
    func requestSatsButtonTouched() {
        let viewController = CreateInvoiceViewController.instantiate(
            viewModel: ChatViewModel(),
            delegate: self,
            rootViewController: rootViewController
        )

        presentNavigationControllerWith(vc: viewController)
    }
}


// MARK: -  Private Helpers
extension DashboardRootViewController {
    
    private func mainContentViewController(
        forActiveTab activeTab: DashboardTab
    ) -> UIViewController {
        switch activeTab {
        case .feed:
            return feedsListViewController
        case .friends:
            return contactChatsContainerViewController
        case .tribes:
            return tribeChatsContainerViewController
        }
    }
    
    
    private func configureHeader() {
        headerView.delegate = self
        
        searchBarContainer.addShadow(location: VerticalLocation.bottom, opacity: 0.15, radius: 3.0)
        bottomBarContainer.addShadow(location: VerticalLocation.top, opacity: 0.2, radius: 3.0)

        searchBar.layer.borderColor = UIColor.Sphinx.Divider.resolvedCGColor(with: self.view)
        searchBar.layer.borderWidth = 1
        searchBar.layer.cornerRadius = searchBar.frame.height / 2
    }
    
    
    internal func listenForEvents() {
        headerView.listenForEvents()
        
        NotificationCenter
            .default
            .addObserver(
                forName: .onGroupDeleted,
                object: nil,
                queue: .main
            ) { [weak self] (_notification: Notification) in
                self?.loadContactsAndSyncMessages()
            }
    }
    
    
    internal func resetSearchField() {
        searchTextField?.text = ""
    }
    
    
    internal func handleLinkQueries() {
        if DeepLinksHandlerHelper.didHandleLinkQuery(
            vc: self,
            rootViewController: rootViewController,
            delegate: self
        ) {
            isLoading = false
        }
    }
    
    
    internal func loadContactsAndSyncMessages() {
        chatsListViewModel.loadFriends() { [weak self] in
            guard let self = self else { return }
            
            self.chatsListViewModel.syncMessages(
                progressCallback: { message in
                    self.isLoading = false
                    self.newBubbleHelper.showLoadingWheel(text: message)
                },
                completion: { (_,_, isRestoring) in
                    if isRestoring {
                        self.chatsListViewModel.updateContactsAndChats()
                    }
                    self.finishLoading()
                }
            )
        }
    }
    
    
    internal func loadDataOnTabChange(to activeTab: DashboardTab) {
        switch activeTab {
        case .feed:
            break
        case .friends:
            // TODO: Maybe call `loadContactsAndSyncMessages` here instead, and then set the
            // new `chats` on the active tab
            // controller within the completion handler there?
            chatsListViewModel.updateContactsAndChats()
            contactChatsContainerViewController.chats = chatsListViewModel.contactChats
        case .tribes:
            // TODO: Maybe call `loadContactsAndSyncMessages` here instead, and then set the
            // new `chats` on the active tab
            // controller within the completion handler there?
            chatsListViewModel.updateContactsAndChats()
            tribeChatsContainerViewController.chats = chatsListViewModel.tribeChats
        }
    }
    
    
    internal func finishLoading() {
        newBubbleHelper.hideLoadingWheel()
        isLoading = false
    }

    
    internal func presentChatDetailsVC(
        for chat: Chat,
        shouldAnimate: Bool = true,
        shouldFetchNewChatData: Bool = true
    ) {
        let contact = chat.getContact()
        
        let chatVC = ChatViewController.instantiate(
            contact: contact,
            chat: chat,
            preventFetching: shouldFetchNewChatData == false,
            contactsService: contactsService,
            rootViewController: rootViewController
        )
        
        navigationController?.pushViewController(chatVC, animated: shouldAnimate)
        
        resetSearchField()
    }
}


extension DashboardRootViewController {
    enum DashboardTab: Int, Hashable {
        case feed
        case friends
        case tribes
    }
}


extension DashboardRootViewController {
    enum BottomBarButton: Int, Hashable {
        case receiveSats
        case transactionsHistory
        case scanQRCode
        case sendSats
    }
}
