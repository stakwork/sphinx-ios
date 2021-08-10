import UIKit


class ChatsCollectionViewController: UICollectionViewController {
    var chats: [Chat] = []
    var onChatSelected: ((Chat) -> Void)?
    var onRefresh: ((UIRefreshControl) -> Void)?


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
extension ChatsCollectionViewController {

    static func instantiate(
        chats: [Chat] = [],
        onChatSelected: ((Chat) -> Void)? = nil,
        onRefresh: ((UIRefreshControl) -> Void)? = nil
    ) -> ChatsCollectionViewController {
        let viewController = StoryboardScene.Dashboard.chatsCollectionViewController.instantiate()
        
        viewController.chats = chats
        viewController.onChatSelected = onChatSelected
        viewController.onRefresh = onRefresh

        return viewController
    }
}


// MARK: - Layout & Data Structure
extension ChatsCollectionViewController {
    enum CollectionViewSection: Int, CaseIterable {
        case all
    }

    typealias CollectionViewCell = ContactChatListCollectionViewCell
    typealias CellDataItem = Chat
    typealias DataSource = UICollectionViewDiffableDataSource<CollectionViewSection, CellDataItem>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, CellDataItem>
}


// MARK: - Lifecycle
extension ChatsCollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        registerViews(for: collectionView)
        configure(collectionView)
        configureDataSource(for: collectionView)
    }
}


// MARK: - Event Handling
private extension ChatsCollectionViewController {
    
    @objc func handleRefreshOnPull(refreshControl: UIRefreshControl) {
        onRefresh?(refreshControl)
    }
}


// MARK: - Navigation
private extension ChatsCollectionViewController {
}



// MARK: - Layout Composition
extension ChatsCollectionViewController {

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


    func makeListSection() -> NSCollectionLayoutSection {
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

        return section
    }


    func makeSectionProvider() -> UICollectionViewCompositionalLayoutSectionProvider {
        { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            switch CollectionViewSection(rawValue: sectionIndex) {
            case .all:
                return self.makeListSection()
            case nil:
                return nil
            }
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
extension ChatsCollectionViewController {

    func registerViews(for collectionView: UICollectionView) {
        collectionView.register(
            CollectionViewCell.nib,
            forCellWithReuseIdentifier: CollectionViewCell.reuseID
        )
    }


    func configure(_ collectionView: UICollectionView) {
        collectionView.collectionViewLayout = makeLayout()

        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = true
        collectionView.backgroundColor = .Sphinx.DashboardHeader
        
        collectionView.delegate = self
        
        collectionView.refreshControl = UIRefreshControl()
        collectionView.refreshControl!.addTarget(
            self,
            action: #selector(handleRefreshOnPull(refreshControl:)),
            for: .valueChanged
        )
    }
}



// MARK: - Data Source Configuration
extension ChatsCollectionViewController {

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
extension ChatsCollectionViewController {

    func makeCellProvider(for collectionView: UICollectionView) -> DataSource.CellProvider {
        { (collectionView, indexPath, chat) -> UICollectionViewCell? in
            let section = CollectionViewSection.allCases[indexPath.section]

            switch section {
            case .all:
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CollectionViewCell.reuseID,
                    for: indexPath
                ) as? CollectionViewCell else { return nil }

                cell.chat = chat

                return cell
            }
        }
    }


    func makeSupplementaryViewProvider(for collectionView: UICollectionView) -> DataSource.SupplementaryViewProvider {
        return {
            (collectionView: UICollectionView, kind: String, indexPath: IndexPath)
        -> UICollectionReusableView? in
            switch kind {
            case UICollectionView.elementKindSectionHeader:
                return UICollectionReusableView()
            default:
                return UICollectionReusableView()
            }
        }
    }
}


// MARK: - Data Source Snapshot
extension ChatsCollectionViewController {

    func makeSnapshotForCurrentState() -> DataSourceSnapshot {
        var snapshot = DataSourceSnapshot()

        snapshot.appendSections(CollectionViewSection.allCases)
        snapshot.appendItems(chats, toSection: .all)

        return snapshot
    }


    func updateSnapshot(shouldAnimate: Bool = true) {
        let snapshot = makeSnapshotForCurrentState()

        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }
}


// MARK: - Event Handling
private extension ChatsCollectionViewController {
}


// MARK: - Private Helpers
private extension ChatsCollectionViewController {
}


// MARK: - `UICollectionViewDelegate` Methods
extension ChatsCollectionViewController {
    
    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let chat = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        onChatSelected?(chat)
    }
}
