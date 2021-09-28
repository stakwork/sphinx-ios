//  DashboardFeedsContainerViewController.swift
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import CoreData


protocol DashboardFeedsListContainerViewControllerDelegate: AnyObject {
    
    func viewController(
        _ viewController: UIViewController,
        didSelectPodcastFeedWithID podcastFeedID: NSManagedObjectID
    )
    
    func viewController(
        _ viewController: UIViewController,
        didSelectPodcastEpisodeWithID podcastEpisodeID: NSManagedObjectID
    )
}


class DashboardFeedsContainerViewController: UIViewController {
    @IBOutlet weak var filterChipCollectionViewContainer: UIView!
    @IBOutlet weak var feedContentCollectionViewContainer: UIView!
    
    private var managedObjectContext: NSManagedObjectContext!
    private var filterChipCollectionViewController: FeedFilterChipsCollectionViewController!
    private var feedContentCollectionViewController: FeedContentCollectionViewController!
    private weak var feedsListContainerDelegate: DashboardFeedsListContainerViewControllerDelegate?
    
    var contentFilterOptions: [ContentFilterOption] = []
    
    var activeFilterOption: ContentFilterOption = .allContent {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.handleFilterChipChange()
            }
        }
    }
    
    var fetchedResultsController: NSFetchedResultsController<PodcastFeed>!
    
    
    internal lazy var emptyStateViewController: PodcastFeedsContentEmptyStateViewController = {
        PodcastFeedsContentEmptyStateViewController.instantiate(
            contentFilterOption: activeFilterOption
        )
    }()
    
    
    static func instantiate(
        managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext,
        feedsListContainerDelegate: DashboardFeedsListContainerViewControllerDelegate
    ) -> DashboardFeedsContainerViewController {
        let viewController = StoryboardScene.Dashboard.feedsListViewController.instantiate()
        
        viewController.managedObjectContext = managedObjectContext
        viewController.fetchedResultsController = makeFetchedResultsController(
            using: managedObjectContext
        )
        viewController.feedsListContainerDelegate = feedsListContainerDelegate
        
        return viewController
    }
    
    
    static func makeFetchedResultsController(
        using managedObjectContext: NSManagedObjectContext
    ) -> NSFetchedResultsController<PodcastFeed> {
        NSFetchedResultsController(
            fetchRequest: PodcastFeed.FetchRequests.default(),
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
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
    
  
    private func handleLatestEpisodeCellSelection(_ managedObjectID: NSManagedObjectID) {
        feedsListContainerDelegate?.viewController(
            self,
            didSelectPodcastEpisodeWithID: managedObjectID
        )
    }
    
    private func handleLatestFeedCellSelection(_ managedObjectID: NSManagedObjectID) {
        feedsListContainerDelegate?.viewController(
            self,
            didSelectPodcastFeedWithID: managedObjectID
        )
    }
    
    
    private func handleNewResultsFetch(_ numberOfItems: Int) {
        if numberOfItems == 0 {
            showEmptyStateViewController()
        } else {
            removeEmptyStateViewController()
        }
    }
    
    
    private func handleFilterChipChange() {
        removeEmptyStateViewController()
        
        switch activeFilterOption.id {
        case ContentFilterOption.allContent.id:
            feedContentCollectionViewController.fetchItems()
        case ContentFilterOption.listen.id:
            feedContentCollectionViewController.fetchItems()
        case ContentFilterOption.watch.id:
            showEmptyStateViewController()
        case ContentFilterOption.read.id:
            showEmptyStateViewController()
        case ContentFilterOption.play.id:
            showEmptyStateViewController()
        default:
            break
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
        feedContentCollectionViewController = FeedContentCollectionViewController
            .instantiate(
                fetchedResultsController: fetchedResultsController,
                onPodcastEpisodeCellSelected: handleLatestEpisodeCellSelection(_:),
                onPodcastFeedCellSelected: handleLatestFeedCellSelection(_:),
                onNewResultsFetched: handleNewResultsFetch(_:)
            )
        
        addChildVC(
            child: feedContentCollectionViewController,
            container: feedContentCollectionViewContainer
        )
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
}

