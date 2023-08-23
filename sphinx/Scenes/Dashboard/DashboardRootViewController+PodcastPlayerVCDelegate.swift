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
        let presentedVC = (presentedViewController as? UINavigationController)?.viewControllers.first ?? presentedViewController
        
        if let _ = presentedVC as? NewPodcastPlayerViewController {
            return
        }
        AlertHelper.showAlert(title: "generic.error.title".localized, message: "error.playing".localized)
    }
}

extension DashboardRootViewController : CustomBoostDelegate {
    func didSendBoostMessage(success: Bool, message: TransactionMessage?) {
        ///Not needed anymore
    }
}
