import UIKit


extension DashboardRootViewController: PodcastPlayerVCDelegate {
    
    func willDismissPlayer() {
        
    }
    
    func shouldShareClip(comment: PodcastComment) {}
    
    func shouldGoToPlayer(podcast: PodcastFeed) {
        feedsManager.restoreContentFeedStatusInBackgroundFor(feedId: podcast.feedID)
        
        presentPodcastPlayerFor(podcast)
    }
    
    func didFailPlayingPodcast() {
        AlertHelper.showAlert(title: "generic.error.title".localized, message: "error.playing".localized)
    }
}

extension DashboardRootViewController : CustomBoostDelegate {
    func didSendBoostMessage(success: Bool, message: TransactionMessage?) {
        chatsListViewModel.updateContactsAndChats()
        updateCurrentViewControllerData()
    }
}
