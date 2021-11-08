// DashboardVideoFeedCollectionViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit
import CoreData


class DashboardVideoFeedCollectionViewController: UICollectionViewController {
    var videoFeeds: [VideoFeed]!
    var videoEpisodes: [Video]!
    
    var interSectionSpacing: CGFloat = 20.0

    var onVideoEpisodeCellSelected: ((NSManagedObjectID) -> Void)!
    var onVideoFeedCellSelected: ((NSManagedObjectID) -> Void)!
    var onNewResultsFetched: ((Int) -> Void)!

    private var managedObjectContext: NSManagedObjectContext!
    private var fetchedResultsController: NSFetchedResultsController<VideoFeed>!
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
        videoFeeds: [VideoFeed] = [],
        videoEpisodes: [Video] = [],
        interSectionSpacing: CGFloat = 20.0,
        onVideoEpisodeCellSelected: ((NSManagedObjectID) -> Void)!,
        onVideoFeedCellSelected: ((NSManagedObjectID) -> Void)!,
        onNewResultsFetched: @escaping ((Int) -> Void) = { _ in }
    ) -> DashboardVideoFeedCollectionViewController {
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
extension DashboardVideoFeedCollectionViewController {
    
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
extension DashboardVideoFeedCollectionViewController {

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
            heightDimension: .absolute(240.0)
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
            case .videoEpisodes:
                return self.makeVideoEpisodeSectionLayout()
            case .videoFeeds:
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

        snapshot.appendSections(CollectionViewSection.allCases)
        
        snapshot.appendItems(
            videoFeeds.sorted { (first, second) in
                guard let firstDate = first.chat?.webAppLastDate else {
                    return false
                }
                guard let secondDate = second.chat?.webAppLastDate else {
                    return true
                }
                return firstDate > secondDate
            }.map { DataSourceItem.videoFeed($0) },
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
        videoEpisodes = videoFeeds.compactMap(\.videosArray.last)

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
extension DashboardVideoFeedCollectionViewController {
    
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
