import UIKit


class FeedContentCollectionViewController: UICollectionViewController {
//    @IBOutlet private var collectionView: UICollectionView!

    var latestPodcastEpisodes: [PodcastEpisode]!
    var subscribedPodcastFeeds: [PodcastFeed]!
//    weak var cellDelegate: PodcastFeedCollectionViewCellDelegate?
    var sectionSpacing: CGFloat!
    var onItemSelected: ((DashboardPodcastCollectionViewItem) -> Void)!


    private var currentDataSnapshot: DataSourceSnapshot!
    private var dataSource: DataSource!
    private let itemContentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10)
    
//
//    init(
//        latestPodcastEpisodes: [PodcastFeed],
//        subscribedPodcastFeeds: [PodcastFeed],
//        cellDelegate: PodcastFeedCollectionViewCellDelegate,
//        sectionSpacing: CGFloat = 20.0
//    ) {
//        super.init()
//
//        self.newEpisodePodcastFeeds = newEpisodePodcastFeeds
//        self.subscribedPodcastFeeds = subscribedPodcastFeeds
//        self.cellDelegate = cellDelegate
//        self.sectionSpacing = sectionSpacing
//    }
//
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
}



// MARK: - Instantiation
extension FeedContentCollectionViewController {

    static func instantiate(
        latestPodcastEpisodes: [PodcastEpisode] = [],
        subscribedPodcastFeeds: [PodcastFeed] = [],
        sectionSpacing: CGFloat = 20.0,
        onItemSelected: @escaping ((DashboardPodcastCollectionViewItem) -> Void) = { _ in }
    ) -> FeedContentCollectionViewController {
        let viewController = StoryboardScene.Dashboard.feedContentCollectionViewController.instantiate()

        viewController.latestPodcastEpisodes = latestPodcastEpisodes
        viewController.subscribedPodcastFeeds = subscribedPodcastFeeds
        viewController.sectionSpacing = sectionSpacing
        viewController.onItemSelected = onItemSelected
        
        return viewController
    }
}


// MARK: - Layout & Data Structure
extension FeedContentCollectionViewController {
    enum CollectionViewSection: Int, CaseIterable {
        case latestPodcastEpisodes
        case subscribedPodcastFeeds
        
        var titleForDisplay: String {
            switch self {
            case .latestPodcastEpisodes:
                return "Listen Now"
            case .subscribedPodcastFeeds:
                return "Following"
            }
        }
    }
    
    enum DataSourceItem: Hashable {
        case latestPodcastEpisode(PodcastEpisode)
        case subscribedPodcastFeed(PodcastFeed)
    }
    
    typealias ReusableHeaderView = PodcastFeedCollectionViewSectionHeader
    typealias CollectionViewCell = PodcastFeedCollectionViewCell
    typealias CellDataItemType = DataSourceItem
    typealias DataSource = UICollectionViewDiffableDataSource<CollectionViewSection, CellDataItemType>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, CellDataItemType>
}



// MARK: - Lifecycle
extension FeedContentCollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.collectionViewLayout = makeLayout()

        registerViews(for: collectionView)
        configure(collectionView)
        configureDataSource(for: collectionView)
    }
}


// MARK: - Event Handling
private extension FeedContentCollectionViewController {
}


// MARK: - Navigation
private extension FeedContentCollectionViewController {
}



// MARK: - Layout Composition
extension FeedContentCollectionViewController {

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


    func makeFeedContentSection() -> NSCollectionLayoutSection {
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

        return section
    }


    func makeSectionProvider() -> UICollectionViewCompositionalLayoutSectionProvider {
        { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            self.makeFeedContentSection()
        }
    }


    func makeLayout() -> UICollectionViewLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = sectionSpacing

        let layout = UICollectionViewCompositionalLayout(sectionProvider: makeSectionProvider())
        layout.configuration = configuration

        return layout
    }
}


// MARK: - Collection View Configuration and View Registration
extension FeedContentCollectionViewController {

    func registerViews(for collectionView: UICollectionView) {
        collectionView.register(
            PodcastFeedCollectionViewCell.nib,
            forCellWithReuseIdentifier: PodcastFeedCollectionViewCell.reuseID
        )

        collectionView.register(
            ReusableHeaderView.nib,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ReusableHeaderView.reuseID
        )
    }


    func configure(_ collectionView: UICollectionView) {
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
    }
}



// MARK: - Data Source Configuration
extension FeedContentCollectionViewController {

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
        
        let snapshot = makeSnapshotWithInitialData(
            latestPodcastEpisodes: latestPodcastEpisodes,
            subscribedPodcastFeeds: subscribedPodcastFeeds
        )

