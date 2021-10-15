import UIKit
import CoreData


class PodcastFeedCollectionViewController: UICollectionViewController {
    var interSectionSpacing: CGFloat!
    
    var onPodcastEpisodeCellSelected: ((NSManagedObjectID) -> Void)!
    var onPodcastFeedCellSelected: ((NSManagedObjectID) -> Void)!
    var onNewResultsFetched: ((Int) -> Void)!

    private var managedObjectContext: NSManagedObjectContext!
    private var fetchedResultsController: NSFetchedResultsController<PodcastFeed>!
    private var currentDataSnapshot: DataSourceSnapshot!
    private var dataSource: DataSource!
    
    private let itemContentInsets = NSDirectionalEdgeInsets(
        top: 0,
        leading: 10,
        bottom: 0,
        trailing: 10
    )
}


// MARK: - Instantiation
extension PodcastFeedCollectionViewController {

    static func instantiate(
        managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext,
//        fetchedResultsController: NSFetchedResultsController<PodcastFeed>,
        interSectionSpacing: CGFloat = 10.0,
        onPodcastEpisodeCellSelected: @escaping ((NSManagedObjectID) -> Void) = { _ in },
        onPodcastFeedCellSelected: @escaping ((NSManagedObjectID) -> Void) = { _ in },
        onNewResultsFetched: @escaping ((Int) -> Void) = { _ in }
    ) -> PodcastFeedCollectionViewController {
        let viewController = StoryboardScene.Dashboard.podcastFeedCollectionViewController.instantiate()

        viewController.managedObjectContext = managedObjectContext
        viewController.interSectionSpacing = interSectionSpacing
        
        viewController.onPodcastEpisodeCellSelected = onPodcastEpisodeCellSelected
        viewController.onPodcastFeedCellSelected = onPodcastFeedCellSelected
        viewController.onNewResultsFetched = onNewResultsFetched
        
//        viewController.fetchedResultsController = fetchedResultsController
        viewController.fetchedResultsController = Self.makeFetchedResultsController(using: managedObjectContext)
        viewController.fetchedResultsController.delegate = viewController
        
        return viewController
    }
}


// MARK: - Layout & Data Structure
extension PodcastFeedCollectionViewController {
    
    enum CollectionViewSection: Int, CaseIterable {
        
        /// New episodes
        case latestPodcastEpisodes
        
        /// Podcasts that the user is subscribed to
        case subscribedPodcastFeeds
        
        var titleForDisplay: String {
            switch self {
            case .latestPodcastEpisodes:
                return "Listen Now"
            case .subscribedPodcastFeeds:
                return "Following"
            }
        }
    }
    
    typealias ReusableHeaderView = DashboardFeedCollectionViewSectionHeader
    typealias CollectionViewCell = PodcastFeedCollectionViewCell
    typealias CellDataItemType = NSManagedObjectID
    typealias DataSource = UICollectionViewDiffableDataSource<CollectionViewSection.RawValue, CellDataItemType>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection.RawValue, CellDataItemType>
}



// MARK: - Lifecycle
extension PodcastFeedCollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        registerViews(for: collectionView)
        configure(collectionView)
        configureDataSource(for: collectionView)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        fetchItems()
    }
}


// MARK: - Layout Composition
extension PodcastFeedCollectionViewController {

    func makeSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(80)
        )

        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }


    func makeFeedContentSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = itemContentInsets


        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(160.0),
            heightDimension: .absolute(240.0)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])


        let section = NSCollectionLayoutSection(group: group)

        section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
        section.boundarySupplementaryItems = [makeSectionHeader()]
//        section.contentInsets = .init(top: 21, leading: 0, bottom: 21, trailing: 0)

        return section
    }


    func makeSectionProvider() -> UICollectionViewCompositionalLayoutSectionProvider {
        { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            self.makeFeedContentSection()
        }
    }


    func makeLayout() -> UICollectionViewLayout {
        let layoutConfiguration = UICollectionViewCompositionalLayoutConfiguration()
        
        layoutConfiguration.interSectionSpacing = interSectionSpacing
        
        let layout = UICollectionViewCompositionalLayout(
            sectionProvider: makeSectionProvider()
        )
        
        layout.configuration = layoutConfiguration

        return layout
    }
}


// MARK: - Collection View Configuration and View Registration
extension PodcastFeedCollectionViewController {

    func registerViews(for collectionView: UICollectionView) {
        collectionView.register(
            PodcastFeedCollectionViewCell.nib,
            forCellWithReuseIdentifier: PodcastFeedCollectionViewCell.reuseID
        )

        collectionView.register(
            ReusableHeaderView.nib,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ReusableHeaderView.reuseID
        )
    }


    func configure(_ collectionView: UICollectionView) {
        collectionView.collectionViewLayout = makeLayout()
        
        collectionView.backgroundColor = .Sphinx.ListBG
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = .init(top: 20, left: 0, bottom: 0, right: 0)
        collectionView.delegate = self
    }
}



// MARK: - Data Source Configuration
extension PodcastFeedCollectionViewController {

