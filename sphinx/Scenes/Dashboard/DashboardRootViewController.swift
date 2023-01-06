//
//  DashboardRootViewController.swift
//  DashboardRootViewController
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import CoreData
import SwiftyJSON


class DashboardRootViewController: RootViewController {
    
    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var bottomBarContainer: UIView!
    @IBOutlet weak var dismissibleBar: CustomDismissibleView!
    @IBOutlet weak var podcastSmallPlayer: PodcastSmallPlayer!
    @IBOutlet weak var headerView: ChatListHeader!
    @IBOutlet weak var searchBar: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchBarContainer: UIView!
    @IBOutlet weak var mainContentContainerView: UIView!
    @IBOutlet weak var restoreProgressView: RestoreProgressView!
    
    @IBOutlet weak var bottomBarBottomConstraint: NSLayoutConstraint!
    
    let buttonTitles : [String] = [
        "dashboard.tabs.feed".localized,
        "dashboard.tabs.friends".localized,
        "dashboard.tabs.tribes".localized,
    ]
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
    internal let actionsManager = ActionsManager.sharedInstance
    internal let refreshControl = UIRefreshControl()
    
    internal let newBubbleHelper = NewMessageBubbleHelper()
    internal let podcastPlayerHelper = PodcastPlayerHelper.sharedInstance

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

        let contacts = chatsListViewModel.contactsService.chatListObjects.filter { $0.isConversation() }
        if contacts
            .contains(
                where: { $0.getChat()?.getReceivedUnseenMessagesCount() ?? 0 > 0 }
            )
        {
            indices.append(1)
        }
        
        let tribes = chatsListViewModel.contactsService.chatListObjects.filter { $0.isPublicGroup() }
        if tribes
            .contains(
                where: { $0.getChat()?.getReceivedUnseenMessagesCount() ?? 0 > 0 }
            )
        {
            indices.append(2)
        }
        
        return indices
    }
    
    var lastContentOffset: CGFloat = 0
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
        setupPlayerBar()
        
        restoreProgressView.delegate = self
        
        isLoading = true
        
        podcastPlayerHelper.addDelegate(
            self,
            withKey: PodcastPlayerHelper.DelegateKeys.dashboard.rawValue
        )
    }
    
    func setupPlayerBar() {
        addBlurToBottomBars()
        
        dismissibleBar.onViewDimissed = {
            self.onPlayerBarDismissed()
        }
    }
    
    func onPlayerBarDismissed() {
        podcastSmallPlayer.pauseIfPlaying()
        hideSmallPodcastPlayer()
        podcastPlayerHelper.finishAndSaveContentConsumed()
    }
    
    func addBlurEffectTo(_ view: UIView) {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.systemChromeMaterial)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        view.sendSubviewToBack(blurEffectView)
    }
    
    func addBlurToBottomBars() {
        addBlurEffectTo(bottomBarContainer)
        addBlurEffectTo(podcastSmallPlayer)
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
            presentChatDetailsVC(for: chat)
        } else if
            let contactId = UserDefaults.Keys.contactId.get(defaultValue: -1),
            let contact = UserContact.getContactWith(id: contactId)
        {
            presentChatDetailsVC(for: nil, contact: contact)
        }

        UserDefaults.Keys.contactId.removeValue()
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
        
        podcastSmallPlayer.addShadow(
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
        view.endEditing(true)
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

        chatsListViewModel.loadFriends() { [weak self] restoring in
            guard let self = self else { return }
            
            if restoring {
                self.chatsListViewModel.updateContactsAndChats()
                self.updateCurrentViewControllerData()
            }

            self.chatsListViewModel.syncMessages(
                progressCallback: { progress in
                    if (restoring) {
                        self.isLoading = false
                        
                        if (progress >= 0) {
                            self.restoreProgressView.showRestoreProgressView(with: progress)
                        } else {
                            self.newBubbleHelper.showLoadingWheel(text: "fetching.old.messages".localized)
                        }
                    }
                },
                completion: { (_,_) in
                    self.finishLoading()
                }
            )
        }
    }
    
    
    internal func updateCurrentViewControllerData() {
        updateNewMessageBadges()
        
        let queryString = searchTextField?.text ?? ""
        
        switch activeTab {
        case .feed:
            break
        case .friends:
            contactChatsContainerViewController.updateWithNewChats(
                chatsListViewModel.contactChats(fromSearchQuery: queryString)
            )
        case .tribes:
            tribeChatsContainerViewController.updateWithNewChats(
                chatsListViewModel.tribeChats(fromSearchQuery: queryString)
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
        restoreProgressView.hideViewAnimated()
        
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
        shouldAnimate: Bool = true
    ) {
        let contact = contact ?? chat?.getContact()
        
        if handleInvite(for: contact) {
            return
        }
        
        chat?.setChatMessagesAsSeen()
        
        let chatVC = ChatViewController.instantiate(
            contact: contact,
            chat: chat,
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
