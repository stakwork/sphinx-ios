import UIKit
import CoreData


class FeedContentCollectionViewController: UICollectionViewController {
    
    var latestPodcastEpisodes: [PodcastEpisode]!
    var subscribedPodcastFeeds: [PodcastFeed]!
    var interSectionSpacing: CGFloat!
    
    var onPodcastEpisodeCellSelected: ((NSManagedObjectID) -> Void)!
    var onPodcastFeedCellSelected: ((NSManagedObjectID) -> Void)!

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
extension FeedContentCollectionViewController {

    static func instantiate(
        managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext,
        fetchedResultsController: NSFetchedResultsController<PodcastFeed>,
        interSectionSpacing: CGFloat = 10.0,
        onPodcastEpisodeCellSelected: @escaping ((NSManagedObjectID) -> Void) = { _ in },
        onPodcastFeedCellSelected: @escaping ((NSManagedObjectID) -> Void) = { _ in }
    ) -> FeedContentCollectionViewController {
        let viewController = StoryboardScene.Dashboard.feedContentCollectionViewController.instantiate()

        viewController.managedObjectContext = managedObjectContext
        viewController.interSectionSpacing = interSectionSpacing
        viewController.onPodcastEpisodeCellSelected = onPodcastEpisodeCellSelected
        viewController.onPodcastFeedCellSelected = onPodcastFeedCellSelected
        viewController.fetchedResultsController = fetchedResultsController
        viewController.fetchedResultsController.delegate = viewController
        
        return viewController
    }
}


// MARK: - Layout & Data Structure
extension FeedContentCollectionViewController {
    enum CollectionViewSection: Int, CaseIterable {
        case latestPodcastEpisodes
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
    
    enum DataSourceItem: Hashable {
        case latestPodcastEpisode(NSManagedObjectID)
        case subscribedPodcastFeed(NSManagedObjectID)
    }
    
    typealias ReusableHeaderView = PodcastFeedCollectionViewSectionHeader
    typealias CollectionViewCell = PodcastFeedCollectionViewCell
    typealias CellDataItemType = DataSourceItem
    typealias DataSource = UICollectionViewDiffableDataSource<CollectionViewSection, CellDataItemType>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, CellDataItemType>
}



// MARK: - Lifecycle
extension FeedContentCollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        registerViews(for: collectionView)
        configure(collectionView)
        configureDataSource(for: collectionView)
    }
}


// MARK: - Layout Composition
extension FeedContentCollectionViewController {

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
extension FeedContentCollectionViewController {

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
extension FeedContentCollectionViewController {

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
}

// MARK: - Data Source View Providers
extension FeedContentCollectionViewController {

    func makeCellProvider(
        for collectionView: UICollectionView
    ) -> DataSource.CellProvider {
        { (collectionView, indexPath, dataItem) -> UICollectionViewCell? in
            guard
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CollectionViewCell.reuseID,
                    for: indexPath
                ) as? CollectionViewCell
            else {
                return nil
            }

            
            switch dataItem {
            case .latestPodcastEpisode(let episodeManagedObjectID):
                guard
                    let managedObject = try? self.managedObjectContext
                        .existingObject(with: episodeManagedObjectID),
                    let podcastEpisode = managedObject as? PodcastEpisode
                else {
                    preconditionFailure("PodcastEpisode managed object should be available")
                }
                
                cell.configure(withItem: podcastEpisode)
            case .subscribedPodcastFeed(let feedManagedObjectID):
                guard
                    let managedObject = try? self.managedObjectContext
                        .existingObject(with: feedManagedObjectID),
                    let podcastFeed = managedObject as? PodcastFeed
                else {
                    preconditionFailure("PodcastFeed managed object should be available")
                }
                
                cell.configure(withItem: podcastFeed)
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
        ) -> UICollectionReusableView? in
            guard let section = CollectionViewSection(rawValue: indexPath.section) else {
                return nil
            }
            
            switch kind {
            case UICollectionView.elementKindSectionHeader:
                guard let headerView = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: ReusableHeaderView.reuseID,
                    for: indexPath
                ) as? ReusableHeaderView else {
                    return nil
                }
                
                headerView.render(withTitle: section.titleForDisplay)

                return headerView
            default:
                return nil
            }
        }
    }
}


// MARK: - `UICollectionViewDelegate` Methods
extension FeedContentCollectionViewController {
    
    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return
        }

        switch item {
        case .latestPodcastEpisode(let podcastEpisode):
            onPodcastEpisodeCellSelected(podcastEpisode)
        case .subscribedPodcastFeed(let podcastFeed):
            onPodcastFeedCellSelected(podcastFeed)
        }
    }
}


// MARK: - `NSFetchedResultsControllerDelegate` Methods
extension FeedContentCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func managedObjectID(
        for itemIdentifier: CellDataItemType,
        in snapshot: DataSourceSnapshot
    ) -> NSManagedObjectID {
        switch itemIdentifier {
        case .latestPodcastEpisode(let episodeManagedObjectID):
            return episodeManagedObjectID
        case .subscribedPodcastFeed(let feedManagedObjectID):
            return feedManagedObjectID
        }
    }
    
    
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
        
        let changedSnapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        var currentSnapshot = dataSource.snapshot() as DataSourceSnapshot
        
        guard let sectionIdentifier = changedSnapshot.sectionIdentifiers.first else { return }

        let feeds = changedSnapshot.itemIdentifiers(inSection: sectionIdentifier)
            .compactMap { changedSnapshot.indexOfItem($0) } // get indices of IDs
            .map { IndexPath(row: $0, section: 0) } // convert indices to index paths
            .map { fetchedResultsController.object(at: $0) } // get object by its index path
        
        let feedItems = feeds
            .map { DataSourceItem.subscribedPodcastFeed($0.objectID) }
        
        let latestEpisodeItems = feeds
            .compactMap(\.episodes?.first)
            .map { DataSourceItem.latestPodcastEpisode($0.objectID) }
        

        let shouldAnimate = collectionView?.numberOfSections != 0
        
        currentSnapshot.appendSections([.subscribedPodcastFeeds])
        currentSnapshot.appendItems(feedItems, toSection: .subscribedPodcastFeeds)
        
        currentSnapshot.appendSections([.latestPodcastEpisodes])
        currentSnapshot.appendItems(latestEpisodeItems, toSection: .latestPodcastEpisodes)

        dataSource.apply(currentSnapshot, animatingDifferences: shouldAnimate)
    }
}


extension PodcastEpisode: DashboardPodcastCollectionViewItem {
    var imageName: String? {
        imageURLPath ?? "podcastTagIcon"
    }
    
    var subtitle: String? {
        episodeDescription ?? ""
    }
}


extension PodcastFeed: DashboardPodcastCollectionViewItem {
    var imageName: String? {
        imageURLPath ?? "podcastTagIcon"
    }
    
    var subtitle: String? {
        podcastDescription ?? ""
    }
}
