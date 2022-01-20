import UIKit


extension DashboardRootViewController: PodcastPlayerVCDelegate {
    
    func shouldDismissPlayerView() {
        navigationController?.popViewController(animated: true)
        
        try? feedSearchResultsContainerViewController
            .fetchedResultsController
            .performFetch()
    }
    
    func willDismissPlayer(playing: Bool) {}
    
    func shouldShareClip(comment: PodcastComment) {}
    
    func shouldGoToPlayer() {}
}

extension DashboardRootViewController : CustomBoostDelegate {
    func didSendBoostMessage(success: Bool, message: TransactionMessage?) {
        chatsListViewModel.updateContactsAndChats()
        updateCurrentViewControllerData()
    }
}
