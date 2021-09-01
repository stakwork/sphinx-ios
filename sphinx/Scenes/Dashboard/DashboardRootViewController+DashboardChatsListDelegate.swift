import UIKit
import CoreData


extension DashboardRootViewController: DashboardChatsListDelegate {
    
    func viewController(
        _ viewController: UIViewController,
        didSelectChat chat: Chat?,
        orContact contact: UserContact?
    ) {
        loadContactsAndSyncMessages()
        presentChatDetailsVC(for: chat, contact: contact)
        updateCurrentViewControllerData()
    }
    
    
    func viewControllerDidRefreshChats(
        _ viewController: UIViewController,
        using refreshControl: UIRefreshControl
    ) {
        loadContactsAndSyncMessages()
        refreshControl.endRefreshing()
    }
}
