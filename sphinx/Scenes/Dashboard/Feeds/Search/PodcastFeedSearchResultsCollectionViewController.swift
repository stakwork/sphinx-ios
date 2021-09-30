// PodcastFeedSearchResultsCollectionViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit
import CoreData



class PodcastFeedSearchResultsCollectionViewController: UICollectionViewController {
    var podcastFeeds: [PodcastFeed]!
    var directorySearchResults: [PodcastFeedSearchResult]!
    var interSectionSpacing: CGFloat = 0.0

    var onPodcastFeedCellSelected: ((NSManagedObjectID) -> Void)!
    var onPodcastDirectoryResultCellSelected: ((PodcastFeedSearchResult) -> Void)!
    var onPodcastSubscriptionSelected: ((PodcastFeedSearchResult) -> Void)!
    var onPodcastSubscriptionCancellationSelected: ((PodcastFeedSearchResult) -> Void)!

    
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
extension PodcastFeedSearchResultsCollectionViewController {

    static func instantiate(
        podcastFeeds: [PodcastFeed] = [],
        directorySearchResults: [PodcastFeedSearchResult] = [],
        interSectionSpacing: CGFloat = 0.0,
        onPodcastFeedCellSelected: ((NSManagedObjectID) -> Void)!,
        onPodcastDirectoryResultCellSelected: ((PodcastFeedSearchResult) -> Void)!,
        onPodcastSubscriptionSelected: ((PodcastFeedSearchResult) -> Void)!,
        onPodcastSubscriptionCancellationSelected: ((PodcastFeedSearchResult) -> Void)!
    ) -> PodcastFeedSearchResultsCollectionViewController {
        let viewController = StoryboardScene
            .Dashboard
            .podcastFeedSearchResultsCollectionViewController
            .instantiate()

        viewController.podcastFeeds = podcastFeeds
        viewController.directorySearchResults = directorySearchResults
        viewController.interSectionSpacing = interSectionSpacing
        viewController.onPodcastFeedCellSelected = onPodcastFeedCellSelected
        viewController.onPodcastDirectoryResultCellSelected = onPodcastDirectoryResultCellSelected
        viewController.onPodcastSubscriptionSelected = onPodcastSubscriptionSelected
        viewController.onPodcastSubscriptionCancellationSelected = onPodcastSubscriptionCancellationSelected
        
        return viewController
    }
}


// MARK: - Layout & Data Structure
extension PodcastFeedSearchResultsCollectionViewController {
    
    enum CollectionViewSection: Int, CaseIterable {
        case subscribedFeedsResults
        case podcastIndexSearchResults
        
        var titleForDisplay: String {
            switch self {
            case .subscribedFeedsResults:
                return "dashboard.feeds.section-headings.following".localized
            case .podcastIndexSearchResults:
                return "dashboard.feeds.section-headings.directory".localized
            }
        }
    }
    
    
    enum DataSourceItem: Hashable {
        case subscribedFeedsResult(PodcastFeed)
        case podcastIndexSearchResult(PodcastFeedSearchResult)
    }

    
    typealias ReusableHeaderView = PodcastFeedSearchResultsCollectionViewSectionHeader
    typealias CollectionViewCell = PodcastFeedSearchResultCollectionViewCell
    typealias CellDataItem = DataSourceItem
    typealias DataSource = UICollectionViewDiffableDataSource<CollectionViewSection, CellDataItem>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, CellDataItem>
}


// MARK: - Lifecycle
extension PodcastFeedSearchResultsCollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        registerViews(for: collectionView)
        configure(collectionView)
        configureDataSource(for: collectionView)
    }
}


// MARK: - Layout Composition
extension PodcastFeedSearchResultsCollectionViewController {

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


