// VideoFeedEpisodePlayerCollectionViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    

import UIKit
import CoreData


class VideoFeedEpisodePlayerCollectionViewController: UICollectionViewController {
    
    var videoPlayerEpisode: Video!
    var videoFeedEpisodes: [Video]!

    var onVideoEpisodeCellSelected: ((NSManagedObjectID) -> Void)!
    var onFeedSubscriptionSelected: (() -> Void)!
    var onFeedSubscriptionCancellationSelected: (() -> Void)!
    
    private var currentDataSnapshot: DataSourceSnapshot!
    private var dataSource: DataSource!
    
    weak var boostDelegate: CustomBoostDelegate?
}


// MARK: -  Static Methods
extension VideoFeedEpisodePlayerCollectionViewController {
    
    static func instantiate(
        videoPlayerEpisode: Video,
        videoFeedEpisodes: [Video],
        boostDelegate: CustomBoostDelegate?,
        onVideoEpisodeCellSelected: @escaping ((NSManagedObjectID) -> Void) = { _ in },
        onFeedSubscriptionSelected: @escaping (() -> Void) = {},
        onFeedSubscriptionCancellationSelected: @escaping (() -> Void) = {}
    ) -> VideoFeedEpisodePlayerCollectionViewController {
        let viewController = StoryboardScene
            .VideoFeed
            .videoFeedEpisodePlayerCollectionViewController
            .instantiate()
        
        viewController.videoPlayerEpisode = videoPlayerEpisode
        viewController.videoFeedEpisodes = videoFeedEpisodes
        
        viewController.boostDelegate = boostDelegate
        
        viewController.onVideoEpisodeCellSelected = onVideoEpisodeCellSelected
        viewController.onFeedSubscriptionSelected = onFeedSubscriptionSelected
        viewController.onFeedSubscriptionCancellationSelected = onFeedSubscriptionCancellationSelected
    
        return viewController
    }
}



// MARK: - Layout & Data Structure
extension VideoFeedEpisodePlayerCollectionViewController {
    
    enum CollectionViewSection: Int, CaseIterable {
        case videoPlayerEpisodeDetails
        case videoFeedEpisodes
    }
    
    
    enum DataSourceItem: Hashable {
        case videoPlayerEpisodeDetails(Video)
        case videoFeedEpisode(Video)
    }
    

    typealias PlayerEpisodeDetailsCell = VideoFeedEpisodePlayerCollectionViewDetailsCell
    typealias FeedEpisodeCell = VideoFeedEpisodeCollectionViewCell
    typealias CellDataItem = DataSourceItem
    typealias DataSource = UICollectionViewDiffableDataSource<CollectionViewSection, CellDataItem>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, CellDataItem>
}


// MARK: -  Lifecycle
extension VideoFeedEpisodePlayerCollectionViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        registerViews(for: collectionView)
        configure(collectionView)
        configureDataSource(for: collectionView)
    }
}


// MARK: - Layout Composition
extension VideoFeedEpisodePlayerCollectionViewController {
    
    /// "Contributor Name" and Count of Views
    func makeVideoFeedEpisodesSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(100)
        )
        
        let headerItem = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        
        return headerItem
    }
    

    func makeVideoFeedEpisodeDetailsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .zero


        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(110.0)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )

        
        let section = NSCollectionLayoutSection(group: group)

        section.orthogonalScrollingBehavior = .none
        section.contentInsets = .zero

        return section
    }

    
    func makeVideoFeedEpisodesSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        item.contentInsets = .zero

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100.0)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        
        let sectionHeader = makeVideoFeedEpisodesSectionHeader()
        
        sectionHeader.pinToVisibleBounds = true

        let section = NSCollectionLayoutSection(group: group)

        section.orthogonalScrollingBehavior = .none
        section.boundarySupplementaryItems = [sectionHeader]
        section.contentInsets = .zero

        return section
    }


    func makeSectionProvider() -> UICollectionViewCompositionalLayoutSectionProvider {
        { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            switch CollectionViewSection(rawValue: sectionIndex)! {
            case .videoPlayerEpisodeDetails:
                return self.makeVideoFeedEpisodeDetailsSection()
            case .videoFeedEpisodes:
                return self.makeVideoFeedEpisodesSection()
            }
        }
    }


    func makeLayout() -> UICollectionViewLayout {
        let layoutConfiguration = UICollectionViewCompositionalLayoutConfiguration()

        layoutConfiguration.interSectionSpacing = .zero

        let layout = UICollectionViewCompositionalLayout(
            sectionProvider: makeSectionProvider()
        )

        layout.configuration = layoutConfiguration

        return layout
    }
}


// MARK: - Collection View Configuration and View Registration
extension VideoFeedEpisodePlayerCollectionViewController {

    func registerViews(for collectionView: UICollectionView) {
        collectionView.register(
            VideoFeedEpisodesSectionHeaderView.nib,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: VideoFeedEpisodesSectionHeaderView.reuseID
        )
        
        collectionView.register(
            PlayerEpisodeDetailsCell.nib,
            forCellWithReuseIdentifier: PlayerEpisodeDetailsCell.reuseID
        )
        
        collectionView.register(
            FeedEpisodeCell.nib,
            forCellWithReuseIdentifier: FeedEpisodeCell.reuseID
        )
    }


    func configure(_ collectionView: UICollectionView) {
        collectionView.contentInset = .zero
        collectionView.collectionViewLayout = makeLayout()
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .Sphinx.ListBG
        collectionView.showsVerticalScrollIndicator = false
        collectionView.scrollsToTop = false
        
        collectionView.delegate = self
    }
}


