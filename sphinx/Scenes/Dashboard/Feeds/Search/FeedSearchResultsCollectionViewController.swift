// FeedSearchResultsCollectionViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit
import CoreData


class FeedSearchResultsCollectionViewController: UICollectionViewController {
    
    var subscribedFeeds: [FeedSearchResult]!
    var feedSearchResults: [FeedSearchResult]!
    
    var interSectionSpacing: CGFloat = 0.0

    var onSubscribedFeedCellSelected: ((FeedSearchResult) -> Void)!
    var onFeedSearchResultCellSelected: ((FeedSearchResult) -> Void)!

    
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
extension FeedSearchResultsCollectionViewController {

    static func instantiate(
        subscribedFeeds: [FeedSearchResult] = [],
        feedSearchResults: [FeedSearchResult] = [],
        interSectionSpacing: CGFloat = 0.0,
        onSubscribedFeedCellSelected: ((FeedSearchResult) -> Void)!,
        onFeedSearchResultCellSelected: ((FeedSearchResult) -> Void)!
    ) -> FeedSearchResultsCollectionViewController {
        let viewController = StoryboardScene
            .Dashboard
            .FeedSearchResultsCollectionViewController
            .instantiate()

        viewController.subscribedFeeds = subscribedFeeds
        viewController.feedSearchResults = feedSearchResults
        viewController.interSectionSpacing = interSectionSpacing
        viewController.onSubscribedFeedCellSelected = onSubscribedFeedCellSelected
        viewController.onFeedSearchResultCellSelected = onFeedSearchResultCellSelected
        
        return viewController
    }
}


// MARK: - Layout & Data Structure
extension FeedSearchResultsCollectionViewController {
    
    enum CollectionViewSection: Int, CaseIterable {
        case subscribedFeedsResults
        case feedSearchResults
        
        var titleForDisplay: String {
            switch self {
            case .subscribedFeedsResults:
                return "dashboard.feeds.section-headings.following".localized
            case .feedSearchResults:
                return "dashboard.feeds.section-headings.directory".localized
            }
        }
    }
    
    
    enum DataSourceItem: Hashable {
        case subscribedFeeds(FeedSearchResult)
        case feedSearchResult(FeedSearchResult)
    }

    
    typealias ReusableHeaderView = FeedSearchResultsCollectionViewSectionHeader
    typealias CollectionViewCell = FeedSearchResultCollectionViewCell
    typealias CellDataItem = DataSourceItem
    typealias DataSource = UICollectionViewDiffableDataSource<CollectionViewSection, CellDataItem>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, CellDataItem>
}


// MARK: - Lifecycle
extension FeedSearchResultsCollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        registerViews(for: collectionView)
        configure(collectionView)
        configureDataSource(for: collectionView)
    }
}


// MARK: - Layout Composition
extension FeedSearchResultsCollectionViewController {

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
extension FeedSearchResultsCollectionViewController {

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
extension FeedSearchResultsCollectionViewController {

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
extension FeedSearchResultsCollectionViewController {

    func makeCellProvider(for collectionView: UICollectionView) -> DataSource.CellProvider {
        { [weak self] (collectionView, indexPath, dataSourceItem) -> UICollectionViewCell? in
            guard
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CollectionViewCell.reuseID,
                    for: indexPath
                ) as? CollectionViewCell,
                let _ = CollectionViewSection(rawValue: indexPath.section)
            else {
                return nil
            }

            let isLastRow = (
                indexPath.row == (
                    collectionView.numberOfItems(inSection: indexPath.section)
                ) - 1
            )
            
            cell.configure(
                withItem: dataSourceItem.feedObject,
                shouldShowSeparator: isLastRow == false
            )

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
                
                let section = self.getSectionFor(indexPath)

                headerView.render(withTitle: section.titleForDisplay)

                return headerView
            default:
                return UICollectionReusableView()
            }
        }
    }
    
    func getSectionFor(_ indexPath: IndexPath) -> CollectionViewSection {
        if subscribedFeeds.isEmpty && indexPath.section == 0 {
            return CollectionViewSection.allCases[indexPath.section + 1]
        }
        return CollectionViewSection.allCases[indexPath.section]
    }
}


// MARK: - Data Source Snapshot
extension FeedSearchResultsCollectionViewController {

    func makeSnapshotForCurrentState() -> DataSourceSnapshot {
        var snapshot = DataSourceSnapshot()
        
        if subscribedFeeds.count > 0 {
            snapshot.appendSections([CollectionViewSection.subscribedFeedsResults])
            
            snapshot.appendItems(
                subscribedFeeds.map { DataSourceItem.subscribedFeeds($0) },
                toSection: .subscribedFeedsResults
            )
        }
        
        if feedSearchResults.count > 0 {
            snapshot.appendSections([CollectionViewSection.feedSearchResults])
            
            snapshot.appendItems(
                feedSearchResults.map { DataSourceItem.feedSearchResult($0) },
                toSection: .feedSearchResults
            )
        }

        return snapshot
    }


    func updateSnapshot(shouldAnimate: Bool = true) {
        let snapshot = makeSnapshotForCurrentState()

        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }
    
    
    func updateWithNew(
        subscribedFeeds: [FeedSearchResult],
        shouldAnimate: Bool = true
    ) {
        self.subscribedFeeds = subscribedFeeds

        if let _ = dataSource {
            updateSnapshot(shouldAnimate: shouldAnimate)
        }
    }
    

    func updateWithNew(
        searchResults: [FeedSearchResult],
        shouldAnimate: Bool = true
    ) {
        self.feedSearchResults = searchResults

        if let _ = dataSource {
            updateSnapshot(shouldAnimate: shouldAnimate)
        }
    }
}


// MARK: - `UICollectionViewDelegate` Methods
extension FeedSearchResultsCollectionViewController {

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard
            let dataSourceItem = dataSource.itemIdentifier(for: indexPath)
        else {
            return
        }
        
        let section = getSectionFor(indexPath)

        switch section {
        case .subscribedFeedsResults:
            guard
                case let .subscribedFeeds(searchRsults) = dataSourceItem
            else {
                preconditionFailure()
            }
            
            onSubscribedFeedCellSelected?(searchRsults)
        case .feedSearchResults:
            guard
                case let .feedSearchResult(directorySearchResult) = dataSourceItem
            else {
                preconditionFailure()
            }
            
            onFeedSearchResultCellSelected?(directorySearchResult)
        }
    }
}


extension FeedSearchResultsCollectionViewController.DataSourceItem {
    
    var feedObject: FeedSearchResult {
        switch self {
        case .subscribedFeeds(let searchResult),
                .feedSearchResult(let searchResult):
            return searchResult
        }
    }
}


