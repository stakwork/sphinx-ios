import UIKit


protocol DashboardChatsListDelegate: AnyObject {
    
    func viewController(
        _ viewController: UIViewController,
        didSelectChat chat: Chat
    )
    
    
    func viewControllerDidRefreshChats(
        _ viewController: UIViewController,
        using refreshControl: UIRefreshControl
    )
}
