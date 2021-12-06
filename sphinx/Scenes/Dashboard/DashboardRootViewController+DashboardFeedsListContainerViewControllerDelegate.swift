import UIKit
import CoreData


extension DashboardRootViewController: DashboardFeedsListContainerViewControllerDelegate, NewsletterFeedContainerViewControllerDelegate {
    
    func viewController(
        _ viewController: UIViewController,
        didSelectPodcastEpisodeWithID podcastEpisodeID: NSManagedObjectID
    ) {
        guard
            let contentFeedItem = managedObjectContext.object(with: podcastEpisodeID) as? ContentFeedItem,
            contentFeedItem.contentFeed?.isPodcast == true
        else {
            preconditionFailure()
        }
        
        if let contentFeed = contentFeedItem.contentFeed {
            
            let podcastFeed = PodcastFeed.convertFrom(contentFeed:  contentFeed)
            let podcastPlayerHelper = getPodcastPlayerFor(podcastFeed)

            presentPodcastPlayer(
                forPodcastFrom: podcastFeed.chat,
                with: podcastPlayerHelper
            )
        }
    }
    
    func viewController(
        _ viewController: UIViewController,
        didSelectPodcastFeed podcastFeed: PodcastFeed
    ) {
        guard let _ = podcastFeed.feedURLPath else {
            AlertHelper.showAlert(title: "Failed to find a URL for the feed.", message: "")
            return
        }
        
        let podcastPlayerHelper = getPodcastPlayerFor(podcastFeed)
        
        presentPodcastPlayer(
            forPodcastFrom: podcastFeed.chat,
            with: podcastPlayerHelper
        )
    }
    
    func getPodcastPlayerFor(_ podcast: PodcastFeed) -> PodcastPlayerHelper {
        let podcastPlayerHelper: PodcastPlayerHelper
        
        if let chat = podcast.chat {
            podcastPlayerHelper = chat.getPodcastPlayer()
        } else {
            // Load a podcast that was subscribed to from the Podcast Index.
            // These won't have an associated `chat`, but we can still fetch episodes.
            podcastPlayerHelper = PodcastPlayerHelper()
        }
        
        podcastPlayerHelper.podcast = podcast
        
        return podcastPlayerHelper
    }
    
    func viewController(
        _ viewController: UIViewController,
        didSelectVideoFeedWithID videoFeedID: NSManagedObjectID
    ) {
        guard
            let contentFeed = managedObjectContext.object(with: videoFeedID) as? ContentFeed,
            contentFeed.isVideo
        else {
            preconditionFailure()
        }
        
        let videoFeed = VideoFeed.convertFrom(contentFeed: contentFeed)

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
            let contentFeedItem = managedObjectContext.object(with: videoEpisodeID) as? ContentFeedItem,
            contentFeedItem.contentFeed?.isVideo == true
        else {
            preconditionFailure()
        }
        
        if let contentFeed = contentFeedItem.contentFeed {
            
            let videoFeed = VideoFeed.convertFrom(contentFeed:  contentFeed)
            let videoEpisode = Video.convertFrom(contentFeedItem: contentFeedItem, videoFeed: videoFeed)
            
            if viewController is DashboardFeedsContainerViewController {
                presentVideoPlayer(for: videoEpisode)
            }
        }
    }
    
    func viewController(
        _ viewController: UIViewController,
        didSelectNewsletterFeedWithID newsletterFeedID: NSManagedObjectID
    ) {
        guard
            let contentFeed = managedObjectContext.object(with: newsletterFeedID) as? ContentFeed,
            contentFeed.isNewsletter
        else {
            preconditionFailure()
        }
        
        let newsletterFeed = NewsletterFeed.convertFrom(contentFeed: contentFeed)
        
        if viewController is DashboardFeedsContainerViewController {
            presentNewsletterFeedVC(for: newsletterFeed)
        }
    }
    
    func viewController(
        _ viewController: UIViewController,
        didSelectNewsletterItemWithID newsletterItemID: NSManagedObjectID
    ) {
        guard
            let contentFeedItem = managedObjectContext.object(with: newsletterItemID) as? ContentFeedItem,
            let contentFeed = contentFeedItem.contentFeed,
            contentFeed.isNewsletter
        else {
            preconditionFailure()
        }
        
        let newsletterFeed = NewsletterFeed.convertFrom(contentFeed: contentFeed)
        
        let newsletterFeedItem = NewsletterItem.convertFrom(
            contentFeedItem: contentFeedItem,
            newsletterFeed: newsletterFeed
        )
        
        presentItemWebView(for: newsletterFeedItem)
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
    
    private func presentItemWebView(
        for newsletterItem: NewsletterItem
    ) {
        let viewController = NewsletterItemDetailViewController
            .instantiate(
                newsletterItem: newsletterItem
            )
        
        viewController.modalPresentationStyle = .automatic
        
        navigationController?
            .present(viewController, animated: true)
    }
    
    private func presentNewsletterFeedVC(
        for newsletterFeed: NewsletterFeed
    ) {
        let viewController = NewsletterFeedContainerViewController
            .instantiate(
                newsletterFeed: newsletterFeed,
                delegate: self
            )
        
        viewController.modalPresentationStyle = .automatic
        
        navigationController?
            .present(viewController, animated: true)
    }
}
