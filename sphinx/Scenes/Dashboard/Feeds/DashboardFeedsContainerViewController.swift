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
        didSelectPodcastEpisodeWithID podcastEpisodeID: String,
        fromDownloadedSection: Bool
    )
    
    func viewController(
        _ viewController: UIViewController,
        didSelectVideoFeedWithID videoFeedID: String
    )
    
    func viewController(
        _ viewController: UIViewController,
        didSelectVideoEpisodeWithID videoEpisodeID: String
    )
    
    func viewController(
        _ viewController: UIViewController,
        didSelectNewsletterFeedWithID newsletterFeedID: String
    )
    
    func viewController(
        _ viewController: UIViewController,
        didSelectNewsletterItemWithID newsletterItemID: String
    )
    
    func viewController(
        _ viewController: UIViewController,
        didSelectRecommendationWithId recommendationId: String,
        from recommendations: [RecommendationResult]
    )
    
    func viewControllerContentScrolled(
        scrollView: UIScrollView
    )
}


class DashboardFeedsContainerViewController: UIViewController {
    
    @IBOutlet weak var filterChipCollectionViewContainer: UIView!
    @IBOutlet weak var feedContentCollectionViewContainer: UIView!
    @IBOutlet weak var loadingWheelContainerView: UIView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
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
    
    var isLoading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(
                loading: isLoading,
                loadingWheel: loadingWheel,
                loadingWheelColor: UIColor.Sphinx.Text
            )
            loadingWheelContainerView.isHidden = !isLoading
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
            onDownloadedItemSelected: handleDownloadedItemCellSelection(_:_:),
            onRecommendationSelected: handleRecommendationSelection(_:_:),
            onNewResultsFetched: handleNewResultsFetch(_:),
            onContentScrolled: handleFeedScroll(scrollView:)
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
    
    internal lazy var downloadedPodcastsVC : ProfileManageStorageSourceDetailsVC = {
        let vc = ProfileManageStorageSourceDetailsVC.instantiate(
            items: StorageManager.sharedManager.allItems,
            source: .podcasts,
            sourceTotalSize: 69420
        )
        vc.presentationContext = .downloadedPodcastList
        return vc
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
        view.accessibilityIdentifier = "DashboardFeedsContainerViewController"
        isLoading = true
        
        setupFilterOptions()
        configureFilterChipCollectionView()
        configureFeedContentCollectionView()
        
        DelayPerformedHelper.performAfterDelay(
            seconds: 0.5,
            completion: {
                self.isLoading = false
            }
        )
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
        actionsManager.syncActions() {
            
            if (PodcastPlayerController.sharedInstance.isPlayingRecommendations()) {
                return
            }

            self.allTribeFeedsCollectionViewController.loadRecommendations()
        }
    }
    
    
    private func configureFilterChipCollectionView() {
        filterChipCollectionViewController = FeedFilterChipsCollectionViewController.instantiate(
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
        _ feedId: String
    ) {
        if let contentFeed = ContentFeed.getFeedById(feedId: feedId) {
            if contentFeed.isNewsletter {
                feedsListContainerDelegate?.viewController(
                    self,
                    didSelectNewsletterFeedWithID: feedId
                )
            } else if contentFeed.isVideo {
                feedsListContainerDelegate?.viewController(
                    self,
                    didSelectVideoFeedWithID: feedId
                )
            } else if contentFeed.isPodcast {
                feedsListContainerDelegate?.viewController(
                    self,
                    didSelectPodcastFeed: PodcastFeed.convertFrom(contentFeed: contentFeed)
                )
            }
        }
    }
    
    private func handleDownloadedItemCellSelection(
        _ feedId: String,
        _ episodeId: String
    ) {
        feedsListContainerDelegate?.viewController(
            self,
            didSelectPodcastEpisodeWithID: episodeId,
            fromDownloadedSection: true
        )
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
    
    private func handlePodcastEpisodeCellSelection(_ feedItemId: String) {
        feedsListContainerDelegate?.viewController(
            self,
            didSelectPodcastEpisodeWithID: feedItemId,
            fromDownloadedSection: false
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
    
    private func handleVideoEpisodeCellSelection(_ feedItemId: String) {
        feedsListContainerDelegate?.viewController(
            self,
            didSelectVideoEpisodeWithID: feedItemId
        )
    }
    
    
    private func handleVideoFeedCellSelection(_ feedId: String) {
        feedsListContainerDelegate?.viewController(
            self,
            didSelectVideoFeedWithID: feedId
        )
    }
}

// MARK: - Newsletter Selection
extension DashboardFeedsContainerViewController {
    
    private func handleNewsletterItemCellSelection(_ feeditemId: String) {
        feedsListContainerDelegate?.viewController(
            self,
            didSelectNewsletterItemWithID: feeditemId
        )
    }
    
    
    private func handleNewsletterFeedCellSelection(_ feedId: String) {
        feedsListContainerDelegate?.viewController(
            self,
            didSelectNewsletterFeedWithID: feedId
        )
    }
}
