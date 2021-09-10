// PodcastFeedSearchContainerViewController.swift
//
// Created by CypherPoet.
// ✌️
//


import UIKit
import CoreData


protocol PodcastFeedSearchResultsViewControllerDelegate: AnyObject {
    
    func viewController(
        _ viewController: UIViewController,
        didSelectPodcastFeedWithID podcastFeedID: NSManagedObjectID
    )
}


class PodcastFeedSearchContainerViewController: UIViewController {
    @IBOutlet weak var contentView: UIView!
    
    private var managedObjectContext: NSManagedObjectContext!
    private weak var resultsDelegate: PodcastFeedSearchResultsViewControllerDelegate?
    
    
    internal lazy var fetchedResultsController: NSFetchedResultsController = PodcastFeedSearchContainerViewController
        .makeFetchedResultsController(
            using: managedObjectContext,
            and: PodcastFeed.FetchRequests.default()
        )
    
    
    internal lazy var searchResultsViewController: PodcastFeedSearchResultsCollectionViewController = {
        PodcastFeedSearchResultsCollectionViewController
            .instantiate(
                onPodcastFeedCellSelected: handleFeedCellSelection,
                onPodcastDirectoryResultCellSelected: handleDirectoryResultCellSelection,
                onPodcastSubscriptionAdded: handlePodcastDirectorySubscription
            )
    }()
    
    
    internal lazy var emptyStateViewController: PodcastFeedSearchEmptyStateViewController = {
        PodcastFeedSearchEmptyStateViewController.instantiate(
            
        )
    }()
    
    
    private var isShowingStartingEmptyStateVC: Bool = true
}



// MARK: -  Static Properties
extension PodcastFeedSearchContainerViewController {
    
    static func instantiate(
        managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext,
        resultsDelegate: PodcastFeedSearchResultsViewControllerDelegate
    ) -> PodcastFeedSearchContainerViewController {
        let viewController = StoryboardScene
            .Dashboard
            .podcastFeedSearchContainerViewController
            .instantiate()
        
        viewController.managedObjectContext = managedObjectContext
        viewController.resultsDelegate = resultsDelegate
        viewController.fetchedResultsController.delegate = viewController
        
        return viewController
    }
    
    
    static func makeFetchedResultsController(
        using managedObjectContext: NSManagedObjectContext,
        and fetchRequest: NSFetchRequest<PodcastFeed>
    ) -> NSFetchedResultsController<PodcastFeed> {
        NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }
    
    
    static let apiKey = Bundle
        .main
        .object(forInfoDictionaryKey: "PODCAST_INDEX_API_KEY") as! String
    
    
    static let apiSecret = Bundle
        .main
        .object(forInfoDictionaryKey: "PODCAST_INDEX_API_SECRET") as! String
}


// MARK: -  Lifecycle
extension PodcastFeedSearchContainerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureStartingEmptyStateView()
    }
}


// MARK: - Public Methods
extension PodcastFeedSearchContainerViewController {
    
    func updateSearchQuery(with searchQuery: String) {
        if searchQuery.isEmpty {
            presentInitialStateView()
        } else {
            presentResultsListView()
            fetchResults(for: searchQuery)
        }
    }
    
    
    func presentResultsListView() {
        isShowingStartingEmptyStateVC = false
        
        removeChildVC(child: emptyStateViewController)
        
        addChildVC(
            child: searchResultsViewController,
            container: contentView
        )
    }
    
    
    func presentInitialStateView() {
        isShowingStartingEmptyStateVC = true
        
        removeChildVC(child: searchResultsViewController)
        
        addChildVC(
            child: emptyStateViewController,
            container: contentView
        )
    }
}


// MARK: -  Private Helpers
extension PodcastFeedSearchContainerViewController {
    
    private func fetchResults(for searchQuery: String) {
        let newFetchRequest = PodcastFeed.FetchRequests.matching(searchQuery: searchQuery)
        
        fetchedResultsController.fetchRequest.sortDescriptors = newFetchRequest.sortDescriptors
        fetchedResultsController.fetchRequest.predicate = newFetchRequest.predicate
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            AlertHelper.showAlert(
                title: "Data Loading Error",
                message: "\(error)"
            )
        }
        
        
        API.sharedInstance.searchPodcastIndex(
            matching: searchQuery,
            apiKey: Self.apiKey,
            apiSecret: Self.apiSecret
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                //                self.stopProgressIndicator()
                
                switch result {
                case .success(let searchResults):
                    self.searchResultsViewController.updateWithNew(
                        directorySearchResults: searchResults
                    )
                case .failure(_):
                    AlertHelper.showAlert(
                        title: "dashboard.feeds.search.error-alert-title".localized,
                        message: """
                        \("generic.contact-support".localized)
                        """
                    )
                }
            }
        }
    }
    
    
    private func configureStartingEmptyStateView() {
        addChildVC(
            child: emptyStateViewController,
            container: contentView
        )
    }
    
    
    private func handleFeedCellSelection(_ podcastFeedID: NSManagedObjectID) {
        // 📝 TODO:  Implement
    }
    
    
    private func handleDirectoryResultCellSelection(
        _ directoryResult: PodcastFeedSearchResult
    ) {
        // 📝 TODO:  Implement
    }
    
    
    private func handlePodcastDirectorySubscription(
        _ directoryResult: PodcastFeedSearchResult
    ) {
        // 📝 TODO:  Implement
    }
}


extension PodcastFeedSearchContainerViewController: NSFetchedResultsControllerDelegate {
    
    /// Called when the contents of the fetched results controller change.
    ///
    /// If this method is implemented, no other delegate methods will be invoked.
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        guard
            let resultController = controller as? NSFetchedResultsController<NSManagedObject>,
            let firstSection = resultController.sections?.first,
            let foundFeeds = firstSection.objects as? [PodcastFeed]
        else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.searchResultsViewController.updateWithNew(podcastFeeds: foundFeeds)
        }
    }
}
