import UIKit
import CoreData


extension DashboardRootViewController: DashboardPodcastFeedsListDelegate {
    
    func viewController(
        _ viewController: UIViewController,
        didSelectPodcastEpisodeWithID podcastEpisodeID: NSManagedObjectID
    ) {
        guard
            let podcastEpisode = managedObjectContext.object(with: podcastEpisodeID) as? PodcastEpisode,
            let podcastFeed = podcastEpisode.feed,
            let chat = podcastFeed.chat
        else {
            return
        }
        
        let podcastPlayerHelper = chat.getPodcastPlayer()

        presentPodcastPlayer(
            forPodcastFrom: chat,
            with: podcastPlayerHelper
        )
    }


    func viewController(
        _ viewController: UIViewController,
        didSelectPodcastFeedWithID podcastFeedID: NSManagedObjectID
    ) {
        guard
            let podcastFeed = managedObjectContext.object(with: podcastFeedID) as? PodcastFeed,
            let chat = podcastFeed.chat
        else {
            return
        }
        
        let podcastPlayerHelper = chat.getPodcastPlayer()
        
        presentPodcastPlayer(
            forPodcastFrom: chat,
            with: podcastPlayerHelper
        )
    }
}


extension DashboardRootViewController {
    
    internal func presentPodcastPlayer(
        forPodcastFrom chat: Chat,
        with podcastPlayerHelper: PodcastPlayerHelper
    ) {
        let podcastFeedVC = NewPodcastPlayerViewController.instantiate(
            chat: chat,
            playerHelper: podcastPlayerHelper,
            delegate: self
        )
        
        podcastFeedVC.modalPresentationStyle = .fullScreen
        
        navigationController?.pushViewController(podcastFeedVC, animated: true)
    }
}


extension DashboardRootViewController: PodcastPlayerVCDelegate {
    
    func shouldDismissPlayerView() {
        navigationController?.popViewController(animated: true)
    }
    
    
    func willDismissPlayer(playing: Bool) {
    }
    
    
    func shouldShareClip(comment: PodcastComment) {
        
    }
    
    
    func shouldGoToPlayer() {
        
    }
    

    func shouldSendBoost(message: String, amount: Int, animation: Bool) -> TransactionMessage? {
        nil
    }
}
