// VideoFeedEpisodePlayerCollectionViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    

import UIKit

protocol VideoFeedEpisodePlayerCollectionViewControllerDelegate{
    func requestPlay()
}

class VideoFeedEpisodePlayerCollectionViewController: UICollectionViewController {
    
    var videoPlayerEpisode: Video!
    var videoFeedEpisodes: [Video]!

    var onVideoEpisodeCellSelected: ((String) -> Void)!
    var onFeedSubscriptionSelected: (() -> Void)!
    var onFeedSubscriptionCancellationSelected: (() -> Void)!
    
    private var currentDataSnapshot: DataSourceSnapshot!
    private var dataSource: DataSource!
    let downloadService : DownloadService = DownloadService.sharedInstance
    
    weak var boostDelegate: CustomBoostDelegate?
    var delegate:VideoFeedEpisodePlayerCollectionViewControllerDelegate? = nil
}


// MARK: -  Static Methods
extension VideoFeedEpisodePlayerCollectionViewController {
    
    static func instantiate(
        videoPlayerEpisode: Video,
        videoFeedEpisodes: [Video],
        boostDelegate: CustomBoostDelegate?,
        onVideoEpisodeCellSelected: @escaping ((String) -> Void) = { _ in },
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
    typealias FeedEpisodeCell = RecommendationItemWUnifiedViewCollectionViewCell
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
            heightDimension: .estimated(200.0)
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
        
        downloadService.setDelegate(
            delegate: self,
            forKey: DownloadServiceDelegateKeys.VideoFeedDelegate
        )
    }
}


// MARK: - Data Source View Providers
extension VideoFeedEpisodePlayerCollectionViewController {

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
                
                episodeCell.configure(withVideoEpisode: videoEpisode, and: self)
                
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

//MARK: Unified View Delegate
extension VideoFeedEpisodePlayerCollectionViewController: FeedItemRowDelegate, PodcastEpisodesDSDelegate {
    func didDismiss() {}
    
    func shouldShowDescription(episode: PodcastEpisode,cell:UITableViewCell) {}
    
    func shouldShowDescription(video: Video) {
        if let feed = video.videoFeed{
            let vc = ItemDescriptionViewController.instantiate(videoFeed: feed, video: video, index: 0)
            vc.delegate = self
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func didTapForDescriptionAt(episode: PodcastEpisode,cell:UITableViewCell) {}
    
    
    func shouldStartDownloading(episode: PodcastEpisode, cell: UITableViewCell)  {}
    func shouldDeleteFile(episode: PodcastEpisode, cell: UITableViewCell)  {}
    func shouldShowMore(episode: PodcastEpisode, cell: UITableViewCell)  {}
    func shouldShare(episode: PodcastEpisode)  {}
    
    func shouldStartDownloading(episode: PodcastEpisode, cell: UICollectionViewCell)  {}
    func shouldDeleteFile(episode: PodcastEpisode, cell: UICollectionViewCell)  {}
    
    func shouldShare(video: Video) {
        
        self.shareTapped(video: video)
    }
    
    func shouldShowMore(episode: PodcastEpisode, cell: UICollectionViewCell) {
        if let indexPath = collectionView.indexPath(for: cell) {
            let vc = FeedItemDetailVC.instantiate(episode: episode, delegate: self, indexPath: indexPath)
            self.present(vc, animated: true)
        }
    }
    
    func shouldShowMore(video: Video, cell: UICollectionViewCell) {
        if let indexPath = collectionView.indexPath(for: cell) {
            let vc = FeedItemDetailVC.instantiate(video: video, delegate: self, indexPath: indexPath)
            self.present(vc, animated: true)
        }
    }
    
    func didTapEpisodeWith(episodeId: String) {}
    
    func downloadTapped(_ indexPath: IndexPath, episode: PodcastEpisode) {}
    
    func deleteTapped(_ indexPath: IndexPath, episode: PodcastEpisode) {}
    
    func shouldToggleTopView(show: Bool) {}
    
    func showEpisodeDetails(episode: PodcastEpisode, indexPath: IndexPath) {}

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
extension VideoFeedEpisodePlayerCollectionViewController:ItemDescriptionViewControllerDelegate {

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
            self.onVideoEpisodeCellSelected(episode.id)
        }
    }
    
    func shouldDismissAndPlayVideo(video: Video) {
        self.onVideoEpisodeCellSelected(video.id)
        self.delegate?.requestPlay()
    }
    
    func shouldDismissAndPlayVideo(episodeAsVideo: PodcastEpisode) {}
    
    func didDismissDescriptionView(index:Int) {
        
    }
    
    func shouldDownloadVideo(video: Video) {
        downloadService.startDownload(video: video)
        refreshCellForVideo(video: video)
    }

    func refreshCellForVideo(video:Video){
        // Update the data source snapshot with the new state
        var snapshot = dataSource.snapshot()
        if let _ = videoFeedEpisodes.firstIndex(of: video) {
            let itemIdentifier = DataSourceItem.videoFeedEpisode(video)
            snapshot.reloadItems([itemIdentifier])
            dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
    
}


extension VideoFeedEpisodePlayerCollectionViewController : DownloadServiceDelegate{
    func shouldReloadRowFor(video: VideoDownload) {
        //TODO: reload row
        print("shouldReloadRowFor from VideoFeedEpisodePlayerCollectionViewController")
        refreshCellForVideo(video: video.video)
    }
}
