import UIKit
import CoreData


class PodcastFeedCollectionViewController: UICollectionViewController {
    var followedPodcastFeeds: [PodcastFeed]!
    var interSectionSpacing: CGFloat!

    var onPodcastEpisodeCellSelected: ((NSManagedObjectID) -> Void)!
    var onSubscribedPodcastFeedCellSelected: ((PodcastFeed) -> Void)!
    var onNewResultsFetched: ((Int) -> Void)!
    var onContentScrolled: ((UIScrollView) -> Void)?

    private var managedObjectContext: NSManagedObjectContext!
    private var fetchedResultsController: NSFetchedResultsController<ContentFeed>!
    private var currentDataSnapshot: DataSourceSnapshot!
    private var dataSource: DataSource!

    private let itemContentInsets = NSDirectionalEdgeInsets(
        top: 0,
        leading: 12,
        bottom: 0,
        trailing: 0
    )
}


// MARK: - Instantiation
extension PodcastFeedCollectionViewController {

    static func instantiate(
        followedPodcastFeeds: [PodcastFeed] = [],
        managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext,
        interSectionSpacing: CGFloat = 10.0,
        onPodcastEpisodeCellSelected: @escaping ((NSManagedObjectID) -> Void) = { _ in },
        onSubscribedPodcastFeedCellSelected: @escaping ((PodcastFeed) -> Void) = { _ in },
        onNewResultsFetched: @escaping ((Int) -> Void) = { _ in },
        onContentScrolled: ((UIScrollView) -> Void)? = nil
    ) -> PodcastFeedCollectionViewController {
        let viewController = StoryboardScene.Dashboard.podcastFeedCollectionViewController.instantiate()

        viewController.followedPodcastFeeds = followedPodcastFeeds

        viewController.managedObjectContext = managedObjectContext
        viewController.interSectionSpacing = interSectionSpacing

        viewController.onPodcastEpisodeCellSelected = onPodcastEpisodeCellSelected
        viewController.onSubscribedPodcastFeedCellSelected = onSubscribedPodcastFeedCellSelected
        viewController.onNewResultsFetched = onNewResultsFetched
        viewController.onContentScrolled = onContentScrolled

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
                return "feed.listen-now".localized
            case .subscribedPodcastFeeds:
                return "feed.following".localized
            }
        }
    }


    enum DataSourceItem: Hashable {
        case listenNowEpisode(PodcastEpisode)
        case subscribedPodcastFeed(PodcastFeed)
        
        static func == (lhs: DataSourceItem, rhs: DataSourceItem) -> Bool {
            if let lhsContentFeed = lhs.feedEntity,
               let rhsContentFeed = rhs.feedEntity {
                    
                return
                    lhsContentFeed.feedID == rhsContentFeed.feedID &&
                    lhsContentFeed.title == rhsContentFeed.title &&
                    lhsContentFeed.feedURLPath == rhsContentFeed.feedURLPath &&
                    lhsContentFeed.episodesArray.count == rhsContentFeed.episodesArray.count
            }
            
            if let lhsEpisode = lhs.episodeEntity,
               let rhsEpisode = rhs.episodeEntity {
                    
                return
                    lhsEpisode.itemID == rhsEpisode.itemID &&
                    lhsEpisode.title == rhsEpisode.title
            }

            return false
         }

        func hash(into hasher: inout Hasher) {
            if let contentFeed = self.feedEntity {
                hasher.combine(contentFeed.feedID)
                hasher.combine(contentFeed.title)
                hasher.combine(contentFeed.feedURLPath)
                hasher.combine(contentFeed.episodesArray.count)
            }
            
            if let episode = self.episodeEntity {
                hasher.combine(episode.itemID)
                hasher.combine(episode.title)
            }
        }
    }


    typealias ReusableHeaderView = DashboardFeedCollectionViewSectionHeader
    typealias CollectionViewCell = DashboardFeedSquaredThumbnailCollectionViewCell
    typealias CellDataItem = DataSourceItem
    typealias DataSource = UICollectionViewDiffableDataSource<CollectionViewSection, CellDataItem>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, CellDataItem>
}



