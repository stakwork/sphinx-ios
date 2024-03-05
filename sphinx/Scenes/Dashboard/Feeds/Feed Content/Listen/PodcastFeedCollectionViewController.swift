import UIKit
import CoreData


class PodcastFeedCollectionViewController: UICollectionViewController {
    
    var allPodcastFeeds: [PodcastFeed] = []
    var followedPodcastFeeds: [PodcastFeed] = []
    
    var interSectionSpacing: CGFloat!

    var onPodcastEpisodeCellSelected: ((String) -> Void)!
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
        managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext,
        interSectionSpacing: CGFloat = 10.0,
        onPodcastEpisodeCellSelected: @escaping ((String) -> Void) = { _ in },
        onSubscribedPodcastFeedCellSelected: @escaping ((PodcastFeed) -> Void) = { _ in },
        onNewResultsFetched: @escaping ((Int) -> Void) = { _ in },
        onContentScrolled: ((UIScrollView) -> Void)? = nil
    ) -> PodcastFeedCollectionViewController {
        let viewController = StoryboardScene.Dashboard.podcastFeedCollectionViewController.instantiate()

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
        case recentlyReleasePods

        /// Podcasts that the user is subscribed to
        case recentlyPlayedPods


        var titleForDisplay: String {
            switch self {
            case .recentlyReleasePods:
                return "feed.recently-released".localized
            case .recentlyPlayedPods:
                return "recently.played".localized
            }
        }
    }


    enum DataSourceItem: Hashable, Equatable {
        case listenNowEpisode(PodcastEpisode, Int)
        case subscribedPodcastFeed(PodcastFeed)
        
        static func == (lhs: DataSourceItem, rhs: DataSourceItem) -> Bool {
            if let lhsContentFeed = lhs.feedEntity,
               let rhsContentFeed = rhs.feedEntity {
                    
                return
                    lhsContentFeed.feedID == rhsContentFeed.feedID &&
                    lhsContentFeed.title == rhsContentFeed.title &&
                    lhsContentFeed.feedURLPath == rhsContentFeed.feedURLPath &&
                    lhsContentFeed.dateLastConsumed == rhsContentFeed.dateLastConsumed &&
                    lhsContentFeed.episodesArray.count == rhsContentFeed.episodesArray.count &&
                    lhsContentFeed.getLastEpisode()?.id == rhsContentFeed.getLastEpisode()?.id &&
                    lhsContentFeed.getLastEpisode()?.datePublished == rhsContentFeed.getLastEpisode()?.datePublished
            }
            
            if let lhsEpisode = lhs.episodeEntity,
               let rhsEpisode = rhs.episodeEntity {
                    
                return
                    lhsEpisode.0.itemID == rhsEpisode.0.itemID &&
                    lhsEpisode.0.title == rhsEpisode.0.title &&
                    lhsEpisode.1 == rhsEpisode.1
            }

            return false
         }

        func hash(into hasher: inout Hasher) {
            if let contentFeed = self.feedEntity {
                hasher.combine(contentFeed.feedID)
            }
            
            if let episode = self.episodeEntity {
                hasher.combine(episode.0.itemID)
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
        
        fetchItems()
    }
    
    func addTableBottomInset(for collectionView: UICollectionView) {
        let windowInsets = getWindowInsets()
        let bottomBarHeight:CGFloat = 64
        
        collectionView.contentInset.bottom = bottomBarHeight + windowInsets.bottom
        collectionView.verticalScrollIndicatorInsets.bottom = bottomBarHeight + windowInsets.bottom
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .refreshFeedUI, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(forceItemsRefresh), name: .refreshFeedUI, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .refreshFeedUI, object: nil)
    }
    
    @objc func forceItemsRefresh(){
        DispatchQueue.main.async { [weak self] in
            if let feeds = self?.allPodcastFeeds {
                self?.updateWithNew(
                    podcastFeeds: feeds
                )
                
                self?.onNewResultsFetched(feeds.count)
            }
        }
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


    func makeFeedContentSectionLayout(
        itemHeight: CGFloat
    ) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = itemContentInsets

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(160.0),
            heightDimension: .absolute(itemHeight)
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
            guard
                let section = CollectionViewSection(rawValue: sectionIndex)
            else {
                preconditionFailure("Unexpected Section index path")
            }
            
            switch section {
            case .recentlyReleasePods:
                return self.makeFeedContentSectionLayout(itemHeight: 285.0)
            case .recentlyPlayedPods:
                return self.makeFeedContentSectionLayout(itemHeight: 255.0)
            }
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
        
        snapshot.appendSections([CollectionViewSection.recentlyReleasePods])

        snapshot.appendItems(
            self.followedPodcastFeeds
                .compactMap { $0.episodesArray.first }
                .map { episode in
                    DataSourceItem.listenNowEpisode(episode, episode.currentTime ?? 0)
                },
            toSection: .recentlyReleasePods
       )
        
        let recentlyPlayedFeed = allPodcastFeeds.filter { $0.dateLastConsumed != nil }.compactMap { contentFeed -> DataSourceItem? in
            return DataSourceItem.subscribedPodcastFeed(contentFeed)
        }
        
        if !recentlyPlayedFeed.isEmpty {
            snapshot.appendSections([CollectionViewSection.recentlyPlayedPods])
            
            snapshot.appendItems(
                recentlyPlayedFeed,
                toSection: .recentlyPlayedPods
            )
        }

        return snapshot
    }


    func updateWithNew(
        podcastFeeds: [PodcastFeed],
        shouldAnimate: Bool = true
    ) {
        for feed in podcastFeeds {
            let _ = feed.episodesArray
        }
        
        self.followedPodcastFeeds = podcastFeeds.filter { $0.isSubscribedToFromSearch || $0.chat != nil }.sorted { (first, second) in
            let firstDate = first.getLastEpisode()?.datePublished ?? Date.init(timeIntervalSince1970: 0)
            let secondDate = second.getLastEpisode()?.datePublished ?? Date.init(timeIntervalSince1970: 0)
            
            return firstDate > secondDate
        }
        
        self.allPodcastFeeds = podcastFeeds.sorted { (first, second) in
            let firstDate = first.dateLastConsumed ?? Date.init(timeIntervalSince1970: 0)
            let secondDate = second.dateLastConsumed ?? Date.init(timeIntervalSince1970: 0)
            
            if (firstDate == secondDate) {
                let firstDate = first.episodesArray.first?.datePublished ?? Date.init(timeIntervalSince1970: 0)
                let secondDate = second.episodesArray.first?.datePublished ?? Date.init(timeIntervalSince1970: 0)

                return firstDate > secondDate
            }

            return firstDate > secondDate
        }

        let snapshot = makeSnapshotForCurrentState()
        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
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
        { [weak self] (collectionView, indexPath, dataSourceItem) -> UICollectionViewCell? in
            guard let self else {
                return nil
            }
            
            guard
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CollectionViewCell.reuseID,
                    for: indexPath
                ) as? CollectionViewCell
            else {
                preconditionFailure("Failed to dequeue cell")
            }

            switch dataSourceItem {
            case .listenNowEpisode(let podcastEpisode, _):
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
        let fetchRequest = PodcastFeed.FetchRequests.allFeeds()

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
        case .listenNowEpisode(let podcastEpisode, _):
            onPodcastEpisodeCellSelected(podcastEpisode.itemID)
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
                podcastFeeds: podcastFeeds
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
    
    var episodeEntity: (PodcastEpisode, Int)? {
        switch self {
        case .listenNowEpisode(let podcastEpisode, let currentTime):
            return (podcastEpisode, currentTime)
        default:
            return nil
        }
    }
}
