import UIKit


private let sampleChats: [Chat] = {
    let managedObjectContext = CoreDataManager
        .sharedManager
        .persistentContainer
        .viewContext
    
    return (1...4).map { sampleChatNumber in
        var chat = Chat(context: managedObjectContext)
        
        chat.id = sampleChatNumber
        chat.uuid = "Contact \(sampleChatNumber)"
        chat.name = "Contact \(sampleChatNumber)"
        chat.photoUrl = nil
        chat.image = UIImage(named: "profile_avatar")!
        chat.type = 1
        chat.status = 1
        chat.createdAt = Date()
        chat.muted = false
        chat.seen = Bool.random()
        chat.host = nil
        chat.groupKey = nil
        chat.ownerPubkey = nil
        chat.priceToJoin = nil
        chat.pricePerMessage = nil
        chat.escrowAmount = nil
        chat.unlisted = false
        chat.privateTribe = false
        chat.myAlias = nil
        chat.myPhotoUrl = nil
        chat.webAppLastDate = nil
        chat.pin = nil
        chat.podcastFeed = nil
        chat.contactIds = []
        chat.pendingContactIds = []
        
        return chat
    }
}()



class ContactChatsContainerViewController: UIViewController {
    @IBOutlet weak var contactChatsListContainerView: UIView!
    
    var viewModel: ChatListViewModel!
    
    private var contactChatsListViewController: ContactChatsListViewController!
    
    private let refreshControl = UIRefreshControl()
    private let socketManager = SphinxSocketManager.sharedInstance
    private let onionConnector = SphinxOnionConnector.sharedInstance
    
    
    private var chatListObjectsArray = [ChatListCommonObject]() {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                let chats = self.chatListObjectsArray
                    .compactMap{ $0 as? UserContact }
                    .compactMap { $0.getConversation() }
                
                //                self.contactChatsListViewController.chats = chats
                self.contactChatsListViewController.chats = sampleChats
                self.contactChatsListViewController.updateSnapshot()
            }
        }
    }
    
    
    var isLoading = false {
        didSet {
            //            LoadingWheelHelper.toggleLoadingWheel(
            //                loading: isLoading || onionConnector.isConnecting(),
            //                loadingWheel: headerView.loadingWheel,
            //                loadingWheelColor: UIColor.white,
            //                views: [chatListTableView, bottomBarContainer, searchBarContainer]
            //            )
        }
    }
    
    
    var loadingRefresh = false {
        didSet {
            //            LoadingWheelHelper.toggleLoadingWheel(
            //                loading: loadingRefresh || onionConnector.isConnecting(),
            //                loadingWheel: headerView.loadingWheel,
            //                loadingWheelColor: UIColor.white
            //            )
        }
    }
}


// MARK: - Instantiation
extension ContactChatsContainerViewController {
    
    static func instantiate(
        viewModel: ChatListViewModel
    ) -> ContactChatsContainerViewController {
        let viewController = StoryboardScene
            .Dashboard
            .contactChatsContainerViewController
            .instantiate()
        
        //        viewController.delegate = delegate
        viewController.viewModel = viewModel
        
        return viewController
    }
}


// MARK: - Lifecycle
extension ContactChatsContainerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureContactChatsCollectionView()
        loadInitialData()
        
        //        chatListTableView.refreshControl = refreshControl
        //        refreshControl.addTarget(self, action: #selector(refreshOnPull(sender:)), for: .valueChanged)
        
        //        searchTextField.delegate = self
        
        //        isLoading = true
    }
}


// MARK: - Event Handling
private extension ContactChatsContainerViewController {
}


// MARK: - Private Helpers
extension ContactChatsContainerViewController {
    
    
    private func loadInitialData() {
        viewModel.updateContactsAndChats()
        chatListObjectsArray = viewModel.contactsService.getChatListObjects()
        refreshControl.endRefreshing()
    }
    
    
    private func configureContactChatsCollectionView() {
        contactChatsListViewController = ContactChatsListViewController
            .instantiate(
                chats: []
            )
        
        
        addChildVC(
            child: contactChatsListViewController,
            container: contactChatsListContainerView
        )
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        socketManager.setDelegate(delegate: self)
        updateContactsAndReload()
    }
    
    
    //    override func viewDidAppear(_ animated: Bool) {
    //        super.viewDidAppear(animated)
    //
    //        if shouldReloadFriends {
    //            loading = true
    //            loadFriendAndReload()
    //        } else {
    //            initialLoad()
    //        }
    //    }
    
    
    //    func handleDeepLinksAndPush() {
    //        goToChat()
    //    }
    
    
    
    //    func goToChat() {
    //        if let chatId = UserDefaults.Keys.chatId.get(defaultValue: -1), let chat = Chat.getChatWith(id: chatId) {
    //            presentChatVC(object: chat, fromPush: true)
    //        }
    //        if let contactId = UserDefaults.Keys.contactId.get(defaultValue: -1), let contact = UserContact.getContactWith(id: contactId) {
    //            presentChatVC(object: contact, fromPush: true)
    //        }
    //        UserDefaults.Keys.contactId.removeValue()
    //        UserDefaults.Keys.chatId.removeValue()
    //    }
    
    
    //    @objc func refreshOnPull(sender: UIRefreshControl) {
    //        loadFriendAndReload()
    //        loadingRefresh = false
    //    }
    //
    
    //    func initialLoad(_ forceLastMessageReload: Bool = false) {
    //        chatListViewModel.updateContactsAndChats()
    //        chatListObjectsArray = contactsService.getChatListObjects(forceLastMessageReload)
    //        refreshControl.endRefreshing()
    //    }
    
    func finishLoading() {
        //        newBubbleHelper.hideLoadingWheel()
        isLoading = false
    }
    
    
    func loadMessages() {
        loadFriendsAndReloadMessages()
        
        viewModel.syncMessages(progressCallback: { message in
            self.isLoading = false
            //            self.newBubbleHelper.showLoadingWheel(text: message)
        }) { (_,_, isRestoring) in
            self.updateContactsAndReload(forceLastMessageReload: isRestoring)
            self.finishLoading()
        }
    }
    
    
    func loadFriendsAndReloadMessages() {
        //        loadingRefresh = true
        
        viewModel.loadFriends() {
            //            self.userId = UserData.sharedInstance.getUserId()
            self.loadMessages()
        }
    }
    
    
    func updateContactsAndReload(
        shouldReloadFriends: Bool = false,
        forceLastMessageReload: Bool = false
    ) {
        if shouldReloadFriends {
            loadFriendsAndReloadMessages()
        } else {
            loadInitialData()
        }
    }
}



extension ContactChatsContainerViewController: SocketManagerDelegate {
    
    func didReceiveMessage(message: TransactionMessage, shouldSync: Bool) {
        if shouldSync {
            loadFriendsAndReloadMessages()
        } else {
            loadInitialData()
        }
    }
    
    func didReceiveConfirmation(message: TransactionMessage) {
        updateContactsAndReload(shouldReloadFriends: false)
    }
    
    func didReceivePurchaseUpdate(message: TransactionMessage) {
        updateContactsAndReload(shouldReloadFriends: false)
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
        loadFriendsAndReloadMessages()
    }
}