        dataSource.apply(snapshot, animatingDifferences: false)
    }
}


extension PodcastEpisode: DashboardPodcastCollectionViewItem {
//    var title: String {
//        title ?? "Untitled Episode"
//    }
    
    var imageName: String {
        image ?? "podcastTagIcon"
    }
    
    var subtitle: String {
        description ?? ""
    }
}


extension PodcastFeed: DashboardPodcastCollectionViewItem {
    var imageName: String {
        image
    }
    
    var subtitle: String {
        description
    }
}


// MARK: - Data Source View Providers
extension FeedContentCollectionViewController {

    func makeCellProvider(
        for collectionView: UICollectionView
    ) -> DataSource.CellProvider {
        { (collectionView, indexPath, mediaType) -> UICollectionViewCell in
            guard
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CollectionViewCell.reuseID,
                    for: indexPath
                ) as? CollectionViewCell,
                let section = CollectionViewSection(rawValue: indexPath.section)
            else {
                preconditionFailure()
            }
            
//            var feed: PodcastFeed
//
//            switch section {
//            case .latestPodcastEpisodes:
//                feed = self.latestPodcastEpisodes[indexPath.row]
//            case .subscribedPodcastFeeds:
//                feed = self.subscribedPodcastFeeds[indexPath.row]
//            }
//
//            cell.delegate = self.cellDelegate
//            cell.configure(withPodcastFeed: feed)

            var cellItem: DashboardPodcastCollectionViewItem
            
            switch section {
            case .latestPodcastEpisodes:
                cellItem = self.latestPodcastEpisodes[indexPath.row]
            case .subscribedPodcastFeeds:
                cellItem = self.subscribedPodcastFeeds[indexPath.row]
            }
            
//            cell.delegate = self.cellDelegate
            cell.configure(withItem: cellItem)

            
            return cell
        }
    }


    func makeSupplementaryViewProvider(
        for collectionView: UICollectionView
    ) -> DataSource.SupplementaryViewProvider {
        {
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
                
                guard let section = CollectionViewSection(rawValue: indexPath.section) else {
                    preconditionFailure("Unknown section index: \(indexPath.section)")
                }

                headerView.render(withTitle: section.titleForDisplay)

                return headerView
            default:
                return UICollectionReusableView()
            }
        }
    }
}


// MARK: - Data Source Snapshot
extension FeedContentCollectionViewController {

    func update(
        _ snapshot: inout DataSourceSnapshot,
        withLatestPodcastEpisodes latestPodcastEpisodes: [PodcastEpisode],
        andSubscribedPodcastFeeds subscribedPodcastFeeds: [PodcastFeed]
    ) {
        snapshot.appendSections(CollectionViewSection.allCases)

        let latestPodcastEpisodeItems = latestPodcastEpisodes
            .map { DataSourceItem.latestPodcastEpisode($0) }
        
        snapshot.appendItems(
            latestPodcastEpisodeItems,
            toSection: CollectionViewSection.latestPodcastEpisodes
        )
        
        let subscribedPodcastFeedItems = subscribedPodcastFeeds
            .map { DataSourceItem.subscribedPodcastFeed($0) }
        
        snapshot.appendItems(
            subscribedPodcastFeedItems,
            toSection: CollectionViewSection.subscribedPodcastFeeds
        )
    }


    func makeSnapshotWithInitialData(
        latestPodcastEpisodes: [PodcastEpisode],
        subscribedPodcastFeeds: [PodcastFeed]
    ) -> DataSourceSnapshot {
        var snapshot = DataSourceSnapshot()
        
        update(
            &snapshot,
            withLatestPodcastEpisodes: latestPodcastEpisodes,
            andSubscribedPodcastFeeds: subscribedPodcastFeeds
        )

        return snapshot
    }

//
//    func updateSnapshot(
//        of dataSource: DataSource,
//        withlatestPodcastEpisodes latestPodcastEpisodes: [PodcastFeed],
//        andSubscribedPodcastFeeds subscribedPodcastFeeds: [PodcastFeed],
//        shouldAnimate: Bool = true
//    ) {
//        let snapshot = makeSnapshotWithInitialData(
//            latestPodcastEpisodes: latestPodcastEpisodes,
//            subscribedPodcastFeeds: subscribedPodcastFeeds
//        )
//
//        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
//    }
}


// MARK: - Private Helpers
private extension FeedContentCollectionViewController {
}


// MARK: - `UICollectionViewDelegate` Methods
extension FeedContentCollectionViewController {


}