// MARK: - Lifecycle
extension PodcastFeedCollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        registerViews(for: collectionView)
        configure(collectionView)
        configureDataSource(for: collectionView)
        addTableBottomInset(for: collectionView)
    }
    
    func addTableBottomInset(for collectionView: UICollectionView) {
        let windowInsets = getWindowInsets()
        let bottomBarHeight:CGFloat = 64
        
        collectionView.contentInset.bottom = bottomBarHeight + windowInsets.bottom
        collectionView.verticalScrollIndicatorInsets.bottom = bottomBarHeight + windowInsets.bottom
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


    func makeFeedContentSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = itemContentInsets


        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(160.0),
            heightDimension: .absolute(255.0)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])


        let section = NSCollectionLayoutSection(group: group)

        section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
        section.boundarySupplementaryItems = [makeSectionHeader()]
        section.contentInsets = .init(top: 11, leading: 0, bottom: 11, trailing: 12)

        return section
    }


    func makeSectionProvider() -> UICollectionViewCompositionalLayoutSectionProvider {
        { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            self.makeFeedContentSectionLayout()
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
            DashboardFeedSquaredThumbnailCollectionViewCell.nib,
            forCellWithReuseIdentifier: DashboardFeedSquaredThumbnailCollectionViewCell.reuseID
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
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onContentScrolled?(scrollView)
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

        let snapshot = makeSnapshotForCurrentState()

        dataSource.apply(snapshot, animatingDifferences: false)
    }


    func makeSnapshotForCurrentState() -> DataSourceSnapshot {
        var snapshot = DataSourceSnapshot()

        if (followedPodcastFeeds.isEmpty) {
            return snapshot
        }
        
        snapshot.appendSections(CollectionViewSection.allCases)

        snapshot.appendItems(
            followedPodcastFeeds.sorted { (first, second) in
                let firstDate = first.dateUpdated ?? first.datePublished ?? Date.init(timeIntervalSince1970: 0)
                let secondDate = second.dateUpdated ?? second.datePublished ?? Date.init(timeIntervalSince1970: 0)
                
                return firstDate > secondDate
            }.map {
                DataSourceItem.subscribedPodcastFeed($0)
                
            },
            toSection: .subscribedPodcastFeeds
        )

        snapshot.appendItems(
            followedPodcastFeeds.sorted { (first, second) in
                let firstDate = first.dateUpdated ?? first.datePublished ?? Date.init(timeIntervalSince1970: 0)
                let secondDate = second.dateUpdated ?? second.datePublished ?? Date.init(timeIntervalSince1970: 0)
                
                return firstDate > secondDate
            }.compactMap { feed in
                feed.getCurrentEpisode()
                ?? feed.episodesArray.last
            }
            .map { episode in
                DataSourceItem.listenNowEpisode(episode)
            },
            toSection: .latestPodcastEpisodes
        )

        return snapshot
    }


    func updateSnapshot(shouldAnimate: Bool = true) {
        let snapshot = makeSnapshotForCurrentState()

        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }


    func updateWithNew(
        followedPodcastFeeds: [PodcastFeed],
        shouldAnimate: Bool = true
    ) {
        self.followedPodcastFeeds = followedPodcastFeeds

        if let dataSource = dataSource {
            dataSource.apply(
                makeSnapshotForCurrentState(),
                animatingDifferences: shouldAnimate
            )
        }
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
        { (collectionView, indexPath, dataSourceItem) -> UICollectionViewCell in
            guard
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CollectionViewCell.reuseID,
                    for: indexPath
                ) as? CollectionViewCell
            else {
                preconditionFailure("Failed to dequeue cell")
            }

            switch dataSourceItem {
            case .listenNowEpisode(let podcastEpisode):
                cell.configure(withItem: podcastEpisode)
            case .subscribedPodcastFeed(let podcastFeed):
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
    ) -> NSFetchedResultsController<ContentFeed> {
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
            let dataSourceItem = dataSource.itemIdentifier(for: indexPath)
        else {
            return
        }

        switch dataSourceItem {
        case .listenNowEpisode(let podcastEpisode):
            if let objectID = podcastEpisode.objectID {
                onPodcastEpisodeCellSelected(objectID)
            }
        case .subscribedPodcastFeed(let podcastFeed):
            onSubscribedPodcastFeedCellSelected(podcastFeed)
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
        guard
            let resultController = controller as? NSFetchedResultsController<NSManagedObject>,
            let firstSection = resultController.sections?.first,
            let foundFeeds = firstSection.objects as? [ContentFeed]
        else {
            return
        }
        
        let podcastFeeds = foundFeeds.map {
            PodcastFeed.convertFrom(contentFeed: $0)
        }

        DispatchQueue.main.async { [weak self] in
            self?.updateWithNew(
                followedPodcastFeeds: podcastFeeds
            )
            
            self?.onNewResultsFetched(podcastFeeds.count)
        }
    }
}

extension PodcastFeedCollectionViewController.DataSourceItem {
    
    var feedEntity: PodcastFeed? {
        switch self {
        case .subscribedPodcastFeed(let podcastFeed):
            return podcastFeed
        default:
            return nil
        }
    }
    
    var episodeEntity: PodcastEpisode? {
        switch self {
        case .listenNowEpisode(let podcastEpisode):
            return podcastEpisode
        default:
            return nil
        }
    }
}
