import UIKit


class FeedFilterChipsCollectionViewController: UICollectionViewController {

    var mediaTypes: [String] = []
    var activeFilterMediaType: String?
    
    var onCellSelected: ((String) -> Void)!
    

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
extension FeedFilterChipsCollectionViewController {

    static func instantiate(
        mediaTypes: [String],
        activeFilterMediaType: String? = nil,
        onCellSelected: @escaping ((String) -> Void)  = { _ in }
    ) -> FeedFilterChipsCollectionViewController {
        let viewController = StoryboardScene.Dashboard.feedFilterChipsCollectionViewController.instantiate()

        viewController.mediaTypes = mediaTypes
        viewController.activeFilterMediaType = activeFilterMediaType
        viewController.onCellSelected = onCellSelected

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
        collectionView.backgroundColor = .Sphinx.DashboardHeader
        
        registerViews(for: collectionView)
        configure(collectionView)
        configureDataSource(for: collectionView)
    }
}


// MARK: - Layout Composition
extension FeedFilterChipsCollectionViewController {

    func makeFilterChipsLayoutSection() -> NSCollectionLayoutSection {
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
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
        
        return section
    }


    func makeSectionProvider() -> UICollectionViewCompositionalLayoutSectionProvider {
        { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            self.makeFilterChipsLayoutSection()
        }
    }


    func makeLayout() -> UICollectionViewLayout {
        let layoutConfiguration = UICollectionViewCompositionalLayoutConfiguration()        
        let layout = UICollectionViewCompositionalLayout(
            sectionProvider: makeSectionProvider()
        )
        
        layout.configuration = layoutConfiguration

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

        return dataSource
    }


    func configureDataSource(for collectionView: UICollectionView) {
        dataSource = makeDataSource(for: collectionView)
        
        let snapshot = makeSnapshotForCurrentState()
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}


// MARK: - Data Source View Providers
extension FeedFilterChipsCollectionViewController {

    func makeCellProvider(
        for collectionView: UICollectionView
    ) -> DataSource.CellProvider {
        { (collectionView, indexPath, dataItem) -> UICollectionViewCell? in
            guard let cell = collectionView
                .dequeueReusableCell(
                    withReuseIdentifier: CollectionViewCell.reuseID,
                    for: indexPath
                ) as? CollectionViewCell
            else {
                return nil
            }

            cell.mediaType = dataItem
            cell.isMediaTypeActive = dataItem == self.activeFilterMediaType

            return cell
        }
    }
}


// MARK: - Data Source Snapshot
extension FeedFilterChipsCollectionViewController {

    func makeSnapshotForCurrentState() -> DataSourceSnapshot {
        var snapshot = DataSourceSnapshot()

        snapshot.appendSections(CollectionViewSection.allCases)
        snapshot.appendItems(mediaTypes, toSection: .all)

        return snapshot
    }


    func updateSnapshot(shouldAnimate: Bool = true) {
        let snapshot = makeSnapshotForCurrentState()

        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }
}


// MARK: - Private Helpers
private extension FeedFilterChipsCollectionViewController {
}


// MARK: - `UICollectionViewDelegate` Methods
extension FeedFilterChipsCollectionViewController {
    
    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return
        }

        onCellSelected(item)
    }
}


