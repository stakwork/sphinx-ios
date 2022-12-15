//
//  RecommendationFeedItemsCollectionCollectionViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/12/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class RecommendationFeedItemsCollectionViewController: UICollectionViewController {
    
    var podcast: PodcastFeed!

    var onRecommendationCellSelected: ((String) -> Void)!
    
    private var currentDataSnapshot: DataSourceSnapshot!
    private var dataSource: DataSource!
}

// MARK: -  Static Methods
extension RecommendationFeedItemsCollectionViewController {
    
    static func instantiate(
        podcast: PodcastFeed,
        onRecommendationCellSelected: @escaping ((String) -> Void) = { _ in }
    ) -> RecommendationFeedItemsCollectionViewController {
        let viewController = StoryboardScene
            .Recommendations
            .recommendationFeedItemsCollectionViewController
            .instantiate()
        
        viewController.podcast = podcast
        
        viewController.onRecommendationCellSelected = onRecommendationCellSelected
    
        return viewController
    }
}

// MARK: - Layout & Data Structure
extension RecommendationFeedItemsCollectionViewController {
    
    enum CollectionViewSection: Int, CaseIterable {
        case recommendations
    }
    
    enum DataSourceItem: Hashable {
        case recommendation(PodcastEpisode)
    }

    typealias RecommendationCell = RecommendationItemCollectionViewCell
    typealias CellDataItem = DataSourceItem
    typealias DataSource = UICollectionViewDiffableDataSource<CollectionViewSection, CellDataItem>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, CellDataItem>
}

// MARK: -  Lifecycle
extension RecommendationFeedItemsCollectionViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        registerViews(for: collectionView)
        configure(collectionView)
        configureDataSource(for: collectionView)
    }
}

// MARK: - Layout Composition
extension RecommendationFeedItemsCollectionViewController {

    func makeRecommendationsSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(60)
        )
        
        let headerItem = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        
        return headerItem
    }

    
    func makeRecommendationsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        item.contentInsets = .zero

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(103.0)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        
        let sectionHeader = makeRecommendationsSectionHeader()
        
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
            case .recommendations:
                return self.makeRecommendationsSection()
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
extension RecommendationFeedItemsCollectionViewController {

    func registerViews(for collectionView: UICollectionView) {
        collectionView.register(
            RecommendationsHeaderCollectionReusableView.nib,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: RecommendationsHeaderCollectionReusableView.reuseID
        )
        
        collectionView.register(
            RecommendationItemCollectionViewCell.nib,
            forCellWithReuseIdentifier: RecommendationItemCollectionViewCell.reuseID
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
extension RecommendationFeedItemsCollectionViewController {

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
extension RecommendationFeedItemsCollectionViewController {

    func makeCellProvider(for collectionView: UICollectionView) -> DataSource.CellProvider {
        { (collectionView, indexPath, dataSourceItem) -> UICollectionViewCell in
            guard
                let section = CollectionViewSection(rawValue: indexPath.section)
            else {
                preconditionFailure("Unexpected Section index path")
            }
            
            switch section {
            case .recommendations:
                guard
                    let recommendationCell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: RecommendationItemCollectionViewCell.reuseID,
                        for: indexPath
                    ) as? RecommendationItemCollectionViewCell
                else {
                    preconditionFailure("Failed to dequeue expected reusable cell type")
                }
                
                guard
                    case .recommendation(let recommendation) = dataSourceItem
                else {
                    preconditionFailure("Failed to find expected data source item")
                }

                recommendationCell.configure(withItem: recommendation)

                return recommendationCell
            }
        }
    }

    func makeSupplementaryViewProvider(
        for collectionView: UICollectionView
    ) -> DataSource.SupplementaryViewProvider {
        {(
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
            case .recommendations:
                switch kind {
                case UICollectionView.elementKindSectionHeader:
                    guard let headerView = collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind,
                        withReuseIdentifier: RecommendationsHeaderCollectionReusableView.reuseID,
                        for: indexPath
                    ) as? RecommendationsHeaderCollectionReusableView else {
                        preconditionFailure()
                    }
                    
                    headerView.configure(withCount: self.podcast.episodesArray.count)
                    
                    return headerView
                default:
                    preconditionFailure()
                }
            }
        }
    }
}

// MARK: - Data Source Snapshot
extension RecommendationFeedItemsCollectionViewController {

    func makeSnapshotForCurrentState() -> DataSourceSnapshot {
        var snapshot = DataSourceSnapshot()

        snapshot.appendSections(CollectionViewSection.allCases)

        snapshot.appendItems(
            (podcast.episodes ?? []).map { DataSourceItem.recommendation($0) },
            toSection: .recommendations
        )

        return snapshot
    }


    func updateSnapshot(shouldAnimate: Bool = true) {
        let snapshot = makeSnapshotForCurrentState()

        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }
}

// MARK: - `UICollectionViewDelegate` Methods
extension RecommendationFeedItemsCollectionViewController {

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
        case .recommendation(let recommendation):
            self.onRecommendationCellSelected(recommendation.itemID)
        }
    }
}