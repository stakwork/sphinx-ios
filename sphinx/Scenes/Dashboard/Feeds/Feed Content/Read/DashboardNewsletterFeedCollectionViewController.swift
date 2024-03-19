//
//  DashboardNewsletterFeedCollectionViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import CoreData

class DashboardNewsletterFeedCollectionViewController: UICollectionViewController {
    
    var recentlyReleasedNewsletterFeeds: [NewsletterFeed] = []
    var recentlyPlayedNewsletterFeeds: [NewsletterFeed] = []
    
    var interSectionSpacing: CGFloat = 20.0

    var onNewsletterItemCellSelected: ((String) -> Void)!
    var onNewsletterFeedCellSelected: ((String) -> Void)!
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
extension DashboardNewsletterFeedCollectionViewController {

    static func instantiate(
        managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext,
        interSectionSpacing: CGFloat = 20.0,
        onNewsletterItemCellSelected: ((String) -> Void)!,
        onNewsletterFeedCellSelected: ((String) -> Void)!,
        onNewResultsFetched: @escaping ((Int) -> Void) = { _ in },
        onContentScrolled: ((UIScrollView) -> Void)? = nil
    ) -> DashboardNewsletterFeedCollectionViewController {
        
        let viewController = StoryboardScene
            .Dashboard
            .newsletterFeedCollectionViewController
            .instantiate()

        viewController.managedObjectContext = managedObjectContext

        viewController.interSectionSpacing = interSectionSpacing
        viewController.onNewsletterItemCellSelected = onNewsletterItemCellSelected
        viewController.onNewsletterFeedCellSelected = onNewsletterFeedCellSelected
        viewController.onNewResultsFetched = onNewResultsFetched
        viewController.onContentScrolled = onContentScrolled
        
        viewController.fetchedResultsController = Self.makeFetchedResultsController(using: managedObjectContext)
        viewController.fetchedResultsController.delegate = viewController
        
        return viewController
    }
}


// MARK: - Layout & Data Structure
extension DashboardNewsletterFeedCollectionViewController {
    
    enum CollectionViewSection: Int, CaseIterable {
        case recentlyPublishedFeeds
        case recentlyReadFeeds
        
        var titleForDisplay: String {
            switch self {
            case .recentlyPublishedFeeds:
                return "feed.recently-published".localized
            case .recentlyReadFeeds:
                return "feed.recently-read".localized
            }
        }
    }
    
    
    enum DataSourceItem: Hashable {
        case newsletterItem(NewsletterItem)
        case newsletterFeed(NewsletterFeed)
        
        static func == (lhs: DataSourceItem, rhs: DataSourceItem) -> Bool {
            if let lhsContentFeed = lhs.feedEntity,
               let rhsContentFeed = rhs.feedEntity {
                    
                return
                    lhsContentFeed.feedID == rhsContentFeed.feedID &&
                    lhsContentFeed.title == rhsContentFeed.title &&
                    lhsContentFeed.feedURL?.absoluteString == rhsContentFeed.feedURL?.absoluteString &&
                    lhsContentFeed.dateLastConsumed == rhsContentFeed.dateLastConsumed &&
                    lhsContentFeed.itemsArray.count == rhsContentFeed.itemsArray.count &&
                    lhsContentFeed.itemsArray.first?.id == rhsContentFeed.itemsArray.first?.id &&
                    lhsContentFeed.itemsArray.first?.datePublished == rhsContentFeed.itemsArray.first?.datePublished
            }
            
            if let lhsEpisode = lhs.articleEntity,
               let rhsEpisode = rhs.articleEntity {
                    
                return
                    lhsEpisode.itemID == rhsEpisode.itemID &&
                    lhsEpisode.title == rhsEpisode.title
            }

            return false
         }

        func hash(into hasher: inout Hasher) {
            if let contentFeed = self.feedEntity {
                hasher.combine(contentFeed.feedID)
            }
            
            if let episode = self.articleEntity {
                hasher.combine(episode.itemID)
            }
        }
    }

    
    typealias ReusableHeaderView = DashboardFeedCollectionViewSectionHeader
    typealias CellDataItem = DataSourceItem
    typealias DataSource = UICollectionViewDiffableDataSource<CollectionViewSection, CellDataItem>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, CellDataItem>
}


// MARK: - Lifecycle
extension DashboardNewsletterFeedCollectionViewController {

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
extension DashboardNewsletterFeedCollectionViewController {

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


