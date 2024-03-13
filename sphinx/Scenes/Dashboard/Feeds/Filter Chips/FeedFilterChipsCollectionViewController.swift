import UIKit



class FeedFilterChipsCollectionViewController: UICollectionViewController {
    typealias ContentFilterOption = DashboardFeedsContainerViewController.ContentFilterOption
    
    var contentFilterOptions: [ContentFilterOption]!
    var onCellSelected: ((CellDataItemType) -> Void)!
    

    private var currentDataSnapshot: DataSourceSnapshot!
    private var dataSource: DataSource!
    
    private let itemContentInsets = NSDirectionalEdgeInsets.zero
    private let itemHeight = 38.0
}


// MARK: - Instantiation
extension FeedFilterChipsCollectionViewController {

    static func instantiate(
        contentFilterOptions: [CellDataItemType],
        onCellSelected: @escaping ((CellDataItemType) -> Void)  = { _ in }
    ) -> FeedFilterChipsCollectionViewController {
        let viewController = StoryboardScene.Dashboard.feedFilterChipsCollectionViewController.instantiate()

        viewController.contentFilterOptions = contentFilterOptions
        viewController.onCellSelected = onCellSelected

        return viewController
    }
}


// MARK: - Layout & Data Structure
extension FeedFilterChipsCollectionViewController {
    enum CollectionViewSection: Int, CaseIterable {
        case all
    }

    typealias CollectionViewCell = FeedFilterChipCollectionViewCell
    typealias CellDataItemType = ContentFilterOption
    typealias DataSource = UICollectionViewDiffableDataSource<CollectionViewSection, CellDataItemType>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, CellDataItemType>
}



// MARK: - Lifecycle
extension FeedFilterChipsCollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerViews(for: collectionView)
        configure(collectionView)
        configureDataSource(for: collectionView)
    }
}


// MARK: - Layout Composition
extension FeedFilterChipsCollectionViewController {

    var sectionContentInsets: NSDirectionalEdgeInsets {
        let containerHeight = view.frame.height
        let totalSpace = containerHeight - CGFloat(itemHeight)
        
        return .init(
            top: totalSpace / 4,
            leading: 10,
            bottom: totalSpace / 4,
            trailing: 10
        )
    }
    
    
    func makeFilterChipsLayoutSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)


        let groupSize = NSCollectionLayoutSize(
            widthDimension: .estimated(108.0),
            heightDimension: .absolute(CGFloat(itemHeight))
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        
        section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
        section.interGroupSpacing = 8
        section.contentInsets = sectionContentInsets
        
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
        collectionView.collectionViewLayout = makeLayout()
        
        collectionView.backgroundColor = .Sphinx.DashboardHeader
        collectionView.addShadow(
            location: VerticalLocation.bottom,
            opacity: 0.4,
            radius: 3.0
        )
        
        collectionView.isScrollEnabled = false
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
        { [weak self] (collectionView, indexPath, dataItem) -> UICollectionViewCell? in
            guard let self else {
                return nil
            }
            
            guard let cell = collectionView
                .dequeueReusableCell(
                    withReuseIdentifier: CollectionViewCell.reuseID,
                    for: indexPath
                ) as? CollectionViewCell
            else {
                return nil
            }

            cell.filterOption = dataItem

            return cell
        }
    }
}


// MARK: - Data Source Snapshot
extension FeedFilterChipsCollectionViewController {
    
    var sortedContentFilterOptions: [CellDataItemType] {
        contentFilterOptions.sorted(by: { $0.displayOrder < $1.displayOrder })
    }
    
    
    func makeSnapshotForCurrentState() -> DataSourceSnapshot {
        var snapshot = DataSourceSnapshot()

        snapshot.appendSections(CollectionViewSection.allCases)
        snapshot.appendItems(sortedContentFilterOptions, toSection: .all)

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


