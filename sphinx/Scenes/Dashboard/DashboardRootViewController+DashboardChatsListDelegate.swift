import UIKit



extension DashboardRootViewController: DashboardChatsListDelegate {
    
    func viewController(
        _ viewController: UIViewController,
        didSelectChat chat: Chat
    ) {
        presentChatDetailsVC(chat: chat)
    }
    
    
    func viewControllerDidRefreshChats(
        _ viewController: UIViewController,
        using refreshControl: UIRefreshControl
    ) {
        loadContactsAndSyncMessages()
        refreshControl.endRefreshing()
    }
}