    func makeSearchResultsListSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = itemContentInsets


        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(90)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])


        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .none
        section.boundarySupplementaryItems = [makeSectionHeader()]

        return section
    }


    func makeSectionProvider() -> UICollectionViewCompositionalLayoutSectionProvider {
        { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            self.makeSearchResultsListSection()
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
extension PodcastFeedSearchResultsCollectionViewController {

    func registerViews(for collectionView: UICollectionView) {
        collectionView.register(
            CollectionViewCell.nib,
            forCellWithReuseIdentifier: CollectionViewCell.reuseID
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
extension PodcastFeedSearchResultsCollectionViewController {

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
extension PodcastFeedSearchResultsCollectionViewController {

    func makeCellProvider(for collectionView: UICollectionView) -> DataSource.CellProvider {
        { [weak self] (collectionView, indexPath, dataSourceItem) -> UICollectionViewCell? in
            guard
                let self = self,
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CollectionViewCell.reuseID,
                    for: indexPath
                ) as? CollectionViewCell,
                let section = CollectionViewSection(rawValue: indexPath.section)
            else {
                return nil
            }

            let isLastRow = (
                indexPath.row == (
                    collectionView.numberOfItems(inSection: indexPath.section)
                ) - 1
            )
            
            cell.configure(
                withItem: dataSourceItem.searchResult,
                subscriptionState: self.subscriptionState(for: dataSourceItem, in: section),
                shouldShowSeparator: isLastRow == false
            )
            
            cell.onSubscriptionButtonTapped = self.handleSubscriptionButtonTap(searchResult:subscriptionState:)

            return cell
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
extension PodcastFeedSearchResultsCollectionViewController {

    func makeSnapshotForCurrentState() -> DataSourceSnapshot {
        var snapshot = DataSourceSnapshot()

        snapshot.appendSections(CollectionViewSection.allCases)
        
        snapshot.appendItems(
            podcastFeeds.map { DataSourceItem.subscribedFeedsResult($0) },
            toSection: .subscribedFeedsResults
        )
        
        snapshot.appendItems(
            directorySearchResults.map { DataSourceItem.podcastIndexSearchResult($0) },
            toSection: .podcastIndexSearchResults
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
        self.podcastFeeds = followedPodcastFeeds

        if let dataSource = dataSource {
            dataSource.apply(
                makeSnapshotForCurrentState(),
                animatingDifferences: shouldAnimate
            )
        }
    }
    
    
    func updateWithNew(
        directorySearchResults: [PodcastFeedSearchResult],
        shouldAnimate: Bool = true
    ) {
        self.directorySearchResults = directorySearchResults

        if let dataSource = dataSource {
            dataSource.apply(
                makeSnapshotForCurrentState(),
                animatingDifferences: shouldAnimate
            )
        }
    }
    
    
    func refreshPodcastIndexResultItem(
        using searchResult: PodcastFeedSearchResult,
        shouldAnimate: Bool = true
    ) {
        var newSnapshot = makeSnapshotForCurrentState()

        let dataSourceItem = DataSourceItem.podcastIndexSearchResult(searchResult)
        newSnapshot.reloadItems([dataSourceItem])
        
        dataSource.apply(
            newSnapshot,
            animatingDifferences: shouldAnimate
        )
    }
}


// MARK: - `UICollectionViewDelegate` Methods
extension PodcastFeedSearchResultsCollectionViewController {

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
        case .subscribedFeedsResults:
            guard
                case let .subscribedFeedsResult(podcastFeed) = dataSourceItem
            else {
                preconditionFailure()
            }
            
            onPodcastFeedCellSelected?(podcastFeed.objectID)
        case .podcastIndexSearchResults:
            guard
                case let .podcastIndexSearchResult(directorySearchResult) = dataSourceItem
            else {
                preconditionFailure()
            }
            
            onPodcastDirectoryResultCellSelected?(directorySearchResult)
        }
    }
}


extension PodcastFeedSearchResultsCollectionViewController.DataSourceItem {
    
    var searchResult: PodcastFeedSearchResult {
        switch self {
        case .subscribedFeedsResult(let podcastFeed):
            return podcastFeed.searchResultItem
        case .podcastIndexSearchResult(let result):
            return result
        }
    }
    
    var podcastFeedObject: PodcastFeed? {
        switch self {
        case .subscribedFeedsResult(let podcastFeed):
            return podcastFeed
        case .podcastIndexSearchResult:
            return nil
        }
    }
}


extension PodcastFeedSearchResultsCollectionViewController {
    
    private func subscriptionState(
        for dataSourceItem: DataSourceItem,
        in section: CollectionViewSection
    ) -> PodcastFeedSearchResultCollectionViewCell.SubscriptionState {
        switch section {
        case .subscribedFeedsResults:
            return .followedViaTribe
        case .podcastIndexSearchResults:
            if dataSource
                .snapshot()
                .itemIdentifiers(inSection: .subscribedFeedsResults)
                .contains(
                    where: { podcastFeedDataSourceItem in
                        podcastFeedDataSourceItem.searchResult == dataSourceItem.searchResult
                    }
                )
            {
                return .subscribedFromPodcastIndex
            } else {
                return .subscriptionAvailableFromPodcastIndex
            }
        }
    }
    
    
    private func handleSubscriptionButtonTap(
        searchResult: PodcastFeedSearchResult,
        subscriptionState: PodcastFeedSearchResultCollectionViewCell.SubscriptionState
    ) {
        switch subscriptionState {
        case .followedViaTribe:
            break
        case .subscribedFromPodcastIndex:
            onPodcastSubscriptionCancellationSelected(searchResult)
        case .subscriptionAvailableFromPodcastIndex:
            onPodcastSubscriptionSelected(searchResult)
        }
    }
}

