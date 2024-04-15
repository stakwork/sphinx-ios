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
    @IBOutlet weak var addTribeTrailing: NSLayoutConstraint!
    @IBOutlet weak var addTribeButton: UIButton!
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
    
    
    internal weak var leftMenuDelegate: LeftMenuDelegate?
    
    internal var managedObjectContext: NSManagedObjectContext!
    internal let onionConnector = SphinxOnionConnector.sharedInstance
    internal let socketManager = SphinxSocketManager.sharedInstance
    internal let actionsManager = ActionsManager.sharedInstance
    internal let contactsService = ContactsService.sharedInstance
    internal let refreshControl = UIRefreshControl()
    
    internal let newBubbleHelper = NewMessageBubbleHelper()
    
    internal let podcastPlayerController = PodcastPlayerController.sharedInstance

    internal lazy var chatsListViewModel: ChatListViewModel = {
        ChatListViewModel()
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
            tab: ChatsContainerViewController.Tab.Friends,
            chatsListDelegate: self
        )
    }()
    
    internal lazy var tribeChatsContainerViewController: ChatsContainerViewController = {
        ChatsContainerViewController.instantiate(
            tab: ChatsContainerViewController.Tab.Tribes,
            chatsListDelegate: self
        )
    }()
    
    
    internal var activeTab: DashboardTab = .friends {
        didSet {
            let newViewController = mainContentViewController(forActiveTab: activeTab)
            
            addChildVC(
                child: newViewController,
                container: mainContentContainerView
            )
            
            resetSearchField()
            loadDataOnTabChange(to: activeTab)
            feedViewMode = .rootList
            
            if (activeTab == .tribes) {
                addTribeTrailing.constant = 16
            } else {
                addTribeTrailing.constant = -120
            }
            
            UIView.animate(withDuration: 0.10) {
                self.searchBarContainer.layoutIfNeeded()
            }
        }
    }
    
    var didFinishInitialLoading = false
    let feedsManager = FeedsManager.sharedInstance
    
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
    
    func forceShowLoadingWheel() {
        didFinishInitialLoading = false
        isLoading = true
    }
    
    func forceHideLoadingWheel() {
        didFinishInitialLoading = true
        isLoading = false
    }
    
    var isLoading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(
                loading: (isLoading && didFinishInitialLoading == false) || onionConnector.isConnecting(),
                loadingWheel: headerView.loadingWheel,
                loadingWheelColor: UIColor.white,
                views: [
                    searchBarContainer,
                    bottomBarContainer
                ]
            )
        }
    }
    
    var feedViewMode: FeedViewMode = .rootList
    
    var indicesOfTabsWithNewMessages: [Int] {
        var indices = [Int]()

        if contactsService.contactsHasNewMessages {
            indices.append(1)
        }
        
        if contactsService.chatsHasNewMessages {
            indices.append(2)
        }
        
        return indices
    }
    
    var lastContentOffset: CGFloat = 0
}


// MARK: - Instantiation
extension DashboardRootViewController {
    
    static func instantiate(
        leftMenuDelegate: LeftMenuDelegate,
        managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext
    ) -> DashboardRootViewController {
        let viewController = StoryboardScene.Dashboard.dashboardRootViewController.instantiate()
        
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
        
        setupHeaderViews()
        listenForEvents()
        setupPlayerBar()
        
        restoreProgressView.delegate = self
        
        isLoading = true
        
        activeTab = .friends
        
        loadLastPlayedPod()
        
        NotificationCenter.default.removeObserver(self, name: .onContactsAndChatsChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onSizeConfigurationChanged, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(dataDidChange), name: .onContactsAndChatsChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sizeDidChange), name: .onSizeConfigurationChanged, object: nil)
        
        addAccessibilityIdentifiers()
        
