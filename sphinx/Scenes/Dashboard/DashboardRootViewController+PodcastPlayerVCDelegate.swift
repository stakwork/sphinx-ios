import UIKit


extension DashboardRootViewController: PodcastPlayerVCDelegate {
    
    func willDismissPlayer() {}
    
    func shouldShareClip(comment: PodcastComment) {}
    
    func shouldGoToPlayer(podcast: PodcastFeed) {
        presentPodcastPlayerFor(podcast)
    }
}

extension DashboardRootViewController : CustomBoostDelegate {
    func didSendBoostMessage(success: Bool, message: TransactionMessage?) {
        chatsListViewModel.updateContactsAndChats()
        updateCurrentViewControllerData()
    }
}
