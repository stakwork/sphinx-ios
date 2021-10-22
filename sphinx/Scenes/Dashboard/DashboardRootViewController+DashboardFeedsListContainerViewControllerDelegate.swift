import UIKit
import CoreData


extension DashboardRootViewController: DashboardFeedsListContainerViewControllerDelegate {
    
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
        
        guard let feedURLPath = podcastFeed.feedURLPath else {
            AlertHelper.showAlert(title: "Failed to find a URL for the feed.", message: "")
            return
        }
        
        
        let podcastPlayerHelper: PodcastPlayerHelper
        
        if let chat = podcastFeed.chat {
            podcastPlayerHelper = chat.getPodcastPlayer()
        } else {
            // Load a podcast that was subscribed to from the Podcast Index.
            // These won't have an associated `chat`, but we can still fetch episodes.
            podcastPlayerHelper = PodcastPlayerHelper()
        }
        
        podcastPlayerHelper.podcast = podcastFeed
        
        presentPodcastPlayer(
            forPodcastFrom: podcastFeed.chat,
            with: podcastPlayerHelper
        )
    }
    
    
    func viewController(
        _ viewController: UIViewController,
        didSelectVideoFeedWithID videoFeedID: NSManagedObjectID
    ) {
        guard
            let videoFeed = managedObjectContext.object(with: videoFeedID) as? VideoFeed
        else {
            preconditionFailure()
        }

        // 📝 TODO:  Implement the dedicated `VideoFeed` screen page and go there instead.
        if
            let latestEpisode = videoFeed.videosArray.first,
            viewController is DashboardFeedsContainerViewController
        {
            presentVideoPlayer(for: latestEpisode)
        }
    }
    
    
    func viewController(
        _ viewController: UIViewController,
        didSelectVideoEpisodeWithID videoEpisodeID: NSManagedObjectID
    ) {
        guard
            let videoEpisode = managedObjectContext
                .object(with: videoEpisodeID) as? Video
        else {
            preconditionFailure()
        }
        
        if viewController is DashboardFeedsContainerViewController {
            presentVideoPlayer(for: videoEpisode)
        }
    }
}


extension DashboardRootViewController {
    
    private func presentPodcastPlayer(
        forPodcastFrom chat: Chat? = nil,
        with podcastPlayerHelper: PodcastPlayerHelper
    ) {
        let podcastFeedVC = NewPodcastPlayerViewController.instantiate(
            chat: chat,
            playerHelper: podcastPlayerHelper,
            dismissButtonStyle: .backArrow,
            delegate: self
        )
        
        podcastFeedVC.modalPresentationStyle = .automatic
        
        navigationController?
            .present(podcastFeedVC, animated: true)
    }
    
    
    private func presentVideoPlayer(
        for videoEpisode: Video
    ) {
        let viewController = VideoFeedEpisodePlayerContainerViewController
            .instantiate(
                videoPlayerEpisode: videoEpisode,
                dismissButtonStyle: .backArrow,
                delegate: self
            )
        
        viewController.modalPresentationStyle = .automatic
        
        navigationController?
            .present(viewController, animated: true)
    }
}
