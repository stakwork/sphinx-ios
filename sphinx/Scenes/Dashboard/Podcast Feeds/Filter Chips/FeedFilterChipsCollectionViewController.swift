import UIKit


class FeedFilterChipsCollectionViewController: UICollectionViewController {
//    @IBOutlet private var collectionView: UICollectionView!


    var mediaTypes: [String] = []
    weak var cellDelegate: FeedFilterChipCollectionViewCellDelegate?
    var sectionSpacing: CGFloat = 20.0


    private var currentDataSnapshot: DataSourceSnapshot!
    private var dataSource: DataSource!
    private let itemContentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
    
//
//    init(
//        mediaTypes: [String],
//        cellDelegate: FeedFilterChipCollectionViewCellDelegate,
//        sectionSpacing: CGFloat = 20.0
//    ) {
//        super.init()
//
//        self.mediaTypes = mediaTypes
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
extension FeedFilterChipsCollectionViewController {

    static func instantiate(
        mediaTypes: [String],
        cellDelegate: FeedFilterChipCollectionViewCellDelegate,
        sectionSpacing: CGFloat = 20.0
    ) -> FeedFilterChipsCollectionViewController {
        let viewController = StoryboardScene.Dashboard.feedFilterChipsCollectionViewController.instantiate()

        viewController.mediaTypes = mediaTypes
        viewController.cellDelegate = cellDelegate
        viewController.sectionSpacing = sectionSpacing

        return viewController
    }
}


// MARK: - Layout & Data Structure
extension FeedFilterChipsCollectionViewController {
    enum CollectionViewSection: CaseIterable {
        case all
    }

    typealias CollectionViewCell = FeedFilterChipCollectionViewCell
    typealias CellDataItemType = String
    typealias DataSource = UICollectionViewDiffableDataSource<CollectionViewSection, CellDataItemType>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, CellDataItemType>
}



// MARK: - Lifecycle
extension FeedFilterChipsCollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.collectionViewLayout = makeLayout()

        registerViews(for: collectionView)
        configure(collectionView)
        configureDataSource(for: collectionView)
    }
}


// MARK: - Event Handling
private extension FeedFilterChipsCollectionViewController {
}


// MARK: - Navigation
private extension FeedFilterChipsCollectionViewController {
}



// MARK: - Layout Composition
extension FeedFilterChipsCollectionViewController {

//    func makeSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
//        let headerSize = NSCollectionLayoutSize(
//            widthDimension: .fractionalWidth(1),
//            heightDimension: .estimated(80)
//        )
//
//        return NSCollectionLayoutBoundarySupplementaryItem(
//            layoutSize: headerSize,
//            elementKind: UICollectionView.elementKindSectionHeader,
//            alignment: .top
//        )
//    }


    func makeLayoutSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = itemContentInsets


        let groupSize = NSCollectionLayoutSize(
            widthDimension: .estimated(108.0),
            heightDimension: .absolute(38.0)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])


        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary

        return section
    }


    func makeSectionProvider() -> UICollectionViewCompositionalLayoutSectionProvider {
        { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            self.makeLayoutSection()
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
extension FeedFilterChipsCollectionViewController {

    func registerViews(for collectionView: UICollectionView) {
        collectionView.register(
            FeedFilterChipCollectionViewCell.nib,
            forCellWithReuseIdentifier: FeedFilterChipCollectionViewCell.reuseID
        )
//
//        collectionView.register(
//            ReusableHeaderView.nib,
//            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
//            withReuseIdentifier: ReusableHeaderView.reuseID
//        )
    }


    func configure(_ collectionView: UICollectionView) {
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
    }
}



// MARK: - Data Source Configuration
extension FeedFilterChipsCollectionViewController {

    func makeDataSource(for collectionView: UICollectionView) -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: makeCellProvider(for: collectionView)
        )

//        dataSource.supplementaryViewProvider = makeSupplementaryViewProvider(for: collectionView)

        return dataSource
    }


    func configureDataSource(for collectionView: UICollectionView) {
        dataSource = makeDataSource(for: collectionView)
        let snapshot = makeSnapshot(withInitial: mediaTypes)

        dataSource.apply(snapshot, animatingDifferences: false)
    }
}


// MARK: - Data Source View Providers
extension FeedFilterChipsCollectionViewController {

    func makeCellProvider(
        for collectionView: UICollectionView
    ) -> DataSource.CellProvider {
        { (collectionView, indexPath, mediaType) -> UICollectionViewCell in
            let section = CollectionViewSection.allCases[indexPath.section]

            switch section {
            case .all:
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CollectionViewCell.reuseID,
                    for: indexPath
                ) as? CollectionViewCell else { preconditionFailure() }

                cell.delegate = self.cellDelegate
                cell.mediaType = mediaType

                return cell
            }
        }
    }


//    func makeSupplementaryViewProvider(
//        for collectionView: UICollectionView
//    ) -> DataSource.SupplementaryViewProvider {
//        {
//            (collectionView: UICollectionView, kind: String, indexPath: IndexPath)
//        -> UICollectionReusableView? in
//            switch kind {
//            case UICollectionView.elementKindSectionHeader:
//                guard let headerView = collectionView.dequeueReusableSupplementaryView(
//                    ofKind: kind,
//                    withReuseIdentifier: ReusableHeaderView.reuseID,
//                    for: indexPath
//                ) as? ReusableHeaderView else { preconditionFailure() }
//
//                let section = CollectionViewSection.allCases[indexPath.section]
//
//                headerView.render(withTitle: section.displayName)
//
//                return headerView
//            default:
//                return UICollectionReusableView()
//            }
//        }
//    }
}


// MARK: - Data Source Snapshot
extension FeedFilterChipsCollectionViewController {

    func update(
        _ snapshot: inout DataSourceSnapshot,
        withNew mediaTypes: [String]
    ) {
        CollectionViewSection.allCases.forEach { section in
            snapshot.appendSections([section])
            snapshot.appendItems(mediaTypes, toSection: section)
        }
    }


    func makeSnapshot(withInitial mediaTypes: [String]) -> DataSourceSnapshot {
        var snapshot = DataSourceSnapshot()
        update(&snapshot, withNew: mediaTypes)

        return snapshot
    }


    func updateSnapshot(
        of dataSource: DataSource,
        withNew mediaTypes: [String],
        animate: Bool = true
    ) {
        let snapshot = makeSnapshot(withInitial: mediaTypes)

        dataSource.apply(snapshot, animatingDifferences: animate)
    }
}


// MARK: - Private Helpers
private extension FeedFilterChipsCollectionViewController {
}


// MARK: - `UICollectionViewDelegate` Methods
extension FeedFilterChipsCollectionViewController {


}

