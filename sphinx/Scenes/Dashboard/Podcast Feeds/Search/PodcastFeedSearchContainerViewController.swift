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
        PodcastFeedSearchResultsCollectionViewController.instantiate(
        
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
        defer { isShowingStartingEmptyStateVC = false }
        
        if isShowingStartingEmptyStateVC {
            emptyStateViewController.removeFromParent()
            
            addChildVC(
                child: searchResultsViewController,
                container: contentView
            )
        }
        
        fetchResults(for: searchQuery)
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
        
        // 📝 TODO:  We'll also need to fetch from the podcast directory at the same time here
    }
     
    
    private func configureStartingEmptyStateView() {
        addChildVC(
            child: emptyStateViewController,
            container: contentView
        )
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
