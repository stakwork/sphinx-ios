import UIKit


class ChatsContainerViewController: UIViewController {
    @IBOutlet weak var chatsListContainerView: UIView!
    
    
    private var chatsCollectionViewController: ChatsCollectionViewController!
    private weak var chatsListDelegate: DashboardChatsListDelegate?
    
    private(set) var chats: [ChatListCommonObject] = []
}


// MARK: - Instantiation
extension ChatsContainerViewController {
    
    static func instantiate(
        chats: [ChatListCommonObject] = [],
        chatsListDelegate: DashboardChatsListDelegate
    ) -> ChatsContainerViewController {
        
        let viewController = StoryboardScene
            .Dashboard
            .chatsContainerViewController
            .instantiate()
        
        viewController.chatsListDelegate = chatsListDelegate
        viewController.chats = chats
        
        return viewController
    }
    
    
    public func updateWithNewChats(
        _ chats: [ChatListCommonObject]
    ) {
        self.chats = chats
        
        self.chatsCollectionViewController.chats = chats
        self.chatsCollectionViewController.updateSnapshot()
    }
}


// MARK: - Lifecycle
extension ChatsContainerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureContactChatsCollectionView()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}


// MARK: - Event Handling
private extension ChatsContainerViewController {
    
    func handleChatSelection(_ chat: ChatListCommonObject) {
        if let chat = chat as? Chat {
            chatsListDelegate?.viewController(self, didSelectChat: chat, orContact: nil)
        } else if let contact = chat as? UserContact {
            chatsListDelegate?.viewController(self, didSelectChat: nil, orContact: contact)
        }
    }
    
    
    func handleChatsListRefresh(refreshControl: UIRefreshControl) {
        chatsListDelegate?.viewControllerDidRefreshChats(self, using: refreshControl)
    }
}


// MARK: - Private Helpers
extension ChatsContainerViewController {
    
    private func configureContactChatsCollectionView() {
        chatsCollectionViewController = ChatsCollectionViewController
            .instantiate(
                chats: chats,
                onChatSelected: handleChatSelection(_:),
                onRefresh: handleChatsListRefresh(refreshControl:)
            )
        
        addChildVC(
            child: chatsCollectionViewController,
            container: chatsListContainerView
        )
    }
}

