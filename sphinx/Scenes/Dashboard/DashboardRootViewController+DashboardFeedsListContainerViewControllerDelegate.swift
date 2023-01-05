import UIKit
import CoreData


extension DashboardRootViewController: DashboardFeedsListContainerViewControllerDelegate, NewsletterFeedContainerViewControllerDelegate {
    
    func viewController(_ viewController: UIViewController, didSelectFeedSearchResult feedId: String) {
        if let contentFeed = ContentFeed.getFeedWith(feedId: feedId) {
            if contentFeed.isPodcast {
                let podcastFeed = PodcastFeed.convertFrom(contentFeed: contentFeed)
                self.viewController(self, didSelectPodcastFeed: podcastFeed)
            } else if contentFeed.isVideo {
                self.viewController(self, didSelectVideoFeedWithID: contentFeed.objectID)
            } else if contentFeed.isNewsletter {
                self.viewController(self, didSelectNewsletterFeedWithID: contentFeed.objectID)
            }
        }
        
        actionsManager.saveFeedSearches()
    }
    
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
            presentPodcastPlayerFor(podcastFeed)
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
        
        presentPodcastPlayerFor(podcastFeed)
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

        if let latestEpisode = videoFeed.videosArray.first {
            presentVideoPlayer(for: latestEpisode)
        } else {
            AlertHelper.showAlert(title: "Invalid channel or playlist", message: "No videos available")
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
            
            presentVideoPlayer(for: videoEpisode)
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
        presentNewsletterFeedVC(for: newsletterFeed)
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
    
    func viewController(
        _ viewController: UIViewController,
        didSelectRecommendationWithId recommendationId: String,
        from recommendations: [RecommendationResult]
    ) {
        presentRecommendationsPlayerVC(for: recommendations, and: recommendationId)
    }
}


extension DashboardRootViewController {
    
    func presentPodcastPlayerFor(
        _ podcast: PodcastFeed
    ) {
        if (podcast.isRecommendationsPodcast) {
            presentRecommendationsPlayerVC(for: podcast)
        } else {
            let podcastFeedVC = NewPodcastPlayerViewController.instantiate(
                podcast: podcast,
                delegate: self,
                boostDelegate: self,
                fromDashboard: true
            )
            
            podcastFeedVC.modalPresentationStyle = .automatic
            
            navigationController?
                .present(podcastFeedVC, animated: true)
        }
    }
    
    
    private func presentVideoPlayer(
        for videoEpisode: Video
    ) {
        let viewController = VideoFeedEpisodePlayerContainerViewController
            .instantiate(
                videoPlayerEpisode: videoEpisode,
                dismissButtonStyle: .backArrow,
                delegate: self,
                boostDelegate: self
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
                newsletterItem: newsletterItem,
                boostDelegate: self
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
    
    private func presentRecommendationsPlayerVC(
        for recommendations: [RecommendationResult],
        and recommendationId: String
    ) {
        if let recommendation = recommendations.filter({ $0.id == recommendationId}).first {
            
            let recommendationsHelper = RecommendationsHelper.sharedInstance
            
            let podcast = recommendationsHelper.getPodcastFor(
                recommendations: recommendations,
                selectedItem: recommendation
            )
            
            pausePlayingIfNeeded(podcast: podcast, itemId: recommendationId)
            
            presentRecommendationsPlayerVC(for: podcast)
        }
    }
    
    private func pausePlayingIfNeeded(
        podcast: PodcastFeed,
        itemId: String
    ) {
        if podcastPlayerHelper.isPlaying(podcast.feedID) {
            if podcast.getCurrentEpisode()?.itemID != itemId {
                podcastPlayerHelper.shouldPause()
            }
        }
        
        let _ = podcastPlayerHelper.setNewEpisodeWith(episodeId: itemId, in: podcast)
    }
    
    private func presentRecommendationsPlayerVC(
        for podcast: PodcastFeed
    ) {
        let viewController = RecommendationFeedPlayerContainerViewController
            .instantiate(podcast: podcast)
        
        viewController.modalPresentationStyle = .automatic
        
        navigationController?
            .present(viewController, animated: true)
    }
}
