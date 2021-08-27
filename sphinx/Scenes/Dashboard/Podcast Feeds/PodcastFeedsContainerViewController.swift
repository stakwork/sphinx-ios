//
//  FeedsListViewController.swift
//  PodcastFeedsContainerViewController
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import CoreData


class PodcastFeedsContainerViewController: UIViewController {
    @IBOutlet weak var filterChipCollectionViewContainer: UIView!
    @IBOutlet weak var feedContentCollectionViewContainer: UIView!
    
    private var managedObjectContext: NSManagedObjectContext!
    private var filterChipCollectionViewController: FeedFilterChipsCollectionViewController!
    private var feedContentCollectionViewController: FeedContentCollectionViewController!
    
    
    var contentFilterOptions: [ContentFilterOption] = []
    var activeFilterOption: ContentFilterOption = .allContent
    var latestPodcastEpisodes: [PodcastEpisode] = []
    var subscribedPodcastFeeds: [PodcastFeed] = []
    
    var fetchedResultsController: NSFetchedResultsController<PodcastFeed>!
    
    
    static func instantiate(
        managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext
    ) -> PodcastFeedsContainerViewController {
        let viewController = StoryboardScene.Dashboard.feedsListViewController.instantiate()
        
        viewController.managedObjectContext = managedObjectContext
        viewController.fetchedResultsController = makeFetchedResultsController(
            using: managedObjectContext
        )
        
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
        
        loadData()
        configureFilterChipCollectionView()
        configureFeedContentCollectionView()
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            AlertHelper.showAlert(
                title: "Data Loading Error",
                message: "\(error)"
            )
        }
    }
}


// MARK: -  Private Helpers
extension PodcastFeedsContainerViewController {
    
    private func loadData() {
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
        AlertHelper.showAlert(
            title: "Selected Podcast Episode",
            message: managedObjectID.description
        )
    }
    
    private func handleLatestFeedCellSelection(_ managedObjectID: NSManagedObjectID) {
        AlertHelper.showAlert(
            title: "Selected Podcast Feed",
            message: managedObjectID.description
        )
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
                onPodcastFeedCellSelected: handleLatestFeedCellSelection(_:)
            )
        
        addChildVC(
            child: feedContentCollectionViewController,
            container: feedContentCollectionViewContainer
        )
    }
}

