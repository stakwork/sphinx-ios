import UIKit


class ChatsContainerViewController: UIViewController {
    @IBOutlet weak var chatsListContainerView: UIView!
    
    
    private var chatsCollectionViewController: ChatsCollectionViewController!
    private weak var chatsListDelegate: DashboardChatsListDelegate?
    
  
    private(set) var chats: [Chat] = []
    
    
    private static func sortChatsForList(_ firstChat: Chat, secondChat: Chat) -> Bool {
        if firstChat.isPending() || secondChat.isPending() {
            return firstChat.isPending() && !secondChat.isPending()
        }
        
        if let firstChatDate = firstChat.getOrderDate() {
            if let secondChatDate = secondChat.getOrderDate() {
                return firstChatDate > secondChatDate
            } else {
                return true
            }
        } else if let _ = secondChat.getOrderDate() {
            return false
        }
        
        return firstChat.getName().lowercased() < secondChat.getName().lowercased()
    }
}


// MARK: - Instantiation
extension ChatsContainerViewController {
    
    static func instantiate(
        chats: [Chat] = [],
        chatsListDelegate: DashboardChatsListDelegate
    ) -> ChatsContainerViewController {
        let viewController = StoryboardScene
            .Dashboard
            .chatsContainerViewController
            .instantiate()
        
        viewController.chatsListDelegate = chatsListDelegate
        
        viewController.updateWithNewChats(chats, animationDelay: 0.0)
        
        return viewController
    }
    
    
    public func updateWithNewChats(
        _ chats: [Chat],
        shouldAnimate: Bool = false,
        shouldForceReload: Bool = false,
        animationDelay: TimeInterval = 0.5
    ) {
        self.chats = chats.sorted(by: Self.sortChatsForList)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.chatsCollectionViewController.chats = self.chats
            self.chatsCollectionViewController.updateSnapshot(
                shouldAnimate: shouldAnimate,
                shouldForceReload: shouldForceReload,
                animationDelay: animationDelay
            )
        }
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
    
    func handleChatSelection(_ chat: Chat) {
        chatsListDelegate?.viewController(self, didSelectChat: chat)
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

