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
        didSelectPodcastFeed podcastFeed: PodcastFeed
    )
}


class PodcastFeedSearchContainerViewController: UIViewController {
    @IBOutlet weak var contentView: UIView!
    
    private var managedObjectContext: NSManagedObjectContext!
    private weak var resultsDelegate: PodcastFeedSearchResultsViewControllerDelegate?
    
    
    lazy var fetchedResultsController: NSFetchedResultsController = Self
        .makeFetchedResultsController(
            using: managedObjectContext,
            and: ContentFeed.FetchRequests.podcastFeeds()
        )
    
    
    internal lazy var searchResultsViewController: PodcastFeedSearchResultsCollectionViewController = {
        PodcastFeedSearchResultsCollectionViewController
            .instantiate(
                onSubscribedPodcastFeedCellSelected: handleFeedCellSelection,
                onPodcastFeedSearchResultCellSelected: handleSearchResultCellSelection,
                onPodcastFeedSubscriptionSelected: handlePodcastFeedSubscription,
                onPodcastFeedSubscriptionCancellationSelected: handlePodcastFeedSubscriptionCancellation
            )
    }()
    
    
    internal lazy var emptyStateViewController: PodcastFeedSearchEmptyStateViewController = {
        PodcastFeedSearchEmptyStateViewController.instantiate()
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
        and fetchRequest: NSFetchRequest<ContentFeed>
    ) -> NSFetchedResultsController<ContentFeed> {
        NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }
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
        let newFetchRequest = PodcastFeed
            .FetchRequests
            .matching(searchQuery: searchQuery)
        
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
        
        API.sharedInstance.searchForPodcasts(
            matching: searchQuery
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let foundFeeds):
                    
                    let podcastFeeds = foundFeeds.map {
                        PodcastFeed.convertFrom(contentFeed: $0)
                    }
                    
                    self.searchResultsViewController.updateWithNew(
                        searchResults: podcastFeeds
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
    
    
    private func handleFeedCellSelection(_ podcastFeed: PodcastFeed) {
        resultsDelegate?.viewController(
            self,
            didSelectPodcastFeed: podcastFeed
        )
    }
    
    private func handleSearchResultCellSelection(
        _ searchResult: PodcastFeed
    ) {
        let existingFeedsFetchRequest: NSFetchRequest<ContentFeed> = ContentFeed
            .FetchRequests
            .matching(feedID: searchResult.feedID)
        
        let fetchRequestResult = try! managedObjectContext.fetch(existingFeedsFetchRequest)
            
        if let existingContentFeed = fetchRequestResult.first {
            let podcastFeed = PodcastFeed.convertFrom(contentFeed: existingContentFeed)
            
            resultsDelegate?.viewController(
                self,
                didSelectPodcastFeed: podcastFeed
            )
        } else {
            if let feedUrl = searchResult.feedURLPath {
                let tribesServerURL = "\(API.kTestTribesServerBaseURL)/feed?url=\(feedUrl)"
                
                API.sharedInstance.getContentFeed(
                    url: tribesServerURL,
                    persistingIn: managedObjectContext,
                    callback: { feed in
                        
                        let podcast = PodcastFeed.convertFrom(contentFeed: feed)
                        
                        self.managedObjectContext.saveContext()
                        
                        self.resultsDelegate?.viewController(
                            self,
                            didSelectPodcastFeed: podcast
                        )
                    },
                    errorCallback: {}
                )
            }
        }
    }
    
    
    private func handlePodcastFeedSubscription(
        _ searchResult: PodcastFeed
    ) {
        
        searchResult.isSubscribedToFromSearch = true
        
        if let contentFeed = managedObjectContext.object(with: searchResult.objectID) as? ContentFeed {
            contentFeed.isSubscribedToFromSearch = true
            contentFeed.managedObjectContext?.saveContext()
        }

        if let currentIndex = searchResultsViewController.podcastFeedSearchResults.firstIndex(of: searchResult) {
            searchResultsViewController.podcastFeedSearchResults.remove(at: currentIndex)
        }
        
        searchResultsViewController.subscribedPodcastFeeds.append(searchResult)
        
        DispatchQueue.main.async { [weak self] in
            self?.searchResultsViewController.updateSnapshot(shouldAnimate: true)
        }
    }
    
    
    private func handlePodcastFeedSubscriptionCancellation(
        _ searchResult: PodcastFeed
    ) {
        
        searchResult.isSubscribedToFromSearch = false
        
        if let contentFeed = managedObjectContext.object(with: searchResult.objectID) as? ContentFeed {
            contentFeed.isSubscribedToFromSearch = false
            contentFeed.managedObjectContext?.saveContext()
        }
    
        if let currentIndex = searchResultsViewController.subscribedPodcastFeeds.firstIndex(of: searchResult) {
            searchResultsViewController.subscribedPodcastFeeds.remove(at: currentIndex)
        }
        
        searchResultsViewController.podcastFeedSearchResults.append(searchResult)
        
        DispatchQueue.main.async { [weak self] in
            self?.searchResultsViewController.updateSnapshot(shouldAnimate: true)
            CoreDataManager.sharedManager.saveContext()
        }
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
            let foundFeeds = firstSection.objects as? [ContentFeed]
        else {
            return
        }
        
        let subscribedPodcastFeeds: [PodcastFeed] = foundFeeds
            .compactMap {
                guard $0.chat != nil else {
                    return nil
                }
                
                return PodcastFeed.convertFrom(contentFeed: $0)
            }
        
        DispatchQueue.main.async { [weak self] in
            self?.searchResultsViewController.updateWithNew(
                subscribedPodcastFeeds: subscribedPodcastFeeds
            )
        }
    }
}
