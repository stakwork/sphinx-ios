//  DashboardFeedsContainerViewController.swift
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import CoreData


protocol DashboardFeedsListContainerViewControllerDelegate: AnyObject {

    func viewController(
        _ viewController: UIViewController,
        didSelectPodcastFeed podcastFeed: PodcastFeed
    )
    
    func viewController(
        _ viewController: UIViewController,
        didSelectPodcastEpisodeWithID podcastEpisodeID: NSManagedObjectID
    )
    
    
    func viewController(
        _ viewController: UIViewController,
        didSelectVideoFeedWithID videoFeedID: NSManagedObjectID
    )
    
    func viewController(
        _ viewController: UIViewController,
        didSelectVideoEpisodeWithID videoEpisodeID: NSManagedObjectID
    )
    
    func viewController(
        _ viewController: UIViewController,
        didSelectNewsletterFeedWithID newsletterFeedID: NSManagedObjectID
    )
    
    func viewController(
        _ viewController: UIViewController,
        didSelectNewsletterItemWithID newsletterItemID: NSManagedObjectID
    )
    
    func viewController(
        _ viewController: UIViewController,
        didSelectRecommendationWithId recommendationId: String,
        from recommendations: [RecommendationResult]
    )
    
    func viewControllerContentScrolled(
        scrollView: UIScrollView
    )
    
    func viewControllerRecommendationsRefreshed()
}


class DashboardFeedsContainerViewController: UIViewController {
    @IBOutlet weak var filterChipCollectionViewContainer: UIView!
    @IBOutlet weak var feedContentCollectionViewContainer: UIView!
    
    private var managedObjectContext: NSManagedObjectContext!
    private var filterChipCollectionViewController: FeedFilterChipsCollectionViewController!
    
    private weak var feedsListContainerDelegate: DashboardFeedsListContainerViewControllerDelegate?
    
    
    var contentFilterOptions: [ContentFilterOption] = []
    
    var activeFilterOption: ContentFilterOption = .allContent {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.handleFilterChipChange(
                    from: oldValue,
                    to: self!.activeFilterOption
                )
            }
        }
    }
    
    let actionsManager = ActionsManager.sharedInstance
    
    internal lazy var emptyStateViewController: DashboardFeedsEmptyStateViewController = {
        DashboardFeedsEmptyStateViewController.instantiate(
            contentFilterOption: activeFilterOption
        )
    }()
    
    
    internal lazy var allTribeFeedsCollectionViewController: AllTribeFeedsCollectionViewController = {
        AllTribeFeedsCollectionViewController.instantiate(
            managedObjectContext: managedObjectContext,
            onCellSelected: handleAllFeedsCellSelection(_:),
            onRecommendationSelected: handleRecommendationSelection(_:_:),
            onNewResultsFetched: handleNewResultsFetch(_:),
            onContentScrolled: handleFeedScroll(scrollView:),
            onRefreshRecommendations: handleRecomendationsRefresh
        )
    }()
    
    
    internal lazy var podcastFeedCollectionViewController: PodcastFeedCollectionViewController = {
        PodcastFeedCollectionViewController.instantiate(
            managedObjectContext: managedObjectContext,
            onPodcastEpisodeCellSelected: handlePodcastEpisodeCellSelection(_:),
            onSubscribedPodcastFeedCellSelected: handlePodcastFeedCellSelection(_:),
            onNewResultsFetched: handleNewResultsFetch(_:),
            onContentScrolled: handleFeedScroll(scrollView:)
        )
    }()
    
    
    internal lazy var videoFeedCollectionViewController: DashboardVideoFeedCollectionViewController = {
        DashboardVideoFeedCollectionViewController.instantiate(
            managedObjectContext: managedObjectContext,
            onVideoEpisodeCellSelected: handleVideoEpisodeCellSelection(_:),
            onVideoFeedCellSelected: handleVideoFeedCellSelection(_:),
            onNewResultsFetched: handleNewResultsFetch(_:),
            onContentScrolled: handleFeedScroll(scrollView:)
        )
    }()
    
    internal lazy var newsletterFeedCollectionViewController: DashboardNewsletterFeedCollectionViewController = {
        DashboardNewsletterFeedCollectionViewController.instantiate(
            managedObjectContext: managedObjectContext,
            onNewsletterItemCellSelected: handleNewsletterItemCellSelection(_:),
            onNewsletterFeedCellSelected: handleNewsletterFeedCellSelection(_:),
            onNewResultsFetched: handleNewResultsFetch(_:),
            onContentScrolled: handleFeedScroll(scrollView:)
        )
    }()
    
    internal lazy var playFeedCollectionViewController: DashboardFeedsEmptyStateViewController = {
        DashboardFeedsEmptyStateViewController.instantiate(
            contentFilterOption: ContentFilterOption.play
        )
    }()
    
    static func instantiate(
        managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext,
        feedsListContainerDelegate: DashboardFeedsListContainerViewControllerDelegate
    ) -> DashboardFeedsContainerViewController {
        let viewController = StoryboardScene.Dashboard.feedsContainerViewController.instantiate()
        
        viewController.managedObjectContext = managedObjectContext
        viewController.feedsListContainerDelegate = feedsListContainerDelegate
        
        return viewController
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFilterOptions()
        configureFilterChipCollectionView()
        configureFeedContentCollectionView()
    }
}


