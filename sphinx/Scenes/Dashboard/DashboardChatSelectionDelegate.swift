import UIKit


protocol DashboardChatSelectionDelegate: AnyObject {
    
    func viewController(_ viewController: UIViewController, didSelectChat chat: Chat)
}
