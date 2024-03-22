//
//  NewsletterFeedItemsCollectionViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 28/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import CoreData

class NewsletterFeedItemsCollectionViewController: UICollectionViewController {
    
    var newsletterItems: [NewsletterItem]!

    var onNewsletterItemCellSelected: ((String) -> Void)!
    
    private var currentDataSnapshot: DataSourceSnapshot!
    private var dataSource: DataSource!
}

// MARK: -  Static Methods
extension NewsletterFeedItemsCollectionViewController {
    
    static func instantiate(
        newsletterItems: [NewsletterItem],
        onNewsletterItemCellSelected: @escaping ((String) -> Void) = { _ in }
    ) -> NewsletterFeedItemsCollectionViewController {
        let viewController = StoryboardScene
            .NewsletterFeed
            .newsletterFeedItemsCollectionViewController
            .instantiate()
        
        viewController.newsletterItems = newsletterItems
        viewController.onNewsletterItemCellSelected = onNewsletterItemCellSelected
        
        return viewController
    }
}



// MARK: - Layout & Data Structure
extension NewsletterFeedItemsCollectionViewController {
    
    enum CollectionViewSection: Int, CaseIterable {
        case newsletterItems
    }
    
    enum DataSourceItem: Hashable {
        case newsletterItem(NewsletterItem)
    }
    

    typealias NewsletterItemCell = NewsletterItemCollectionViewCell
    typealias CellDataItem = DataSourceItem
    typealias DataSource = UICollectionViewDiffableDataSource<CollectionViewSection, CellDataItem>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, CellDataItem>
}


// MARK: -  Lifecycle
extension NewsletterFeedItemsCollectionViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        registerViews(for: collectionView)
        configure(collectionView)
        configureDataSource(for: collectionView)
    }
    
    func reloadItems(
        newsletterItems: [NewsletterItem],
        forceReload: Bool = false
    ) {
        if forceReload || (newsletterItems.count > 0 && newsletterItems.count != self.newsletterItems.count) {
            self.newsletterItems = newsletterItems
            configureDataSource(for: collectionView)
        }
    }
}


// MARK: - Layout Composition
extension NewsletterFeedItemsCollectionViewController {
    
    /// "Contributor Name" and Count of Views
    func makeNewsletterItemsSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(50)
        )
        
        let headerItem = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        
        return headerItem
    }

    
    func makeNewsletterItemsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        item.contentInsets = .zero


        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(120.0)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        
        
        let sectionHeader = makeNewsletterItemsSectionHeader()
        
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
            case .newsletterItems:
                return self.makeNewsletterItemsSection()
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
extension NewsletterFeedItemsCollectionViewController {

    func registerViews(for collectionView: UICollectionView) {
        collectionView.register(
            NewsletterItemsSectionCollectionReusableView.nib,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: NewsletterItemsSectionCollectionReusableView.reuseID
        )
        
        collectionView.register(
            NewsletterItemCell.nib,
            forCellWithReuseIdentifier: NewsletterItemCell.reuseID
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
extension NewsletterFeedItemsCollectionViewController {

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
extension NewsletterFeedItemsCollectionViewController {

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
            case .newsletterItems:
                guard
                    let episodeCell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: NewsletterItemCell.reuseID,
                        for: indexPath
                    ) as? NewsletterItemCell
                else {
                    preconditionFailure("Failed to dequeue expected reusable cell type")
                }
                
                guard
                    case .newsletterItem(let newsletterItem) = dataSourceItem
                else {
                    preconditionFailure("Failed to find expected data source item")
                }

                episodeCell.configure(withNewsletterItem: newsletterItem)

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
                case .newsletterItems:
                    switch kind {
                    case UICollectionView.elementKindSectionHeader:
                        guard let headerView = collectionView.dequeueReusableSupplementaryView(
                            ofKind: kind,
                            withReuseIdentifier: NewsletterItemsSectionCollectionReusableView.reuseID,
                            for: indexPath
                        ) as? NewsletterItemsSectionCollectionReusableView else {
                            preconditionFailure()
                        }
                        
                        headerView.configure(withItemsCount: self.newsletterItems.count)
                        
                        return headerView
                    default:
                        preconditionFailure()
                    }
                }
        }
    }
}


// MARK: - Data Source Snapshot
extension NewsletterFeedItemsCollectionViewController {

    func makeSnapshotForCurrentState() -> DataSourceSnapshot {
        var snapshot = DataSourceSnapshot()

        snapshot.appendSections(CollectionViewSection.allCases)


        snapshot.appendItems(
            newsletterItems.sorted { (first, second) in
                guard let firstDate = first.newsletterFeed?.chat?.webAppLastDate else {
                    return false
                }
                guard let secondDate = second.newsletterFeed?.chat?.webAppLastDate else {
                    return true
                }
                return firstDate > secondDate
            }.map { DataSourceItem.newsletterItem($0) },
            toSection: .newsletterItems
        )

        return snapshot
    }


    func updateSnapshot(shouldAnimate: Bool = true) {
        let snapshot = makeSnapshotForCurrentState()

        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }
}


// MARK: - `UICollectionViewDelegate` Methods
extension NewsletterFeedItemsCollectionViewController {

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
        case .newsletterItem(let newsletterItem):
            self.onNewsletterItemCellSelected(newsletterItem.id)
        }
    }
}
