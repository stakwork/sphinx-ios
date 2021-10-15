// VideoFeedCollectionViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit
import CoreData


class VideoFeedCollectionViewController: UICollectionViewController {
    var videoFeeds: [VideoFeed]!
    var videoEpisodes: [Video]!
    
    var interSectionSpacing: CGFloat = 0.0

    var onVideoEpisodeCellSelected: ((NSManagedObjectID) -> Void)!
    var onVideoFeedCellSelected: ((NSManagedObjectID) -> Void)!
    var onNewResultsFetched: ((Int) -> Void)!

    private var managedObjectContext: NSManagedObjectContext!
    private var fetchedResultsController: NSFetchedResultsController<VideoFeed>!
    private var currentDataSnapshot: DataSourceSnapshot!
    private var dataSource: DataSource!

    private let itemContentInsets = NSDirectionalEdgeInsets(
        top: 0,
        leading: 0,
        bottom: 0,
        trailing: 0
    )
}


// MARK: - Instantiation
extension VideoFeedCollectionViewController {

    static func instantiate(
        managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext,
        videoFeeds: [VideoFeed] = [],
        videoEpisodes: [Video] = [],
        interSectionSpacing: CGFloat = 0.0,
        onVideoEpisodeCellSelected: ((NSManagedObjectID) -> Void)!,
        onVideoFeedCellSelected: ((NSManagedObjectID) -> Void)!,
        onNewResultsFetched: @escaping ((Int) -> Void) = { _ in }
    ) -> VideoFeedCollectionViewController {
        let viewController = StoryboardScene
            .Dashboard
            .videoFeedCollectionViewController
            .instantiate()

        viewController.managedObjectContext = managedObjectContext

        viewController.videoFeeds = videoFeeds
        viewController.videoEpisodes = videoEpisodes
        viewController.interSectionSpacing = interSectionSpacing
        viewController.onVideoEpisodeCellSelected = onVideoEpisodeCellSelected
        viewController.onVideoFeedCellSelected = onVideoFeedCellSelected
        viewController.onNewResultsFetched = onNewResultsFetched
        
        viewController.fetchedResultsController = Self.makeFetchedResultsController(using: managedObjectContext)
        viewController.fetchedResultsController.delegate = viewController
        
        return viewController
    }
}


// MARK: - Layout & Data Structure
extension VideoFeedCollectionViewController {
    
    enum CollectionViewSection: Int, CaseIterable {
        case videoEpisodes
        case videoFeeds
        
        var titleForDisplay: String {
            switch self {
            case .videoEpisodes:
                return "Watch Now"
            case .videoFeeds:
                return "Following"
            }
        }
    }
    
    
    enum DataSourceItem: Hashable {
        case videoEpisode(Video)
        case videoFeed(VideoFeed)
    }

    
    typealias ReusableHeaderView = DashboardFeedCollectionViewSectionHeader
    typealias CellDataItem = DataSourceItem
    typealias DataSource = UICollectionViewDiffableDataSource<CollectionViewSection, CellDataItem>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, CellDataItem>
}


// MARK: - Lifecycle
extension VideoFeedCollectionViewController {

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
extension VideoFeedCollectionViewController {

    func makeSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(48)
        )

        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }


    func makeVideoFeedSectionLayout() -> NSCollectionLayoutSection {
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
        section.contentInsets = .init(top: 0, leading: 24, bottom: 0, trailing: 24)

        return section
    }


    func makeSectionProvider() -> UICollectionViewCompositionalLayoutSectionProvider {
        { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            // 📝 TODO:  Switch on the type of section
            self.makeVideoFeedSectionLayout()
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
extension VideoFeedCollectionViewController {

    func registerViews(for collectionView: UICollectionView) {
        collectionView.register(
            DashboardVideoFeedCollectionViewCell.nib,
            forCellWithReuseIdentifier: DashboardVideoFeedCollectionViewCell.reuseID
        )
        
        collectionView.register(
            DashboardVideoEpisodeCollectionViewCell.nib,
            forCellWithReuseIdentifier: DashboardVideoEpisodeCollectionViewCell.reuseID
        )

        collectionView.register(
            ReusableHeaderView.nib,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ReusableHeaderView.reuseID
        )
    }


    func configure(_ collectionView: UICollectionView) {
        collectionView.collectionViewLayout = makeLayout()
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .Sphinx.ListBG
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
    }
}


// MARK: - Data Source Configuration
extension VideoFeedCollectionViewController {

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
}


// MARK: - Data Source View Providers
extension VideoFeedCollectionViewController {

    func makeCellProvider(for collectionView: UICollectionView) -> DataSource.CellProvider {
        { (collectionView, indexPath, dataSourceItem) -> UICollectionViewCell in
            guard
                let section = CollectionViewSection(rawValue: indexPath.section)
            else {
                preconditionFailure("Unexpected Section index path")
            }
            
            switch section {
            case .videoEpisodes:
                guard
                    let episodeCell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: DashboardVideoEpisodeCollectionViewCell.reuseID,
                        for: indexPath
                    ) as? DashboardVideoEpisodeCollectionViewCell,
                    case .videoEpisode(let videoEpisode) = dataSourceItem
                else {
                    preconditionFailure("Failed to dequeue expected reusable cell type")
                }
                
                episodeCell.configure(withVideoEpisode: videoEpisode)
                
                return episodeCell
            case .videoFeeds:
                guard
                    let feedCell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: DashboardVideoFeedCollectionViewCell.reuseID,
                        for: indexPath
                    ) as? DashboardVideoFeedCollectionViewCell,
                    case .videoFeed(let videoFeed) = dataSourceItem
                else {
                    preconditionFailure("Failed to dequeue expected reusable cell type")
                }
                
                feedCell.configure(withVideoFeed: videoFeed)
                
                return feedCell
            }
        }
    }


    func makeSupplementaryViewProvider(for collectionView: UICollectionView) -> DataSource.SupplementaryViewProvider {
        return {
            (collectionView: UICollectionView, kind: String, indexPath: IndexPath)
        -> UICollectionReusableView? in
            switch kind {
            case UICollectionView.elementKindSectionHeader:
                guard let headerView = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: ReusableHeaderView.reuseID,
                    for: indexPath
                ) as? ReusableHeaderView else {
                    preconditionFailure()
                }

                let section = CollectionViewSection.allCases[indexPath.section]

                headerView.render(withTitle: section.titleForDisplay)

                return headerView
            default:
                return UICollectionReusableView()
            }
        }
    }
}


