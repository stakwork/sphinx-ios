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
    
    func viewControllerContentScrolled(scrollView: UIScrollView) {
        if (
            scrollView.contentOffset.y <= 0 ||
            scrollView.contentOffset.y >= (scrollView.contentSize.height - (scrollView.frame.size.height - scrollView.contentInset.bottom))
        ) {
            //Scrolling out of bounds of content
            return
        }

        if (self.lastContentOffset > scrollView.contentOffset.y) {
            shouldToggleBottomBar(true)
        } else {
            shouldToggleBottomBar(false)
        }

        self.lastContentOffset = scrollView.contentOffset.y
    }
    
    func shouldToggleBottomBar(_ show: Bool) {
        let destinationBottomBarBottomConstraint:CGFloat = show ? 0 : -58
        let destinationBottomBarAlpha:CGFloat = show ? 1.0 : 0.0
        
        if bottomBarBottomConstraint.constant != destinationBottomBarBottomConstraint {
            self.bottomBarBottomConstraint.constant = destinationBottomBarBottomConstraint
            
            UIView.animate(withDuration: 0.3, animations: {
                self.bottomBar.alpha = destinationBottomBarAlpha
                self.bottomBarContainer.superview?.layoutIfNeeded()
            })
        }
    }
    
    func viewControllerRecommendationsRefreshed() {
        onPlayerBarDismissed()
    }
}