// MARK: - Data Source Configuration
extension VideoFeedEpisodePlayerCollectionViewController {

    func makeDataSource(for collectionView: UICollectionView) -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: makeCellProvider(for: collectionView)
        )

        dataSource.supplementaryViewProvider = makeSupplementaryViewProvider(
            for: collectionView
        )

        return dataSource
    }


    func configureDataSource(for collectionView: UICollectionView) {
        dataSource = makeDataSource(for: collectionView)

        let snapshot = makeSnapshotForCurrentState()

        dataSource.apply(snapshot, animatingDifferences: false)
    }
}


// MARK: - Data Source View Providers
extension VideoFeedEpisodePlayerCollectionViewController {

    func makeCellProvider(for collectionView: UICollectionView) -> DataSource.CellProvider {
        { (collectionView, indexPath, dataSourceItem) -> UICollectionViewCell in
            guard
                let section = CollectionViewSection(rawValue: indexPath.section)
            else {
                preconditionFailure("Unexpected Section index path")
            }
            
            switch section {
            case .videoPlayerEpisodeDetails:
                guard
                    let episodeCell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: PlayerEpisodeDetailsCell.reuseID,
                        for: indexPath
                    ) as? PlayerEpisodeDetailsCell
                else {
                    preconditionFailure("Failed to dequeue expected reusable cell type")
                }
                
                guard
                    case .videoPlayerEpisodeDetails(let videoEpisode) = dataSourceItem
                else {
                    preconditionFailure("Failed to find expected data source item")
                }

                episodeCell.configure(
                    withVideoEpisode: videoEpisode,
                    and: self.boostDelegate
                )

                return episodeCell
                
            case .videoFeedEpisodes:
                guard
                    let episodeCell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: FeedEpisodeCell.reuseID,
                        for: indexPath
                    ) as? FeedEpisodeCell
                else {
                    preconditionFailure("Failed to dequeue expected reusable cell type")
                }
                
                guard
                    case .videoFeedEpisode(let videoEpisode) = dataSourceItem
                else {
                    preconditionFailure("Failed to find expected data source item")
                }

                episodeCell.configure(withVideoEpisode: videoEpisode)

                return episodeCell
            }
        }
    }

    func makeSupplementaryViewProvider(
        for collectionView: UICollectionView
    ) -> DataSource.SupplementaryViewProvider {
        {
            (
                collectionView: UICollectionView,
                kind: String,
                indexPath: IndexPath
            ) -> UICollectionReusableView in
                guard
                    let section = CollectionViewSection(rawValue: indexPath.section)
                else {
                    preconditionFailure()
                }
            
                switch section {
                case .videoPlayerEpisodeDetails:
                    preconditionFailure()
                case .videoFeedEpisodes:
                    switch kind {
                    case UICollectionView.elementKindSectionHeader:
                        guard let headerView = collectionView.dequeueReusableSupplementaryView(
                            ofKind: kind,
                            withReuseIdentifier: VideoFeedEpisodesSectionHeaderView.reuseID,
                            for: indexPath
                        ) as? VideoFeedEpisodesSectionHeaderView else {
                            preconditionFailure()
                        }
                        
                        headerView.configure(
                            withEpisode: self.videoPlayerEpisode,
                            onFeedSubscribed: self.onFeedSubscriptionSelected,
                            onFeedUnsubscribed: self.onFeedSubscriptionCancellationSelected
                        )
                        
                        return headerView
                    default:
                        preconditionFailure()
                    }
                }
        }
    }
}


// MARK: - Data Source Snapshot
extension VideoFeedEpisodePlayerCollectionViewController {

    func makeSnapshotForCurrentState() -> DataSourceSnapshot {
        var snapshot = DataSourceSnapshot()

        snapshot.appendSections(CollectionViewSection.allCases)
        
        snapshot.appendItems(
            [ DataSourceItem.videoPlayerEpisodeDetails(videoPlayerEpisode) ],
            toSection: .videoPlayerEpisodeDetails
        )

        snapshot.appendItems(
            videoFeedEpisodes.sorted { (first, second) in
                guard let firstDate = first.videoFeed?.chat?.webAppLastDate else {
                    return false
                }
                guard let secondDate = second.videoFeed?.chat?.webAppLastDate else {
                    return true
                }
                return firstDate > secondDate
            }.map { DataSourceItem.videoFeedEpisode($0) },
            toSection: .videoFeedEpisodes
        )

        return snapshot
    }


    func updateSnapshot(shouldAnimate: Bool = true) {
        let snapshot = makeSnapshotForCurrentState()

        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }
    
    
    func updateWithNew(
        videoPlayerEpisode: Video,
        shouldAnimate: Bool = true
    ) {
        self.videoPlayerEpisode = videoPlayerEpisode
        
        if (self.videoFeedEpisodes.count != videoPlayerEpisode.videoFeed?.videosArray.count) {
            self.videoFeedEpisodes = videoPlayerEpisode.videoFeed?.videosArray ?? []
        }

        if let dataSource = dataSource {
            dataSource.apply(
                makeSnapshotForCurrentState(),
                animatingDifferences: shouldAnimate
            )
        }
    }
}


// MARK: - `UICollectionViewDelegate` Methods
extension VideoFeedEpisodePlayerCollectionViewController {

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
        case .videoPlayerEpisodeDetails:
            break
        case .videoFeedEpisode(let episode):
            self.onVideoEpisodeCellSelected(episode.objectID)
        }
    }
}