        SphinxOnionManager.sharedInstance.fetchMyAccountFromState()
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
            self.connectToV2Server()
        })
    }
    
    func addAccessibilityIdentifiers(){
        bottomBar.accessibilityIdentifier = "bottomBar"
        bottomBarContainer.accessibilityIdentifier = "bottomBarContainer"
        headerView.accessibilityIdentifier = "headerView"
        searchBar.accessibilityIdentifier = "searchBar"
        searchBarContainer.accessibilityIdentifier = "searchBarContainer"
        mainContentContainerView.accessibilityIdentifier = "mainContentContainerView"
    }
    
    func loadLastPlayedPod() {
        if podcastPlayerController.isPlaying {
            return
        }
        
        if let lastPodData = feedsManager.getLastPlayedPodcastData(){
            showSmallPodcastPlayerFor(podcastData: lastPodData)
        }
    }
    
    func setupAddTribeButton(){
        addTribeButton.layer.cornerRadius = 22.0
        addTribeButton.clipsToBounds = true
    }
    
    @IBAction func didTapAddTribeButton() {
        let discoverVC = DiscoverTribesWebViewController.instantiate()
        navigationController?.pushViewController(discoverVC, animated: true)
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
        
        podcastPlayerController.finishAndSaveContentConsumed()
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
        
        setStatusBarColor()
        
        headerView.delegate = self
        
        podcastPlayerController.addDelegate(
            self,
            withKey: PodcastDelegateKeys.DashboardView.rawValue
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        podcastPlayerController.removeFromDelegatesWith(key: PodcastDelegateKeys.DashboardView.rawValue)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        headerView.updateBalance()
        headerView.showBalance()
        
        handleDeepLinksAndPush()
        
        if didFinishInitialLoading {
            loadDataOnTabChange(to: activeTab)
        }
        
        setupAddTribeButton()
        
    }
    
    func connectToV2Server(){
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewKeyExchangeReceived), name: .newContactKeyExchangeResponseWasReceived, object: nil)
        SphinxOnionManager.sharedInstance.connectToV2Server(contactRestoreCallback: contactRestoreCallback(percentage:), messageRestoreCallback: messageRestoreCallback(percentage:), hideRestoreViewCallback: hideRestoreViewCallback)
    }
    
    func hideRestoreViewCallback(){
        self.restoreProgressView.hideViewAnimated()
    }
    
    func contactRestoreCallback(percentage:Int){
        DispatchQueue.main.async {
            let value = min(percentage,100)
            self.restoreProgressView.showRestoreProgressView(
                with: value,
                label: "restoring-contacts".localized,
                buttonEnabled: false
            )
            if value >= 100 {self.restoreProgressView.hideViewAnimated()}
        }
    }
    
    func messageRestoreCallback(percentage:Int){
        let value = min(percentage,100)
        
        DispatchQueue.main.async {
            self.restoreProgressView.showRestoreProgressView(
                with: value,
                label: "restoring-messages".localized,
                buttonEnabled: true
            )
            if value >= 100 {self.restoreProgressView.hideViewAnimated()}
        }
    }
    
    @objc func handleNewKeyExchangeReceived(){
        DelayPerformedHelper.performAfterDelay(seconds: 1.0, completion: {//slight delay to ensure new DB write goes through first
            self.contactChatsContainerViewController.reloadCollectionView()
        })
    }
}



// MARK: -  Public Methods
extension DashboardRootViewController {
    
