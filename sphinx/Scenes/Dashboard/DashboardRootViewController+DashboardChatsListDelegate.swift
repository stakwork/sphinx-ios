import UIKit



extension DashboardRootViewController: DashboardChatsListDelegate {
    
    func viewController(
        _ viewController: UIViewController,
        didSelectChat chat: Chat
    ) {
        presentChatDetailsVC(for: chat)
    }
    
    
    func viewControllerDidRefreshChats(
        _ viewController: UIViewController,
        using refreshControl: UIRefreshControl
    ) {
        loadContactsAndSyncMessages()
        refreshControl.endRefreshing()
    }
}
