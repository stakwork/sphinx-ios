// DashboardVideoFeedCollectionViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit
import CoreData

class DashboardVideoFeedCollectionViewController: UICollectionViewController {
    
    var allVideoFeeds: [VideoFeed] = []
    var followedVideoFeeds: [VideoFeed] = []
    
    var interSectionSpacing: CGFloat = 20.0

    var onVideoEpisodeCellSelected: ((String) -> Void)!
    var onVideoFeedCellSelected: ((String) -> Void)!
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
extension DashboardVideoFeedCollectionViewController {

    static func instantiate(
        managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext,
        interSectionSpacing: CGFloat = 20.0,
        onVideoEpisodeCellSelected: ((String) -> Void)!,
        onVideoFeedCellSelected: ((String) -> Void)!,
        onNewResultsFetched: @escaping ((Int) -> Void) = { _ in },
        onContentScrolled: ((UIScrollView) -> Void)? = nil
    ) -> DashboardVideoFeedCollectionViewController {
        let viewController = StoryboardScene
            .Dashboard
            .videoFeedCollectionViewController
            .instantiate()

        viewController.managedObjectContext = managedObjectContext
        viewController.interSectionSpacing = interSectionSpacing
        viewController.onVideoEpisodeCellSelected = onVideoEpisodeCellSelected
        viewController.onVideoFeedCellSelected = onVideoFeedCellSelected
        viewController.onNewResultsFetched = onNewResultsFetched
        viewController.onContentScrolled = onContentScrolled
        
        viewController.fetchedResultsController = Self.makeFetchedResultsController(using: managedObjectContext)
        viewController.fetchedResultsController.delegate = viewController
        
        return viewController
    }
}


// MARK: - Layout & Data Structure
extension DashboardVideoFeedCollectionViewController {
    
    enum CollectionViewSection: Int, CaseIterable {
        case recentlyReleaseVideos
        case recentlyPlayedVideos
        
        var titleForDisplay: String {
            switch self {
            case .recentlyReleaseVideos:
                return "feed.recently-released".localized
            case .recentlyPlayedVideos:
                return "recently.played".localized
            }
        }
    }
    
    
    enum DataSourceItem: Hashable {
        case videoEpisode(Video)
        case videoFeed(VideoFeed)
        
        static func == (lhs: DataSourceItem, rhs: DataSourceItem) -> Bool {
            if let lhsContentFeed = lhs.feedEntity,
               let rhsContentFeed = rhs.feedEntity {
                    
                return
                    lhsContentFeed.feedID == rhsContentFeed.feedID &&
                    lhsContentFeed.title == rhsContentFeed.title &&
                    lhsContentFeed.feedURL?.absoluteString == rhsContentFeed.feedURL?.absoluteString &&
                    lhsContentFeed.dateLastConsumed == rhsContentFeed.dateLastConsumed &&
                    lhsContentFeed.videosArray.count == rhsContentFeed.videosArray.count &&
                    lhsContentFeed.videosArray.first?.id == rhsContentFeed.videosArray.first?.id &&
                    lhsContentFeed.videosArray.first?.datePublished == rhsContentFeed.videosArray.first?.datePublished
            }
            
            if let lhsEpisode = lhs.episodeEntity,
               let rhsEpisode = rhs.episodeEntity {
                    
                return
                    lhsEpisode.videoID == rhsEpisode.videoID &&
                    lhsEpisode.title == rhsEpisode.title
            }

            return false
         }

        func hash(into hasher: inout Hasher) {
            if let contentFeed = self.feedEntity {
                hasher.combine(contentFeed.feedID)
            }
            
            if let episode = self.episodeEntity {
                hasher.combine(episode.videoID)
            }
        }
    }

    
    typealias ReusableHeaderView = DashboardFeedCollectionViewSectionHeader
    typealias CellDataItem = DataSourceItem
    typealias DataSource = UICollectionViewDiffableDataSource<CollectionViewSection, CellDataItem>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, CellDataItem>
}


// MARK: - Lifecycle
extension DashboardVideoFeedCollectionViewController {

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
}


// MARK: - Layout Composition
extension DashboardVideoFeedCollectionViewController {

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
            heightDimension: .absolute(255.0)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        
        let section = NSCollectionLayoutSection(group: group)

        section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
        section.boundarySupplementaryItems = [makeSectionHeader()]
        section.contentInsets = .init(top: 11, leading: 0, bottom: 11, trailing: 12)

