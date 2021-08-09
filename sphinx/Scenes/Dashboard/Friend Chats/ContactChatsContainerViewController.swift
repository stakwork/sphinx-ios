import UIKit


//private let sampleChats: [Chat] = {
//    let managedObjectContext = CoreDataManager
//        .sharedManager
//        .persistentContainer
//        .viewContext
//
//    return (1...4).map { sampleChatNumber in
//        var chat = Chat(context: managedObjectContext)
//
//        chat.id = sampleChatNumber
//        chat.uuid = "Contact \(sampleChatNumber)"
//        chat.name = "Contact \(sampleChatNumber)"
//        chat.photoUrl = nil
//        chat.image = UIImage(named: "profile_avatar")!
//        chat.type = 1
//        chat.status = 1
//        chat.createdAt = Date()
//        chat.muted = Bool.random()
//        chat.seen = Bool.random()
//        chat.host = nil
//        chat.groupKey = nil
//        chat.ownerPubkey = nil
//        chat.priceToJoin = nil
//        chat.pricePerMessage = nil
//        chat.escrowAmount = nil
//        chat.unlisted = false
//        chat.privateTribe = false
//        chat.myAlias = nil
//        chat.myPhotoUrl = nil
//        chat.webAppLastDate = nil
//        chat.pin = nil
//        chat.podcastFeed = nil
//        chat.contactIds = []
//        chat.pendingContactIds = []
//
//        try? managedObjectContext.save()
//
//        return chat
//    }
//}()
//


class ContactChatsContainerViewController: UIViewController {
    @IBOutlet weak var contactChatsListContainerView: UIView!
    
    
    private var contactChatsListViewController: ContactChatsListViewController!
    private weak var chatsListDelegate: DashboardChatsListDelegate?
    
    
    var chats: [Chat] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.contactChatsListViewController.chats = self.chats
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
        chats: [Chat] = [],
        chatsListDelegate: DashboardChatsListDelegate
    ) -> ContactChatsContainerViewController {
        let viewController = StoryboardScene
            .Dashboard
            .contactChatsContainerViewController
            .instantiate()
        
        viewController.chats = chats
        viewController.chatsListDelegate = chatsListDelegate
        
        return viewController
    }
}


// MARK: - Lifecycle
extension ContactChatsContainerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureContactChatsCollectionView()
    }
}



// MARK: - Event Handling
private extension ContactChatsContainerViewController {
    
    func handleChatSelection(_ chat: Chat) {
        chatsListDelegate?.viewController(self, didSelectChat: chat)
    }
    
    
    func handleChatsListRefresh(refreshControl: UIRefreshControl) {
        chatsListDelegate?.viewControllerDidRefreshChats(self, using: refreshControl)
    }
}


// MARK: - Private Helpers
extension ContactChatsContainerViewController {
    
    private func configureContactChatsCollectionView() {
        contactChatsListViewController = ContactChatsListViewController
            .instantiate(
                chats: chats,
                onChatSelected: handleChatSelection(_:),
                onRefresh: handleChatsListRefresh(refreshControl:)
            )
        
        addChildVC(
            child: contactChatsListViewController,
            container: contactChatsListContainerView
        )
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
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
    
}

