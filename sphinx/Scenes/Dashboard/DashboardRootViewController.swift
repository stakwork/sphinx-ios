//
//  DashboardRootViewController.swift
//  DashboardRootViewController
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import CoreData


class DashboardRootViewController: RootViewController {
    @IBOutlet weak var bottomBarContainer: UIView!
    @IBOutlet weak var headerView: ChatListHeader!
    @IBOutlet weak var searchBar: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchBarContainer: UIView!
    @IBOutlet weak var mainContentContainerView: UIView!
    
    @IBOutlet weak var dashboardNavigationTabs: CustomSegmentedControl! {
        didSet {
            dashboardNavigationTabs.configureFromOutlet(
                buttonTitles: [
                    "dashboard.tabs.feed".localized,
                    "dashboard.tabs.friends".localized,
                    "dashboard.tabs.tribes".localized,
                ],
                initialIndex: 1,
                delegate: self
            )
        }
    }
    
    
    internal var rootViewController: RootViewController!
    internal weak var leftMenuDelegate: LeftMenuDelegate?
    
    internal var managedObjectContext: NSManagedObjectContext!
    internal let onionConnector = SphinxOnionConnector.sharedInstance
    internal let socketManager = SphinxSocketManager.sharedInstance
    internal let refreshControl = UIRefreshControl()
    internal let newBubbleHelper = NewMessageBubbleHelper()
    

    internal lazy var chatsListViewModel: ChatListViewModel = {
        ChatListViewModel(contactsService: contactsService)
    }()
    
    
    internal lazy var feedsContainerViewController = {
        DashboardFeedsContainerViewController.instantiate(
            feedsListContainerDelegate: self
        )
    }()
    
    
    internal lazy var feedSearchResultsContainerViewController = {
        FeedSearchContainerViewController.instantiate(
            resultsDelegate: self
        )
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
    
    
    internal var activeTab: DashboardTab = .friends {
        didSet {
            let newViewController = mainContentViewController(forActiveTab: activeTab)
            let oldViewController = mainContentViewController(forActiveTab: oldValue)
            
            removeChildVC(child: oldViewController)
            
            addChildVC(
                child: newViewController,
                container: mainContentContainerView
            )
            
            resetSearchField()
            loadDataOnTabChange(to: activeTab)
            feedViewMode = .rootList
        }
    }
    
    var didFinishInitialLoading = false
    
    var shouldShowHeaderLoadingWheel = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(
                loading: shouldShowHeaderLoadingWheel,
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
    
    
    var isLoading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(
                loading:
                    (isLoading && didFinishInitialLoading == false)
                    || onionConnector.isConnecting(),
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
    
    
    var feedViewMode: FeedViewMode = .rootList
    
    var indicesOfTabsWithNewMessages: [Int] {
        var indices = [Int]()
        
        if chatsListViewModel
            .contactChats
            .contains(
                where: { $0.getChat()?.getReceivedUnseenMessagesCount() ?? 0 > 0 }
            )
        {
            indices.append(1)
        }
        
        if chatsListViewModel
            .tribeChats
            .contains(
                where: { $0.getChat()?.getReceivedUnseenMessagesCount() ?? 0 > 0 }
            )
        {
            indices.append(2)
        }
        
        return indices
    }
}


// MARK: - Instantiation
extension DashboardRootViewController {
    
    static func instantiate(
        rootViewController: RootViewController,
        leftMenuDelegate: LeftMenuDelegate,
        managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext
    ) -> DashboardRootViewController {
        let viewController = StoryboardScene.Dashboard.dashboardRootViewController.instantiate()
        
        viewController.rootViewController = rootViewController
        viewController.leftMenuDelegate = leftMenuDelegate
        viewController.managedObjectContext = managedObjectContext
        
        return viewController
    }
}


// MARK: -  Lifecycle Methods
extension DashboardRootViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = true
        searchTextField.delegate = self
        activeTab = .friends
        
        setupHeaderViews()
        listenForEvents()
        
        isLoading = true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        rootViewController.setStatusBarColor(light: true)
        socketManager.setDelegate(delegate: self)
        headerView.delegate = self
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        headerView.updateBalance()
        headerView.showBalance()
        
        handleDeepLinksAndPush()
        
        if didFinishInitialLoading {
            loadDataOnTabChange(to: activeTab)
        }
    }
}


// MARK: -  Public Methods
extension DashboardRootViewController {
    
