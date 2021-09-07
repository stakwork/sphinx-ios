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
        interSectionSpacing: CGFloat = 0.0
    ) -> PodcastFeedSearchResultsCollectionViewController {
        let viewController = StoryboardScene
            .Dashboard
            .podcastFeedSearchResultsCollectionViewController
            .instantiate()

        viewController.podcastFeeds = podcastFeeds
        viewController.directorySearchResults = directorySearchResults
        viewController.interSectionSpacing = interSectionSpacing

        return viewController
    }
}


/// Type to represent that data returned when users search for podcasts.
struct PodcastFeedSearchResult {
    var title: String
    var subtitle: String
    var imageURLPath: String?
}

extension PodcastFeedSearchResult: Hashable {}


// MARK: - Layout & Data Structure
extension PodcastFeedSearchResultsCollectionViewController {
    
    enum CollectionViewSection: Int, CaseIterable {
        case subscribedFeedsResults
        case directoryResults
        
        var titleForDisplay: String {
            switch self {
            case .subscribedFeedsResults:
                return "dashboard.feeds.section-headings.following".localized
            case .directoryResults:
                return "dashboard.feeds.section-headings.directory".localized
            }
        }
    }
    
    
    enum DataSourceItem: Hashable {
        case subscribedFeedsResult(PodcastFeed)
        case directoryResult(PodcastFeedSearchResult)
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
            heightDimension: .estimated(80)
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
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
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
        { (collectionView, indexPath, dataSourceItem) -> UICollectionViewCell? in
            guard let cell = collectionView
                .dequeueReusableCell(
                    withReuseIdentifier: CollectionViewCell.reuseID,
                    for: indexPath
                ) as? CollectionViewCell
            else {
                return nil
            }

            let isLastRow = (
                indexPath.row == collectionView
                .numberOfItems(inSection: indexPath.row) - 1
            )
            
            cell.configure(
                withItem: dataSourceItem.searchResult,
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
            directorySearchResults.map { DataSourceItem.directoryResult($0) },
            toSection: .directoryResults
        )

        return snapshot
    }


    func updateSnapshot(shouldAnimate: Bool = true) {
        let snapshot = makeSnapshotForCurrentState()

        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }
    
    
    func updateWithNew(
        podcastFeeds: [PodcastFeed],
        shouldAnimate: Bool = true
    ) {
        self.podcastFeeds = podcastFeeds

        dataSource.apply(
            makeSnapshotForCurrentState(),
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
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return
        }

        // Do moar here
    }
}


extension PodcastFeed {
    
    var searchResultItem: PodcastFeedSearchResult {
        .init(
            title: title ?? "",
            subtitle: podcastDescription ?? "",
            imageURLPath: imageURLPath
        )
    }
}


extension PodcastFeedSearchResultsCollectionViewController.DataSourceItem {
    
    var searchResult: PodcastFeedSearchResult {
        switch self {
        case .subscribedFeedsResult(let podcastFeed):
            return podcastFeed.searchResultItem
        case .directoryResult(let result):
            return result
        }
    }
    
    var podcastFeedObject: PodcastFeed? {
        switch self {
        case .subscribedFeedsResult(let podcastFeed):
            return podcastFeed
        case .directoryResult:
            return nil
        }
    }
}

