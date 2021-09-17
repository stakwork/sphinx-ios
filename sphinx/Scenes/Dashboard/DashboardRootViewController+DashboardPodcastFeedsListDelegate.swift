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
            let podcastFeed = managedObjectContext.object(with: podcastFeedID) as? PodcastFeed
        else {
            return
        }
        
        let podcastPlayerHelper: PodcastPlayerHelper
        
        if let chat = podcastFeed.chat {
            podcastPlayerHelper = chat.getPodcastPlayer()
            
            presentPodcastPlayer(
                forPodcastFrom: chat,
                with: podcastPlayerHelper
            )
        } else {
            // Load a podcast that was subscribed to by searching the Podcast Index.
            // These won't have an associated `chat`, but we can still fetch episodes.
            
            guard let feedURLPath = podcastFeed.feedURLPath else {
                AlertHelper.showAlert(title: "Failed to find a URL for the feed.", message: "")
                
                return
            }
            
            podcastPlayerHelper = PodcastPlayerHelper()
            podcastPlayerHelper.podcast = podcastFeed
            
            API.sharedInstance.getPodcastEpisodes(
                byFeedURLPath: feedURLPath
            ) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success(let episodes):
                        podcastPlayerHelper.podcast?.episodes = Set(episodes)
                        
                        let podcastFeedVC = NewPodcastPlayerViewController.instantiate(
                            chat: nil,
                            playerHelper: podcastPlayerHelper,
                            delegate: self
                        )
                    
                        podcastFeedVC.modalPresentationStyle = .fullScreen
                    
                        self.navigationController?.pushViewController(
                            podcastFeedVC,
                            animated: true
                        )
                    case .failure(_):
                        AlertHelper.showAlert(
                            title: "Failed to fetch episodes for feed",
                            message: ""
                        )
                    }
                }
            }
        }
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