// MARK: - Data Source Snapshot
extension VideoFeedCollectionViewController {

    func makeSnapshotForCurrentState() -> DataSourceSnapshot {
        var snapshot = DataSourceSnapshot()

        snapshot.appendSections(CollectionViewSection.allCases)
        
        snapshot.appendItems(
            videoFeeds.map { DataSourceItem.videoFeed($0) },
            toSection: .videoFeeds
        )
        
        snapshot.appendItems(
            videoEpisodes.map { DataSourceItem.videoEpisode($0) },
            toSection: .videoEpisodes
        )

        return snapshot
    }


    func updateSnapshot(shouldAnimate: Bool = true) {
        let snapshot = makeSnapshotForCurrentState()

        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }
    
    
    func updateWithNew(
        videoFeeds: [VideoFeed],
        shouldAnimate: Bool = true
    ) {
        self.videoFeeds = videoFeeds

        if let dataSource = dataSource {
            dataSource.apply(
                makeSnapshotForCurrentState(),
                animatingDifferences: shouldAnimate
            )
        }
    }
    
    
    func updateWithNew(
        videoEpisodes: [Video],
        shouldAnimate: Bool = true
    ) {
        self.videoEpisodes = videoEpisodes

        if let dataSource = dataSource {
            dataSource.apply(
                makeSnapshotForCurrentState(),
                animatingDifferences: shouldAnimate
            )
        }
    }
}


// MARK: -  Fetched Result Controller
extension VideoFeedCollectionViewController {
    
    static func makeFetchedResultsController(
        using managedObjectContext: NSManagedObjectContext
    ) -> NSFetchedResultsController<VideoFeed> {
        let fetchRequest = VideoFeed.FetchRequests.followedFeeds()
        
        return NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
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


// MARK: - `UICollectionViewDelegate` Methods
extension VideoFeedCollectionViewController {

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard
            let section = CollectionViewSection(rawValue: indexPath.section),
            let dataSourceItem = dataSource.itemIdentifier(for: indexPath)
        else {
            return
        }

        switch section {
        case .videoFeeds:
            guard
                case let .videoFeed(videoFeed) = dataSourceItem
            else {
                preconditionFailure()
            }
            
            onVideoFeedCellSelected?(videoFeed.objectID)
        case .videoEpisodes:
            guard
                case let .videoEpisode(videoEpisode) = dataSourceItem
            else {
                preconditionFailure()
            }
            
            onVideoEpisodeCellSelected?(videoEpisode.objectID)
        }
    }
}




//extension VideoFeedCollectionViewController.DataSourceItem {
//
//    var searchResult: VideoFeedSearchResult {
//        switch self {
//        case .subscribedFeedsResult(let videoFeed):
//            return videoFeed.searchResultItem
//        case .podcastIndexSearchResult(let result):
//            return result
//        }
//    }
//
//    var videoFeedObject: VideoFeed? {
//        switch self {
//        case .subscribedFeedsResult(let videoFeed):
//            return videoFeed
//        case .podcastIndexSearchResult:
//            return nil
//        }
//    }
//}

//
//extension VideoFeedCollectionViewController {
//
//    private func subscriptionState(
//        for dataSourceItem: DataSourceItem,
//        in section: CollectionViewSection
//    ) -> VideoFeedSearchResultCollectionViewCell.SubscriptionState {
//        switch section {
//        case .subscribedFeedsResults:
//            return .followedViaTribe
//        case .podcastIndexSearchResults:
//            if dataSource
//                .snapshot()
//                .itemIdentifiers(inSection: .subscribedFeedsResults)
//                .contains(
//                    where: { videoFeedDataSourceItem in
//                        videoFeedDataSourceItem.searchResult == dataSourceItem.searchResult
//                    }
//                )
//            {
//                return .subscribedFromPodcastIndex
//            } else {
//                return .subscriptionAvailableFromPodcastIndex
//            }
//        }
//    }
//
//
//    private func handleSubscriptionButtonTap(
//        searchResult: VideoFeedSearchResult,
//        subscriptionState: VideoFeedSearchResultCollectionViewCell.SubscriptionState
//    ) {
//        switch subscriptionState {
//        case .followedViaTribe:
//            break
//        case .subscribedFromPodcastIndex:
//            onPodcastSubscriptionCancellationSelected(searchResult)
//        case .subscriptionAvailableFromPodcastIndex:
//            onPodcastSubscriptionSelected(searchResult)
//        }
//    }
//}
//


extension VideoFeedCollectionViewController: NSFetchedResultsControllerDelegate {
    
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
            let foundFeeds = firstSection.objects as? [VideoFeed]
        else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.updateWithNew(
                videoFeeds: foundFeeds
            )
            
            self?.onNewResultsFetched(foundFeeds.count)
        }
    }
}
