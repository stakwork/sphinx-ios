//
//  DashboardRootViewController.swift
//  DashboardRootViewController
//
//  Created by Brian Sipple on 7/22/21.
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit


class DashboardRootViewController: UIViewController {
    @IBOutlet weak var bottomBarContainer: UIView!
//    @IBOutlet weak var chatListTableView: UITableView!
//    @IBOutlet weak var navigationTabsView: DashboardNavigationTabsView!
    @IBOutlet weak var headerView: ChatListHeader!
    @IBOutlet weak var searchBar: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchBarContainer: UIView!
    @IBOutlet weak var mainContentContainerView: UIView!
    
    @IBOutlet weak var dashboardNavigationTabs: CustomSegmentedControl! {
        didSet {
            dashboardNavigationTabs.setButtonTitles([
                "Feed",
                "Friends",
                "Tribes"
            ])
//            dashboardNavigationTabs.selectorViewColor = .orange
//            dashboardNavigationTabs.activeTextColor = .orange
            dashboardNavigationTabs.delegate = self
        }
    }
    

    private var rootViewController: RootViewController!
    private weak var leftMenuDelegate: MenuDelegate?

    
    private lazy var feedsListViewController = {
        FeedsListViewController.instantiate()
    }()
    
    private lazy var friendsListViewController = {
        FriendsListViewController.instantiate()
    }()
    
    private lazy var tribesListViewController = {
        TribesListViewController.instantiate()
    }()
    
    
    private var activeTab: DashboardTab? {
        didSet {
            guard let newActiveTab = activeTab else { return }
            
            let newViewController = mainContentViewController(forActiveTab: newActiveTab)
            
            if let oldActiveTab = oldValue {
                let oldViewController = mainContentViewController(forActiveTab: oldActiveTab)
                oldViewController.removeFromParent()
            }
            
            addChildVC(
                child: newViewController,
                container: mainContentContainerView
            )
        }
    }

    
    var socketManager = SphinxSocketManager.sharedInstance
    var onionConnecter = SphinxOnionConnector.sharedInstance
    
    
    
    static func instantiate(
        rootViewController: RootViewController,
        leftMenuDelegate: MenuDelegate
    ) -> DashboardRootViewController {
        let viewController = StoryboardScene.Dashboard.dashboardRootViewController.instantiate()
        
        viewController.rootViewController = rootViewController
        viewController.leftMenuDelegate = leftMenuDelegate
        
        return viewController
    }
    
    
    var isLoading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(
                loading: isLoading || onionConnecter.isConnecting(),
                loadingWheel: headerView.loadingWheel,
                loadingWheelColor: UIColor.white,
                views: [
                    mainContentContainerView,
                    bottomBarContainer,
                    searchBarContainer
                ]
            )
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = true
        searchTextField.delegate = self
        activeTab = .feed
        
//        listenForEvents()
        isLoading = true
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
//        initialLoad()
//        handleDeepLinksAndPush()
    }
    
    
    func handleLinkQueries() {
        if DeepLinksHandlerHelper.didHandleLinkQuery(
            vc: self,
            rootViewController: rootViewController,
            delegate: self
        ) {
            isLoading = false
        }
    }
    
    
    func leftMenuButtonTouched() {
//        shouldReloadFriends = false
        leftMenuDelegate?.shouldOpenLeftMenu()
    }
    
    
    @IBAction func bottomBarButtonTouched(_ sender: UIButton) {
//        switch (bottomBarButtons(rawValue: sender.tag)!) {
//        case bottomBarButtons.receive:
//            requestButtonTouched()
//        case bottomBarButtons.transactions:
//            historyButtonTouched()
//        case bottomBarButtons.code:
//            scannerTouched()
//        case bottomBarButtons.send:
//            sendButtonTouched()
//        }
    }
    
    
    private func mainContentViewController(forActiveTab activeTab: DashboardTab) -> UIViewController {
        switch activeTab {
        case .feed:
            return feedsListViewController
        case .friends:
            return friendsListViewController
        case .tribes:
            return tribesListViewController
        }
//        switch activeTab {
//        case .feed:
//            return FeedsListViewController.instantiate()
//        case .friends:
//            return FriendsListViewController.instantiate()
//        case .tribes:
//            return TribesListViewController.instantiate()
//        }
    }
    
    
    func scannerTouched() {
        let viewController = NewQRScannerViewController.instantiate(
            rootViewController: rootViewController
        )
        
        viewController.delegate = self
        viewController.currentMode = NewQRScannerViewController.Mode.ScanAndProcess
        
        let navigationController = UINavigationController(
            rootViewController: viewController
        )
        
        navigationController.isNavigationBarHidden = true
        present(navigationController, animated: true)
    }
    
    
    func historyButtonTouched() {
        let viewController = HistoryViewController.instantiate(
            rootViewController: rootViewController
        )
        
        self.presentNavigationControllerWith(vc: viewController)
    }
    
    
    func sendButtonTouched() {
        // TODO: Why do we need to couple the `chatViewModel` to the `instantiate` method here?
        
//        let viewController = CreateInvoiceViewController.instantiate(
//            viewModel: chatViewModel,
//            delegate: self,
//            paymentMode: CreateInvoiceViewController.paymentMode.send,
//            rootViewController: rootViewController
//        )
//
//        self.presentNavigationControllerWith(vc: viewController)
    }
    
    func requestButtonTouched() {
        // TODO: Why do we need to couple the `chatViewModel` to the `instantiate` method here?
        
//        let viewController = CreateInvoiceViewController.instantiate(
//            viewModel: chatViewModel,
//            delegate: self,
//            rootViewController: rootViewController
//        )
//
//        self.presentNavigationControllerWith(vc: viewController)
    }
    
    
    func configureHeader() {
        headerView.delegate = self
        
        searchBarContainer.addShadow(location: VerticalLocation.bottom, opacity: 0.15, radius: 3.0)
        bottomBarContainer.addShadow(location: VerticalLocation.top, opacity: 0.2, radius: 3.0)

        searchBar.layer.borderColor = UIColor.Sphinx.Divider.resolvedCGColor(with: self.view)
        searchBar.layer.borderWidth = 1
        searchBar.layer.cornerRadius = searchBar.frame.height / 2
    }
    
    
    func listenForEvents() {
        headerView.listenForEvents()
        
        NotificationCenter.default.addObserver(forName: .onGroupDeleted, object: nil, queue: OperationQueue.main) { (n: Notification) in
//            self.initialLoad()
        }
    }
    
    
    func resetSearchField() {
        searchTextField?.text = ""
    }
}