// MARK: -  Private Helpers
extension DashboardFeedsContainerViewController {
    
    private func setupFilterOptions() {
        contentFilterOptions = getContentFilterOptions()
    }
    
    
    private func getContentFilterOptions() -> [ContentFilterOption] {
        ContentFilterOption
            .allCases
            .map {
                var startingOption = $0
                
                if startingOption.id == activeFilterOption.id {
                    startingOption.isActive = true
                }
                
                return startingOption
            }
    }
    
    
    private func handleFilterChipActivation(
        _ filterOption: ContentFilterOption
    ) {
        var updatedOption = filterOption
        
        updatedOption.isActive = true
        activeFilterOption = updatedOption

        let newOptions = ContentFilterOption
            .allCases
            .filter { $0.id != activeFilterOption.id }
            + [activeFilterOption]
        
        filterChipCollectionViewController.contentFilterOptions = newOptions
        filterChipCollectionViewController.updateSnapshot()
    }
    
  
    private func handleNewResultsFetch(_ numberOfItems: Int) {
        if numberOfItems == 0 {
            showEmptyStateViewController()
        } else {
            removeEmptyStateViewController()
        }
    }
    
    private func handleRecomendationsRefresh() {
        feedsListContainerDelegate?.viewControllerRecommendationsRefreshed()
    }
    
    
    private func mainContentViewController(
        for filterChip: ContentFilterOption
    ) -> UIViewController {
        switch activeFilterOption.id {
        case ContentFilterOption.allContent.id:
            return allTribeFeedsCollectionViewController
        case ContentFilterOption.listen.id:
            return podcastFeedCollectionViewController
        case ContentFilterOption.watch.id:
            return videoFeedCollectionViewController
        case ContentFilterOption.read.id:
            return newsletterFeedCollectionViewController
        case ContentFilterOption.play.id:
            return playFeedCollectionViewController
        default:
            preconditionFailure()
        }
    }
    
    private func handleFilterChipChange(
        from oldFilterOption: ContentFilterOption,
        to activeFilterOption: ContentFilterOption
    ) {
        removeEmptyStateViewController()
        
        let oldViewController = mainContentViewController(for: oldFilterOption)
        let newViewController = mainContentViewController(for: activeFilterOption)
        
        removeChildVC(child: oldViewController)
        
        addChildVC(
            child: newViewController,
            container: feedContentCollectionViewContainer
        )
        
        if activeFilterOption.id == ContentFilterOption.allContent.id {
            actionsManager.saveFeedSearches()
            synActionsAndRefreshRecommendations()
        }
    }
    
