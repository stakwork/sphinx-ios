//
//  DashboardRootViewController.swift
//  DashboardRootViewController
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit


class DashboardRootViewController: UIViewController {
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
                "dashboard.tabs.tribe".localized,
            ])
            dashboardNavigationTabs.delegate = self
        }
    }
    

    internal var rootViewController: RootViewController!
    internal weak var leftMenuDelegate: MenuDelegate?

    
    internal lazy var feedsListViewController = {
        FeedsListViewController.instantiate()
    }()
    
    internal lazy var friendsListViewController = {
        FriendsListViewController.instantiate()
    }()
    
    internal lazy var tribesListViewController = {
        TribesListViewController.instantiate()
    }()
    
    
    internal var activeTab: DashboardTab? {
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


    internal let onionConnecter = SphinxOnionConnector.sharedInstance

    
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
                    searchBarContainer,
                    mainContentContainerView,
                    bottomBarContainer,
                ]
            )
        }
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
        configureHeader()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        headerView.showBalance()
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
        viewController.currentMode = NewQRScannerViewController.Mode.ScanAndProcess
        
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
        
        self.presentNavigationControllerWith(vc: viewController)
    }
    
    
    func sendSatsButtonTouched() {
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
    
    func requestSatsButtonTouched() {
        // TODO: Why do we need to couple the `chatViewModel` to the `instantiate` method here?
        
//        let viewController = CreateInvoiceViewController.instantiate(
//            viewModel: chatViewModel,
//            delegate: self,
//            rootViewController: rootViewController
//        )
//
//        self.presentNavigationControllerWith(vc: viewController)
    }
}


// MARK: -  Private Helpers
extension DashboardRootViewController {
    
    private func mainContentViewController(forActiveTab activeTab: DashboardTab) -> UIViewController {
        switch activeTab {
        case .feed:
            return feedsListViewController
        case .friends:
            return friendsListViewController
        case .tribes:
            return tribesListViewController
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


