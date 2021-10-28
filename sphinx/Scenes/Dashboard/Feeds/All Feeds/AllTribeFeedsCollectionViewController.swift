// AllTribeFeedsCollectionViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit
import CoreData


class AllTribeFeedsCollectionViewController: UICollectionViewController {
    var tribesWithFeeds: [Chat] = []
    var interSectionSpacing: CGFloat = 20.0

    var onCellSelected: ((NSManagedObjectID) -> Void)!
    var onNewResultsFetched: ((Int) -> Void)!

    private var managedObjectContext: NSManagedObjectContext!
    private var fetchedResultsController: NSFetchedResultsController<Chat>!
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
extension AllTribeFeedsCollectionViewController {

    static func instantiate(
        managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext,
        interSectionSpacing: CGFloat = 20.0,
        onCellSelected: ((NSManagedObjectID) -> Void)!,
        onNewResultsFetched: @escaping ((Int) -> Void) = { _ in }
    ) -> AllTribeFeedsCollectionViewController {
        let viewController = StoryboardScene
            .Dashboard
            .allTribeFeedsCollectionViewController
            .instantiate()

        viewController.managedObjectContext = managedObjectContext

        viewController.interSectionSpacing = interSectionSpacing
        viewController.onCellSelected = onCellSelected
        viewController.onNewResultsFetched = onNewResultsFetched
        
        viewController.fetchedResultsController = Self.makeFetchedResultsController(using: managedObjectContext)
        viewController.fetchedResultsController.delegate = viewController
        
        return viewController
    }
}


// MARK: - Layout & Data Structure
extension AllTribeFeedsCollectionViewController {
    
    enum CollectionViewSection: Int, CaseIterable {
        case followedFeeds
        
        var titleForDisplay: String {
            switch self {
            case .followedFeeds:
                return "Following"
            }
        }
    }
    
    
    enum DataSourceItem: Hashable {
        case tribePodcastFeed(PodcastFeed)
        case tribeVideoFeed(VideoFeed)
    }

    
    typealias ReusableHeaderView = DashboardFeedCollectionViewSectionHeader
    typealias CellDataItem = DataSourceItem
    typealias DataSource = UICollectionViewDiffableDataSource<CollectionViewSection, CellDataItem>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, CellDataItem>
}


// MARK: - Lifecycle
extension AllTribeFeedsCollectionViewController {

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
extension AllTribeFeedsCollectionViewController {

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


    func makeFollowedFeedsSectionLayout() -> NSCollectionLayoutSection {
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
        section.contentInsets = .init(top: 11, leading: 0, bottom: 11, trailing: 0)

        return section
    }


    func makeSectionProvider() -> UICollectionViewCompositionalLayoutSectionProvider {
        { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            switch CollectionViewSection(rawValue: sectionIndex)! {
            case .followedFeeds:
                return self.makeFollowedFeedsSectionLayout()
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
extension AllTribeFeedsCollectionViewController {

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
extension AllTribeFeedsCollectionViewController {

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
extension AllTribeFeedsCollectionViewController {

    func makeCellProvider(for collectionView: UICollectionView) -> DataSource.CellProvider {
        { (collectionView, indexPath, dataSourceItem) -> UICollectionViewCell in
            guard
                let section = CollectionViewSection(rawValue: indexPath.section)
            else {
                preconditionFailure("Unexpected Section index path")
            }
            
            switch section {
            case .followedFeeds:
                guard
                    let feedCell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: DashboardFeedSquaredThumbnailCollectionViewCell.reuseID,
                        for: indexPath
                    ) as? DashboardFeedSquaredThumbnailCollectionViewCell
                else {
                    preconditionFailure("Failed to dequeue expected reusable cell type")
                }
                
                guard
                    let feedEntity = dataSourceItem
                        .feedEntity
                        as? DashboardFeedSquaredThumbnailCollectionViewItem
                else {
                    preconditionFailure("Failed to find entity that conforms to `DashboardFeedSquaredThumbnailCollectionViewItem`")
                }
                
                feedCell.configure(withItem: feedEntity)
                
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
extension AllTribeFeedsCollectionViewController {

    func makeSnapshotForCurrentState() -> DataSourceSnapshot {
        var snapshot = DataSourceSnapshot()

        snapshot.appendSections(CollectionViewSection.allCases)
  
        let dataSourceItems = tribesWithFeeds.compactMap { tribeChat -> DataSourceItem? in
            if let podcastFeed = tribeChat.podcastFeed {
                return DataSourceItem.tribePodcastFeed(podcastFeed)
            } else if let videoFeed = tribeChat.videoFeed {
                return DataSourceItem.tribeVideoFeed(videoFeed)
            } else {
                return nil
            }
        }
        
        snapshot.appendItems(
            dataSourceItems,
            toSection: .followedFeeds
        )
        
        return snapshot
    }


    func updateSnapshot(shouldAnimate: Bool = true) {
        let snapshot = makeSnapshotForCurrentState()

        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }
    
    
    func updateWithNew(
        tribes tribesWithFeeds: [Chat],
        shouldAnimate: Bool = true
    ) {
        self.tribesWithFeeds = tribesWithFeeds

        if let dataSource = dataSource {
            dataSource.apply(
                makeSnapshotForCurrentState(),
                animatingDifferences: shouldAnimate
            )
        }
    }
}


// MARK: -  Fetched Result Controller
extension AllTribeFeedsCollectionViewController {
    
    static func makeFetchedResultsController(
        using managedObjectContext: NSManagedObjectContext
    ) -> NSFetchedResultsController<Chat> {
        let fetchRequest = Chat.FetchRequests.default()
        
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
extension AllTribeFeedsCollectionViewController {

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard
            let dataSourceItem = dataSource.itemIdentifier(for: indexPath)
        else {
            return
        }

        onCellSelected?(dataSourceItem.feedEntity.objectID)
    }
}


extension AllTribeFeedsCollectionViewController: NSFetchedResultsControllerDelegate {
    
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
            let foundTribes = firstSection.objects as? [Chat]
        else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.updateWithNew(
                tribes: foundTribes
            )
            
            self?.onNewResultsFetched(foundTribes.count)
        }
    }
}


// MARK: -  Computeds
extension AllTribeFeedsCollectionViewController.DataSourceItem {
    
    var feedEntity: NSManagedObject {
        switch self {
        case .tribePodcastFeed(let podcastFeed):
            return podcastFeed
        case .tribeVideoFeed(let videoFeed):
            return videoFeed
        }
    }
}