    private func synActionsAndRefreshRecommendations() {
        allTribeFeedsCollectionViewController.updateLoadingRecommendations()
        
        actionsManager.syncActions() {
            self.allTribeFeedsCollectionViewController.loadRecommendations(forceRefresh: true)
        }
    }
    
    
    private func configureFilterChipCollectionView() {
        filterChipCollectionViewController = FeedFilterChipsCollectionViewController
            .instantiate(
                contentFilterOptions: Array(contentFilterOptions),
                onCellSelected: handleFilterChipActivation(_:)
            )
        
        addChildVC(
            child: filterChipCollectionViewController,
            container: filterChipCollectionViewContainer
        )
    }
    
    
    private func configureFeedContentCollectionView() {
        activeFilterOption = .allContent
    }
    
    
    private func showEmptyStateViewController() {
        emptyStateViewController.contentFilterOption = activeFilterOption
        
        addChildVC(
            child: emptyStateViewController,
            container: feedContentCollectionViewContainer
        )
    }
    
    
    private func removeEmptyStateViewController() {
        removeChildVC(child: emptyStateViewController)
    }
    
    
    private func presentContentViewController(_ viewController: UIViewController) {
        addChildVC(
            child: viewController,
            container: feedContentCollectionViewContainer
        )
    }
    
    
    private func handleAllFeedsCellSelection(
        _ managedObjectID: NSManagedObjectID
    ) {
        let entity = managedObjectContext.object(with: managedObjectID)
        
        if let contentFeed = entity as? ContentFeed {
            if contentFeed.isNewsletter {
                feedsListContainerDelegate?.viewController(
                    self,
                    didSelectNewsletterFeedWithID: managedObjectID
                )
            } else if contentFeed.isVideo {
                feedsListContainerDelegate?.viewController(
                    self,
                    didSelectVideoFeedWithID: managedObjectID
                )
            } else if contentFeed.isPodcast {
                feedsListContainerDelegate?.viewController(
                    self,
                    didSelectPodcastFeed: PodcastFeed.convertFrom(contentFeed: contentFeed)
                )
            }
        }
    }
    
    private func handleRecommendationSelection(
        _ recommendations: [RecommendationResult],
        _ selectedRecommendationId: String
    ) {
        feedsListContainerDelegate?.viewController(
            self,
            didSelectRecommendationWithId: selectedRecommendationId,
            from: recommendations
        )
    }
    
    func handleFeedScroll(scrollView: UIScrollView) {
        feedsListContainerDelegate?.viewControllerContentScrolled(scrollView: scrollView)
    }
}


// MARK: -  Audio Podcast Selection
extension DashboardFeedsContainerViewController {
    
    private func handlePodcastEpisodeCellSelection(_ managedObjectID: NSManagedObjectID) {
        feedsListContainerDelegate?.viewController(
            self,
            didSelectPodcastEpisodeWithID: managedObjectID
        )
    }
    
    private func handlePodcastFeedCellSelection(_ podcastFeed: PodcastFeed) {
        feedsListContainerDelegate?.viewController(
            self,
            didSelectPodcastFeed: podcastFeed
        )
    }
}


// MARK: - Video Selection
extension DashboardFeedsContainerViewController {
    
    private func handleVideoEpisodeCellSelection(_ managedObjectID: NSManagedObjectID) {
        feedsListContainerDelegate?.viewController(
            self,
            didSelectVideoEpisodeWithID: managedObjectID
        )
    }
    
    
    private func handleVideoFeedCellSelection(_ managedObjectID: NSManagedObjectID) {
        feedsListContainerDelegate?.viewController(
            self,
            didSelectVideoFeedWithID: managedObjectID
        )
    }
}

// MARK: - Newsletter Selection
extension DashboardFeedsContainerViewController {
    
    private func handleNewsletterItemCellSelection(_ managedObjectID: NSManagedObjectID) {
        feedsListContainerDelegate?.viewController(
            self,
            didSelectNewsletterItemWithID: managedObjectID
        )
    }
    
    
    private func handleNewsletterFeedCellSelection(_ managedObjectID: NSManagedObjectID) {
        feedsListContainerDelegate?.viewController(
            self,
            didSelectNewsletterFeedWithID: managedObjectID
        )
    }
}