extension DashboardRootViewController: ChatListHeaderDelegate {
    
}


extension DashboardRootViewController: SocketManagerDelegate {

    func didReceiveMessage(message: TransactionMessage, shouldSync: Bool) {
//        updateContactsAndReload(shouldReload: shouldSync)
    }
    
    func didReceiveConfirmation(message: TransactionMessage) {
//        updateContactsAndReload(shouldReload: false)
    }
    
    func didReceivePurchaseUpdate(message: TransactionMessage) {
//        updateContactsAndReload(shouldReload: false)
    }
    
    func shouldShowAlert(message: String) {
        AlertHelper.showAlert(title: "Hey!", message: message)
    }
    
    func didUpdateContact(contact: UserContact) {
//        chatListDataSource?.updateContactAndReload(object: contact)
    }
    
    func didUpdateChat(chat: Chat) {
//        chatListDataSource?.updateChatAndReload(object: chat)
    }
    
    func didReceiveOrUpdateGroup() {
//        loadFriendAndReload()
    }
}

extension DashboardRootViewController: CustomSegmentedControlDelegate {
    
    func segmentedControlDidSwitch(
        _ segmentedControl: CustomSegmentedControl,
        to index: Int
    ) {
        activeTab = DashboardTab(rawValue: index)!
        print("segmentedControl index changed to \(index)")
    }
}


extension DashboardRootViewController {
    
    enum DashboardTab: Int, Hashable {
        case feed
        case friends
        case tribes
    }
}



// MARK: - UITextFieldDelegate for handling search input
extension DashboardRootViewController: UITextFieldDelegate {
   
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
    
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
//        chatListObjectsArray = contactsService.getChatListObjects()
//        loadDataSource()
        
        return true
    }
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        var currentString = (textField.text ?? "") as NSString
    
        currentString = currentString.replacingCharacters(
            in: range,
            with: string
        ) as NSString

//        chatListObjectsArray = contactsService.getObjectsWith(
//            searchString: currentString
//        )
        
//        loadDataSource()
        return true
    }
}

extension DashboardRootViewController: NewContactVCDelegate {
    func shouldReloadContacts(reload: Bool) {
        if reload {
//            loadFriendAndReload()
        }
    }
}

extension DashboardRootViewController: QRCodeScannerDelegate {
    func shouldGoToChat() {
//        goToChat()
    }
    
    func didScanDeepLink() {
        handleLinkQueries()
    }
}

extension DashboardRootViewController: WindowsManagerDelegate {
    func didDismissCoveringWindows() {
//        goToChat()
    }
}


extension DashboardRootViewController: PaymentInvoiceDelegate {
    func willDismissPresentedView(paymentCreated: Bool) {
        rootViewController.setStatusBarColor(light: true)
        headerView.updateBalance()
    }
}