        return section
    }
    
    
    func makeVideoEpisodeSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = itemContentInsets


        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.9),
            heightDimension: .estimated(241.0)
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
            switch CollectionViewSection(rawValue: sectionIndex)! {
            case .recentlyReleaseVideos:
                return self.makeVideoEpisodeSectionLayout()
            case .recentlyPlayedVideos:
                return self.makeVideoFeedSectionLayout()
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
extension DashboardVideoFeedCollectionViewController {

    func registerViews(for collectionView: UICollectionView) {
        collectionView.register(
            DashboardFeedSquaredThumbnailCollectionViewCell.nib,
            forCellWithReuseIdentifier: DashboardFeedSquaredThumbnailCollectionViewCell.reuseID
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
        collectionView.contentInset = .init(
            top: interSectionSpacing,
            left: 0,
            bottom: 0,
            right: 0
        )
        
        collectionView.collectionViewLayout = makeLayout()
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .Sphinx.ListBG
        collectionView.showsVerticalScrollIndicator = false
        
        collectionView.delegate = self
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onContentScrolled?(scrollView)
    }
}


// MARK: - Data Source Configuration
extension DashboardVideoFeedCollectionViewController {

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
extension DashboardVideoFeedCollectionViewController {

    func makeCellProvider(for collectionView: UICollectionView) -> DataSource.CellProvider {
        { [weak self] (collectionView, indexPath, dataSourceItem) -> UICollectionViewCell? in
            guard let self else {
                return nil
            }
            
            guard
                let section = CollectionViewSection(rawValue: indexPath.section)
            else {
                preconditionFailure("Unexpected Section index path")
            }
            
            switch section {
            case .recentlyReleaseVideos:
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
            case .recentlyPlayedVideos:
                guard
                    let feedCell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: DashboardFeedSquaredThumbnailCollectionViewCell.reuseID,
                        for: indexPath
                    ) as? DashboardFeedSquaredThumbnailCollectionViewCell,
                    case .videoFeed(let videoFeed) = dataSourceItem
                else {
                    preconditionFailure("Failed to dequeue expected reusable cell type")
                }
                
                feedCell.configure(withItem: videoFeed)
                
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
extension DashboardVideoFeedCollectionViewController {

    func makeSnapshotForCurrentState() -> DataSourceSnapshot {
        var snapshot = DataSourceSnapshot()
        
        if (allVideoFeeds.isEmpty) {
            return snapshot
        }

        snapshot.appendSections([CollectionViewSection.recentlyReleaseVideos])
        
        snapshot.appendItems(
            followedVideoFeeds
                .compactMap { $0.videosArray.first }
                .map { DataSourceItem.videoEpisode( $0 ) },
            toSection: .recentlyReleaseVideos
        )
        
        let recentlyPlayedFeed = allVideoFeeds.filter { $0.dateLastConsumed != nil }.compactMap { contentFeed -> DataSourceItem? in
            return DataSourceItem.videoFeed(contentFeed)
        }
        
        if !recentlyPlayedFeed.isEmpty {
            snapshot.appendSections([CollectionViewSection.recentlyPlayedVideos])
            
            snapshot.appendItems(
                recentlyPlayedFeed,
                toSection: .recentlyPlayedVideos
            )
        }

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
        for feed in videoFeeds {
            let _ = feed.videosArray
        }
        
        self.followedVideoFeeds = videoFeeds.filter { $0.isSubscribedToFromSearch || $0.chat != nil }.sorted { (first, second) in
            let firstDate = first.videosArray.first?.datePublished ?? Date.init(timeIntervalSince1970: 0)
            let secondDate = second.videosArray.first?.datePublished ?? Date.init(timeIntervalSince1970: 0)
            
            return firstDate > secondDate
        }
        
        self.allVideoFeeds = videoFeeds.sorted { (first, second) in
            let firstDate = first.dateLastConsumed ?? Date.init(timeIntervalSince1970: 0)
            let secondDate = second.dateLastConsumed ?? Date.init(timeIntervalSince1970: 0)
            
            if (firstDate == secondDate) {
                let firstDate = first.videosArray.first?.datePublished ?? Date.init(timeIntervalSince1970: 0)
                let secondDate = second.videosArray.first?.datePublished ?? Date.init(timeIntervalSince1970: 0)

                return firstDate > secondDate
            }

            return firstDate > secondDate
        }
        
        if let dataSource = dataSource {
            dataSource.apply(
                makeSnapshotForCurrentState(),
                animatingDifferences: shouldAnimate
            )
        }
    }
}


// MARK: -  Fetched Result Controller
extension DashboardVideoFeedCollectionViewController {
    
    static func makeFetchedResultsController(
        using managedObjectContext: NSManagedObjectContext
    ) -> NSFetchedResultsController<ContentFeed> {
        let fetchRequest = VideoFeed.FetchRequests.allFeeds()
        
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
extension DashboardVideoFeedCollectionViewController {

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
        case .recentlyReleaseVideos:
            guard
                case let .videoEpisode(videoEpisode) = dataSourceItem
            else {
                preconditionFailure()
            }
            
            onVideoEpisodeCellSelected?(videoEpisode.id)
        case .recentlyPlayedVideos:
            guard
                case let .videoFeed(videoFeed) = dataSourceItem
            else {
                preconditionFailure()
            }
            
            onVideoFeedCellSelected?(videoFeed.id)
    }
    }
}


extension DashboardVideoFeedCollectionViewController: NSFetchedResultsControllerDelegate {
    
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

        let videoFeeds = foundFeeds.map {
            VideoFeed.convertFrom(contentFeed: $0)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.updateWithNew(
                videoFeeds: videoFeeds
            )
            
            self?.onNewResultsFetched(videoFeeds.count)
        }
    }
}

extension DashboardVideoFeedCollectionViewController.DataSourceItem {
    
    var feedEntity: VideoFeed? {
        switch self {
        case .videoFeed(let videoFeed):
            return videoFeed
        default:
            return nil
        }
    }
    
    var episodeEntity: Video? {
        switch self {
        case .videoEpisode(let videoEpisode):
            return videoEpisode
        default:
            return nil
        }
    }
}
