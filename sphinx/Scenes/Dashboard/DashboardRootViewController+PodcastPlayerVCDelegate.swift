import UIKit


extension DashboardRootViewController: PodcastPlayerVCDelegate {
    
    func shouldDismissPlayerView() {
        navigationController?.popViewController(animated: true)
        
        try? feedSearchResultsContainerViewController
            .fetchedResultsController
            .performFetch()
    }
    
    func didSendBoostMessage(success: Bool, message: TransactionMessage?) {
        chatsListViewModel.updateContactsAndChats()
        updateCurrentViewControllerData()
    }
    
    func willDismissPlayer(playing: Bool) {}
    
    func shouldShareClip(comment: PodcastComment) {}
    
    func shouldGoToPlayer() {}
}
