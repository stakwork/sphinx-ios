import UIKit


class ChatsCollectionViewController: UICollectionViewController {
    
    var chatListObjects: [ChatListCommonObject] = []
    var onChatSelected: ((ChatListCommonObject) -> Void)?
    var onContentScrolled: ((UIScrollView) -> Void)?
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
        chatListObjects: [ChatListCommonObject] = [],
        onChatSelected: ((ChatListCommonObject) -> Void)? = nil,
        onContentScrolled: ((UIScrollView) -> Void)? = nil,
        onRefresh: ((UIRefreshControl) -> Void)? = nil
    ) -> ChatsCollectionViewController {
        let viewController = StoryboardScene.Dashboard.chatsCollectionViewController.instantiate()
        
        viewController.chatListObjects = chatListObjects
        viewController.onChatSelected = onChatSelected
        viewController.onContentScrolled = onContentScrolled
        viewController.onRefresh = onRefresh

        return viewController
    }
}


// MARK: - Layout & Data Structure
extension ChatsCollectionViewController {
    enum CollectionViewSection: Int, CaseIterable {
        case all
    }
    
    struct DataSourceItem: Hashable {
        
        var objectId: String
        var messageId: Int?
        var messageSeen: Bool
        var contactStatus: Int?
        var inviteStatus: Int?
        var muted: Bool

        init(
            objectId: String,
            messageId: Int?,
            messageSeen: Bool,
            contactStatus: Int?,
            inviteStatus: Int?,
            muted: Bool
        )
        {
            self.objectId = objectId
            self.messageId = messageId
            self.messageSeen = messageSeen
            self.contactStatus = contactStatus
            self.inviteStatus = inviteStatus
            self.muted = muted
        }
        
        static func == (lhs: DataSourceItem, rhs: DataSourceItem) -> Bool {
            let isEqual =
                lhs.objectId == rhs.objectId &&
                lhs.messageId == rhs.messageId &&
                lhs.messageSeen == rhs.messageSeen &&
                lhs.contactStatus == rhs.contactStatus &&
                lhs.inviteStatus == rhs.inviteStatus &&
                lhs.muted == rhs.muted
            
            return isEqual
         }

        func hash(into hasher: inout Hasher) {
            hasher.combine(objectId)
            hasher.combine(messageId)
            hasher.combine(messageSeen)
            hasher.combine(contactStatus)
            hasher.combine(inviteStatus)
            hasher.combine(muted)
        }
    }


    typealias CollectionViewCell = ChatListCollectionViewCell
    typealias CellDataItem = DataSourceItem
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
        addTableBottomInset(for: collectionView)
    }
    
    func addTableBottomInset(for collectionView: UICollectionView) {
        let windowInsets = getWindowInsets()
        let bottomBarHeight:CGFloat = 64
        
        collectionView.contentInset.bottom = bottomBarHeight + windowInsets.bottom
        collectionView.verticalScrollIndicatorInsets.bottom = bottomBarHeight + windowInsets.bottom
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
            heightDimension: .absolute(Constants.kChatListRowHeight)
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
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onContentScrolled?(scrollView)
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
        
        updateSnapshot()
    }
}


// MARK: - Data Source View Providers
extension ChatsCollectionViewController {

    func makeCellProvider(for collectionView: UICollectionView) -> DataSource.CellProvider {
        { (collectionView, indexPath, chatItem) -> UICollectionViewCell? in
            let section = CollectionViewSection.allCases[indexPath.section]

            switch section {
            case .all:
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CollectionViewCell.reuseID,
                    for: indexPath
                ) as? CollectionViewCell else { return nil }

                cell.chatListObject = self.chatListObjects[indexPath.row]

                return cell
            }
        }
    }


    func makeSupplementaryViewProvider(for collectionView: UICollectionView) -> DataSource.SupplementaryViewProvider {
        return {
            (collectionView: UICollectionView, kind: String, indexPath: IndexPath)
        -> UICollectionReusableView in
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

    func updateSnapshot() {
        var snapshot = DataSourceSnapshot()

        snapshot.appendSections(CollectionViewSection.allCases)

        let items = chatListObjects.map {
            
            DataSourceItem(
                objectId: $0.getObjectId(),
                messageId: $0.lastMessage?.id,
                messageSeen: $0.lastMessage?.seen ?? false,
                contactStatus: $0.getContactStatus(),
                inviteStatus: $0.getInviteStatus(),
                muted: $0.isMuted()
            )
            
        }

        snapshot.appendItems(items, toSection: .all)
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}


// MARK: - Event Handling
private extension ChatsCollectionViewController {
}


// MARK: - Private Helpers
private extension ChatsCollectionViewController {
}


// MARK: - `UICollectionViewDelegate`
extension ChatsCollectionViewController {
    
    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let selectedChatObject = chatListObjects[indexPath.row]
        onChatSelected?(selectedChatObject)
    }
}