    public func handleDeepLinksAndPush() {
        deepLinkIntoChatDetails()
        handleLinkQueries()
    }

    
    public func deepLinkIntoChatDetails() {
        if
            let chatId = UserDefaults.Keys.chatId.get(defaultValue: -1),
            let chat = Chat.getChatWith(id: chatId)
        {
            presentChatDetailsVC(for: chat, shouldFetchNewChatData: true)
        }

        UserDefaults.Keys.chatId.removeValue()
    }
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
            return feedsContainerViewController
        case .friends:
            return contactChatsContainerViewController
        case .tribes:
            return tribeChatsContainerViewController
        }
    }
    
    
    internal func setupHeaderViews() {
        searchBarContainer.addShadow(
            location: VerticalLocation.bottom,
            opacity: 0.15,
            radius: 3.0
        )
        
        bottomBarContainer.addShadow(
            location: VerticalLocation.top,
            opacity: 0.2,
            radius: 3.0
        )
        
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
    
    
    internal func loadContactsAndSyncMessages(
        shouldShowHeaderLoadingWheel: Bool = false
    ) {
        updateCurrentViewControllerData()
        
        self.shouldShowHeaderLoadingWheel = shouldShowHeaderLoadingWheel
        
        isLoading = true
        headerView.updateBalance()

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
    
    
    internal func updateCurrentViewControllerData() {
        updateNewMessageBadges()
        
        switch activeTab {
        case .feed:
            break
        case .friends:
            contactChatsContainerViewController.updateWithNewChats(
                chatsListViewModel.contactChats
            )
        case .tribes:
            tribeChatsContainerViewController.updateWithNewChats(
                chatsListViewModel.tribeChats
            )
        }
    }
    
    
    internal func loadDataOnTabChange(to activeTab: DashboardTab) {
        switch activeTab {
        case .feed:
            finishLoading()
        case .friends:
            loadContactsAndSyncMessages()
        case .tribes:
            loadContactsAndSyncMessages()
        }
    }
    
    
    internal func finishLoading() {
        defer { didFinishInitialLoading = true }
        
        updateCurrentViewControllerData()
        
        newBubbleHelper.hideLoadingWheel()
        isLoading = false
        shouldShowHeaderLoadingWheel = false
        
        updateNewMessageBadges()
    }
    
    
    internal func updateNewMessageBadges() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            
            self.dashboardNavigationTabs.indicesOfTitlesWithBadge = self.indicesOfTabsWithNewMessages
        }
    }
    
    
    internal func presentChatDetailsVC(
        for chat: Chat?,
        contact: UserContact? = nil,
        shouldAnimate: Bool = true,
        shouldFetchNewChatData: Bool = true
    ) {
        let contact = contact ?? chat?.getContact()
        
        if handleInvite(for: contact) {
            return
        }
        
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
    
    private func handleInvite(for contact: UserContact?) -> Bool {
        if let invite = contact?.invite, (contact?.isPending() ?? false) {
            
            if invite.isPendingPayment() && !invite.isPaymentProcessed() {
                
                payInvite(invite: invite)
                
            } else {
                
                let (ready, title, message) = invite.getInviteStatusForAlert()
                
                if ready {
                    goToInviteCodeString(inviteCode: contact?.invite?.inviteString ?? "")
                } else {
                    AlertHelper.showAlert(title: title, message: message)
                }
                
            }
            return true
        }
        return false
    }
    
    private func goToInviteCodeString(
        inviteCode: String
    ) {
        guard !inviteCode.isEmpty else {
            return
        }
        let confirmAddfriendVC = ShareInviteCodeViewController.instantiate()
        confirmAddfriendVC.qrCodeString = inviteCode
        navigationController?.present(confirmAddfriendVC, animated: true, completion: nil)
    }
    
    private func payInvite(invite: UserInvite) {
        AlertHelper.showTwoOptionsAlert(title: "pay.invitation".localized, message: "", confirm: {
            self.chatsListViewModel.payInvite(invite: invite, completion: { contact in
                if let contact = contact {
                    self.didUpdateContact(contact: contact)
                } else {
                    AlertHelper.showAlert(title: "generic.error.title".localized, message: "payment.failed".localized)
                }
            })
        })
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
    enum FeedViewMode {
        case rootList
        case searching
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
