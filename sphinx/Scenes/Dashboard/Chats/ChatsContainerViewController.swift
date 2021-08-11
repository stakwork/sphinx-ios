import UIKit


class ChatsContainerViewController: UIViewController {
    @IBOutlet weak var chatsListContainerView: UIView!
    
    
    private var chatsCollectionViewController: ChatsCollectionViewController!
    private weak var chatsListDelegate: DashboardChatsListDelegate?
    
    
    var chats: [Chat] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.chatsCollectionViewController.chats = self.chats
                self.chatsCollectionViewController.updateSnapshot()
            }
        }
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
        
        viewController.chats = chats
        viewController.chatsListDelegate = chatsListDelegate
        
        return viewController
    }
}


// MARK: - Lifecycle
extension ChatsContainerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureContactChatsCollectionView()
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
}