    public func handleDeepLinksAndPush() {
        handleLinkQueries()
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
            scanQRCodeButtonTouched(mode: NewQRScannerViewController.Mode.ScanAndProcessGeneric)
        case .sendSats:
            scanQRCodeButtonTouched(mode: NewQRScannerViewController.Mode.ScanAndProcessPayment)
        }
    }
    
    func scanQRCodeButtonTouched(
        mode: NewQRScannerViewController.Mode
    ) {
        let viewController = NewQRScannerViewController.instantiate(currentMode: mode)
        
        viewController.delegate = self
        
        let navigationController = UINavigationController(
            rootViewController: viewController
        )
        
        navigationController.isNavigationBarHidden = true
        present(navigationController, animated: true)
    }
    
    func transactionsHistoryButtonTouched() {
        let viewController = HistoryViewController.instantiate()
        
        presentNavigationControllerWith(vc: viewController)
    }
    
    func presentNewContactVC(pubkey:String){
        let newContactVC = NewContactViewController.instantiate(pubkey: pubkey)
        newContactVC.delegate = self
        self.present(newContactVC, animated: true)
    }
    
    
    func sendSatsButtonTouched(pubkey:String?=nil) {
        let viewController = CreateInvoiceViewController.instantiate(
            delegate: self,
            paymentMode: PaymentsViewModel.PaymentMode.send,
            preloadedPubkey: pubkey
        )
        
        presentNavigationControllerWith(vc: viewController)
    }
    
    
    func requestSatsButtonTouched() {
        let viewController = CreateInvoiceViewController.instantiate(
            delegate: self
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
        contactsService.resetSearches()
    }
    
    
    internal func handleLinkQueries() {
        if DeepLinksHandlerHelper.didHandleLinkQuery(
            vc: self,
            delegate: self
        ) {
            isLoading = false
        }
    }
    
    
    internal func loadContactsAndSyncMessages(
        shouldShowHeaderLoadingWheel: Bool = false
    ) {
        self.shouldShowHeaderLoadingWheel = shouldShowHeaderLoadingWheel
        
        isLoading = true
        headerView.updateBalance()
        
        if chatsListViewModel.isRestoring() {
            DispatchQueue.main.async {
                self.restoreProgressView.showRestoreProgressView(
                    with: 1,
                    label: "restoring-contacts".localized,
                    buttonEnabled: false
                )
            }
        }
        
        var contactsProgressShare : Float = 0.01
        
        chatsListViewModel.loadFriends(
            progressCompletion: { restoring in
                if restoring {
                    
                    contactsProgressShare += 0.01
                    
                    DispatchQueue.main.async {
                        self.restoreProgressView.showRestoreProgressView(
                            with: Int(contactsProgressShare * 100),
                            label: "restoring-contacts".localized,
                            buttonEnabled: false
                        )
                    }
                }
            }
        ) { [weak self] restoring in
            guard let self = self else { return }
            
            if restoring {
                
                DispatchQueue.main.async {
                    self.restoreProgressView.showRestoreProgressView(
                        with: Int(contactsProgressShare * 100),
                        label: "restoring-contacts".localized,
                        buttonEnabled: false
                    )
                }
                
                self.chatsListViewModel.askForNotificationPermissions()
                self.contactsService.forceUpdate()
            } else {
                self.contactsService.configureFetchResultsController()
            }
            
            var contentProgressShare : Float = 0.0
            
            self.syncContentFeedStatus(
                restoring: restoring,
                progressCallback:  { contentProgress in
                    contentProgressShare = 0.1
                    
                    if (contentProgress >= 0 && restoring) {
                        let contentProgress = Int(contentProgressShare * Float(contentProgress))
                        
                        DispatchQueue.main.async {
                            self.restoreProgressView.showRestoreProgressView(
                                with: contentProgress + Int(contactsProgressShare * 100),
                                label: "restoring-content".localized,
                                buttonEnabled: false
                            )
                        }
                    }
                },
                completionCallback: {
                    self.chatsListViewModel.syncMessages(
                        progressCallback: { progress in
                            if (restoring) {
                                self.isLoading = false
                                let messagesProgress : Int = Int(Float(progress) * (1.0 - contentProgressShare - contactsProgressShare))
                                
                                if (progress >= 0) {
                                    DispatchQueue.main.async {
                                        self.restoreProgressView.showRestoreProgressView(
                                            with: messagesProgress + Int(contentProgressShare * 100) + Int(contactsProgressShare * 100),
                                            label: "restoring-messages".localized,
                                            buttonEnabled: true
                                        )
                                    }
                                } else {
                                    self.newBubbleHelper.showLoadingWheel(text: "fetching.old.messages".localized)
                                }
                                
                                self.contactsService.forceUpdate()
                            }
                        },
                        completion: { (_,_) in
                            self.finishLoading()
                        }
                    )
                }
            )
        }
    }
    
    internal func syncContentFeedStatus(
        restoring: Bool,
        progressCallback: @escaping (Int) -> (),
        completionCallback: @escaping () -> ()
    ) {
        if !restoring {
            completionCallback()
            return
        }
        
        CoreDataManager.sharedManager.saveContext()
        
        feedsManager.restoreContentFeedStatus(
            progressCallback: { contentProgress in
                progressCallback(contentProgress)
            },
            completionCallback: {
                completionCallback()
            }
        )
    }
    
    @objc func sizeDidChange() {
        contactChatsContainerViewController.reloadCollectionView()
        tribeChatsContainerViewController.reloadCollectionView()
    }
    
    @objc func dataDidChange() {
        updateNewMessageBadges()
        
        contactChatsContainerViewController.updateWithNewChats(
            contactsService.contactListObjects
        )
        
        tribeChatsContainerViewController.updateWithNewChats(
            contactsService.chatListObjects
        )
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
        newBubbleHelper.hideLoadingWheel()
        restoreProgressView.hideViewAnimated()
        
        isLoading = false
        shouldShowHeaderLoadingWheel = false
        
        updateNewMessageBadges()
        
        didFinishInitialLoading = true
        
        contactsService.configureFetchResultsController()
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
        didRetry:Bool = false
    ) {
        
        let chatContact = contact ?? chat?.getContact()

        if handleInvite(for: contact) {
            return
        }
        
        let chatVC = NewChatViewController.instantiate(
            contactId: chatContact?.id,
            chatId: chat?.id,
            chatListViewModel: chatsListViewModel
        )
        
        navigationController?.pushViewController(chatVC, animated: shouldAnimate)
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
                if let _ = contact {
                    return
                }
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "payment.failed".localized)
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