    func makeDataSource(for collectionView: UICollectionView) -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: makeCellProvider(for: collectionView)
        )

        dataSource.supplementaryViewProvider = makeSupplementaryViewProvider(for: collectionView)

        return dataSource
    }


    func configureDataSource(for collectionView: UICollectionView) {
        dataSource = makeDataSource(for: collectionView)
    }
    
    
    func fetchItems() {
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

// MARK: - Data Source View Providers
extension PodcastFeedCollectionViewController {

    func makeCellProvider(
        for collectionView: UICollectionView
    ) -> DataSource.CellProvider {
        { (collectionView, indexPath, dataSourceItem) -> UICollectionViewCell? in
            guard
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CollectionViewCell.reuseID,
                    for: indexPath
                ) as? CollectionViewCell
            else {
                return nil
            }

            guard
                let managedObject = try? self
                    .managedObjectContext
                    .existingObject(with: dataSourceItem)
            else {
                return nil
            }
            
            if let podcastFeed = managedObject as? PodcastFeed {
                cell.configure(withItem: podcastFeed)
            } else if let podcastEpisode = managedObject as? PodcastEpisode {
                cell.configure(withItem: podcastEpisode)
            }
            
            return cell
        }
    }


    func makeSupplementaryViewProvider(
        for collectionView: UICollectionView
    ) -> DataSource.SupplementaryViewProvider {
        { (
            collectionView: UICollectionView,
            kind: String,
            indexPath: IndexPath
        ) -> UICollectionReusableView in
            guard let section = CollectionViewSection(rawValue: indexPath.section) else {
                return UICollectionReusableView()
            }
            
            switch kind {
            case UICollectionView.elementKindSectionHeader:
                guard let headerView = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: ReusableHeaderView.reuseID,
                    for: indexPath
                ) as? ReusableHeaderView else {
                    return UICollectionReusableView()
                }
                
                headerView.render(withTitle: section.titleForDisplay)

                return headerView
            default:
                return UICollectionReusableView()
            }
        }
    }
}


// MARK: -  Static Helpers
extension PodcastFeedCollectionViewController {
    
    static func makeFetchedResultsController(
        using managedObjectContext: NSManagedObjectContext
    ) -> NSFetchedResultsController<PodcastFeed> {
        let fetchRequest = PodcastFeed.FetchRequests.followedFeeds()
        
        return NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }
}


// MARK: - `UICollectionViewDelegate` Methods
extension PodcastFeedCollectionViewController {
    
    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard
            let managedObjectID = dataSource.itemIdentifier(for: indexPath),
            let managedObject = try? managedObjectContext
                .existingObject(with: managedObjectID)
        else {
            return
        }
        
        if let _ = managedObject as? PodcastFeed {
            onPodcastFeedCellSelected(managedObjectID)
        } else if let _ = managedObject as? PodcastEpisode {
            onPodcastEpisodeCellSelected(managedObjectID)
        }
    }
}


// MARK: - `NSFetchedResultsControllerDelegate` Methods
extension PodcastFeedCollectionViewController: NSFetchedResultsControllerDelegate {

    /// Called when the contents of the fetched results controller change.
    ///
    /// If this method is implemented, no other delegate methods will be invoked.
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        guard let dataSource = dataSource else {
            assertionFailure("The data source has not implemented snapshot support while it should")
            return
        }
        
        var changedSnapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
        let currentSnapshot = dataSource.snapshot() as DataSourceSnapshot
        
        let feedItemIDsToReload: [NSManagedObjectID] = changedSnapshot
            .itemIdentifiers
            .compactMap { managedObjectID in
                guard
                    let currentIndex = currentSnapshot.indexOfItem(managedObjectID),
                    let changedIndex = changedSnapshot.indexOfItem(managedObjectID),
                    changedIndex == currentIndex
                else {
                    return nil
                }
            
                guard
                    let existingObject = try? fetchedResultsController
                        .managedObjectContext
                        .existingObject(with: managedObjectID),
                    existingObject.isUpdated
                else {
                    return nil
                }
            
                return managedObjectID
            }
        
        
        // We have feeds... now make an episodes section from them...
        changedSnapshot.appendSections([
            CollectionViewSection.latestPodcastEpisodes.rawValue,
       ])

       changedSnapshot.appendItems(
           changedSnapshot
               .itemIdentifiers
               .compactMap {
                   try? fetchedResultsController
                       .managedObjectContext
                       .existingObject(with: $0)
               }
               .compactMap { $0 as? PodcastFeed }
               .compactMap { $0.getCurrentEpisode()?.objectID }
           ,
           toSection: CollectionViewSection.latestPodcastEpisodes.rawValue
       )
        
        changedSnapshot.reloadItems(feedItemIDsToReload)
        
        let shouldAnimate = collectionView?.numberOfSections == CollectionViewSection.allCases.count
        
        dataSource.apply(
            changedSnapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>,
            animatingDifferences: shouldAnimate
        )
        
        onNewResultsFetched(changedSnapshot.numberOfItems)
    }
}


extension PodcastEpisode: DashboardPodcastCollectionViewItem {
    var subtitle: String? {
        formattedDescription
    }
}


extension PodcastFeed: DashboardPodcastCollectionViewItem {
    var subtitle: String? {
        podcastDescription ?? ""
    }
}
