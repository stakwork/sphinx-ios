import UIKit


protocol DashboardChatsListDelegate: AnyObject {
    
    func viewController(
        _ viewController: UIViewController,
        didSelectChat chat: Chat?,
        orContact contact: UserContact?
    )
    
    func viewControllerDidRefreshChats(
        _ viewController: UIViewController,
        using refreshControl: UIRefreshControl
    )

    func viewControllerContentScrolled(
        scrollView: UIScrollView
    )
    
    func shouldGetChatsContainerYOffset() -> CGFloat
}