    func makeNewsletterFeedSectionLayout() -> NSCollectionLayoutSection {
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
    
    
    func makeNewsletterItemSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = itemContentInsets


        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.9),
            heightDimension: .estimated(300.0)
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
            case .recentlyPublishedFeeds:
                return self.makeNewsletterItemSectionLayout()
            case .recentlyReadFeeds:
                return self.makeNewsletterFeedSectionLayout()
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
extension DashboardNewsletterFeedCollectionViewController {

    func registerViews(for collectionView: UICollectionView) {
        collectionView.register(
            DashboardFeedSquaredThumbnailCollectionViewCell.nib,
            forCellWithReuseIdentifier: DashboardFeedSquaredThumbnailCollectionViewCell.reuseID
        )
        
        collectionView.register(
            DashboardNewsletterItemCollectionViewCell.nib,
            forCellWithReuseIdentifier: DashboardNewsletterItemCollectionViewCell.reuseID
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
extension DashboardNewsletterFeedCollectionViewController {

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
extension DashboardNewsletterFeedCollectionViewController {

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
            case .recentlyPublishedFeeds:
                guard
                    let itemCell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: DashboardNewsletterItemCollectionViewCell.reuseID,
                        for: indexPath
                    ) as? DashboardNewsletterItemCollectionViewCell,
                    case .newsletterItem(let newsletterItem) = dataSourceItem
                else {
                    preconditionFailure("Failed to dequeue expected reusable cell type")
                }
                
                itemCell.configure(withNewsletterItem: newsletterItem)
                itemCell.delegate = self
                return itemCell
                
            case .recentlyReadFeeds:
                guard
                    let feedCell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: DashboardFeedSquaredThumbnailCollectionViewCell.reuseID,
                        for: indexPath
                    ) as? DashboardFeedSquaredThumbnailCollectionViewCell,
                    case .newsletterFeed(let newsletterFeed) = dataSourceItem
                else {
                    preconditionFailure("Failed to dequeue expected reusable cell type")
                }
                
                feedCell.configure(withItem: newsletterFeed)
                
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
extension DashboardNewsletterFeedCollectionViewController {

    func makeSnapshotForCurrentState() -> DataSourceSnapshot {
        var snapshot = DataSourceSnapshot()
        
        if (recentlyReleasedNewsletterFeeds.isEmpty && recentlyPlayedNewsletterFeeds.isEmpty) {
            return snapshot
        }

        snapshot.appendSections([CollectionViewSection.recentlyPublishedFeeds])
        
        snapshot.appendItems(
            recentlyReleasedNewsletterFeeds
                .compactMap { $0.lastArticle }
                .map { DataSourceItem.newsletterItem( $0 ) },
            toSection: .recentlyPublishedFeeds
        )
        
        let recentlyReadFeed = recentlyPlayedNewsletterFeeds.filter { $0.dateLastConsumed != nil }.compactMap { contentFeed -> DataSourceItem? in
            return DataSourceItem.newsletterFeed(contentFeed)
        }
        
        if !recentlyReadFeed.isEmpty {
            snapshot.appendSections([CollectionViewSection.recentlyReadFeeds])
            
            snapshot.appendItems(
                recentlyReadFeed,
                toSection: .recentlyReadFeeds
            )
        }

        return snapshot
    }


    func updateSnapshot(shouldAnimate: Bool = true) {
        let snapshot = makeSnapshotForCurrentState()

        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }
    
    
    func updateWithNew(
        newsletterFeeds: [NewsletterFeed],
        shouldAnimate: Bool = true
    ) {
        
        for feed in newsletterFeeds {
            let _ = feed.itemsArray
        }
        
        self.recentlyReleasedNewsletterFeeds = newsletterFeeds.sorted { (first, second) in
            let firstDate = first.newsletterItems?.first?.datePublished ?? Date.init(timeIntervalSince1970: 0)
            let secondDate = second.newsletterItems?.first?.datePublished ?? Date.init(timeIntervalSince1970: 0)
            
            return firstDate > secondDate
        }
        
        self.recentlyPlayedNewsletterFeeds = newsletterFeeds.sorted(by: {(first, second) in
            let firstDate = first.dateLastConsumed ?? Date.init(timeIntervalSince1970: 0)
            let secondDate = second.dateLastConsumed ?? Date.init(timeIntervalSince1970: 0)
            
            if (firstDate == secondDate) {
                let firstDate = first.newsletterItems?.first?.datePublished ?? Date.init(timeIntervalSince1970: 0)
                let secondDate = second.newsletterItems?.first?.datePublished ?? Date.init(timeIntervalSince1970: 0)

                return firstDate > secondDate
            }

            return firstDate > secondDate
        
        })

        if let dataSource = dataSource {
            dataSource.apply(
                makeSnapshotForCurrentState(),
                animatingDifferences: shouldAnimate
            )
        }
    }
}


// MARK: -  Fetched Result Controller
extension DashboardNewsletterFeedCollectionViewController {
    
    static func makeFetchedResultsController(
        using managedObjectContext: NSManagedObjectContext
    ) -> NSFetchedResultsController<ContentFeed> {
        let fetchRequest = NewsletterFeed.FetchRequests.allFeeds()
        
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

extension DashboardNewsletterFeedCollectionViewController : DashboardNewsLetterItemCollectionViewCellDelegate{
    
    func handleShare(item: NewsletterItem) {
        self.shareTapped(newsletterItem: item)
    }
    
}

// MARK: - `UICollectionViewDelegate` Methods
extension DashboardNewsletterFeedCollectionViewController {

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
        case .recentlyPublishedFeeds:
            guard
                case let .newsletterItem(newsletterItem) = dataSourceItem
            else {
                preconditionFailure()
            }
            
            onNewsletterItemCellSelected?(newsletterItem.id)
        case .recentlyReadFeeds:
            guard
                case let .newsletterFeed(newsletterFeed) = dataSourceItem
            else {
                preconditionFailure()
            }
            
            onNewsletterFeedCellSelected?(newsletterFeed.id)
        }
    }
}


extension DashboardNewsletterFeedCollectionViewController: NSFetchedResultsControllerDelegate {
    
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
        
        let newsletterFeeds = foundFeeds.map {
            NewsletterFeed.convertFrom(contentFeed: $0)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.updateWithNew(
                newsletterFeeds: newsletterFeeds
            )
            
            self?.onNewResultsFetched(newsletterFeeds.count)
        }
    }
}

extension NewsletterFeed: DashboardFeedSquaredThumbnailCollectionViewItem {
    
    var imageToShow: String? {
        imageURL?.absoluteString ?? chat?.photoUrl
    }
    
    var placeholderImageName: String? {
        "newsletterPlaceholder"
    }
    
    var subtitle: String? {
        feedDescription
    }
    
    var typeIconImage: String? { get { nil }}
    
    var titleLines: Int {
        1
    }
    
    var publishDate: Date? {
        return itemsArray.first?.datePublished
    }
}

extension NewsletterItem: DashboardFeedSquaredThumbnailCollectionViewItem {
    
    var imageToShow: String? {
        imageUrl?.absoluteString ?? newsletterFeed?.imageURL?.absoluteString
    }
    
    var placeholderImageName: String? {
        "newsletterPlaceholder"
    }

    var subtitle: String? {
        itemDescription
    }
    
    var typeIconImage: String? { get { nil }}
    
    var titleLines: Int {
        1
    }
    
    var publishDate: Date? {
        return datePublished
    }
}

extension DashboardNewsletterFeedCollectionViewController.DataSourceItem {
    
    var feedEntity: NewsletterFeed? {
        switch self {
        case .newsletterFeed(let newsletterFeed):
            return newsletterFeed
        default:
            return nil
        }
    }
    
    var articleEntity: NewsletterItem? {
        switch self {
        case .newsletterItem(let newsletterItem):
            return newsletterItem
        default:
            return nil
        }
    }
}
