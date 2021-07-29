//
//  FeedsListViewController.swift
//  FeedsListViewController
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit

private let samplePodcastFeeds: [PodcastFeed] = [
    PodcastFeed(
        chatId: 1,
        id: 1,
        title: "Sample Podcast 1",
        description: "Sample Podcast 1 Description",
        author: "Satoshi Nakamoto",
        image: "cashAppIcon",
        model: nil,
        episodes: [],
        destinations: []
    ),
    PodcastFeed(
        chatId: 2,
        id: 2,
        title: "Sample Podcast 2",
        description: "Sample Podcast 1 Description",
        author: "Satoshi Nakamoto",
        image: "cashAppIcon",
        model: nil,
        episodes: [],
        destinations: []
    ),
    PodcastFeed(
        chatId: 3,
        id: 3,
        title: "Sample Podcast 3",
        description: "Sample Podcast 3 Description",
        author: "Satoshi Nakamoto",
        image: "cashAppIcon",
        model: nil,
        episodes: [],
        destinations: []
    ),
]


private let samplePodcastEpisodes: [PodcastEpisode] = [
    PodcastEpisode(
        id: 1,
        title: "Sample Episode 1",
        description: "Sample Episode 1 Description",
        url: "",
        image: "cashAppIcon",
        link: "",
        downloaded: false
    ),
    PodcastEpisode(
        id: 2,
        title: "Sample Episode 2",
        description: "Sample Episode 2 Description",
        url: "",
        image: "cashAppIcon",
        link: "",
        downloaded: false
    ),
    PodcastEpisode(
        id: 3,
        title: "Sample Episode 3",
        description: "Sample Episode 3 Description",
        url: "",
        image: "cashAppIcon",
        link: "",
        downloaded: false
    ),
]


class FeedsListViewController: UIViewController {
//    @IBOutlet weak var feedFilterChipCollectionView: UICollectionView!
//    @IBOutlet weak var feedContentCollectionView: UICollectionView!
    
    @IBOutlet weak var filterChipCollectionViewContainer: UIView!
//    @IBOutlet weak var latestEpisodesCollectionViewContainer: UIView!
    @IBOutlet weak var feedContentCollectionViewContainer: UIView!
    
    
//    var feedFilterChipDataSource: FeedFilterChipDataSource!
//    var feedContentDataSource: FeedContentDataSource!
    
    // TODO: These should probably be strongly-typed and dynamically generated in some way.
    var mediaTypes: [String] = []
    
    var latestPodcastEpisodes: [PodcastEpisode] = []
    var subscribedPodcastFeeds: [PodcastFeed] = []
    
    
    static func instantiate() -> FeedsListViewController {
        let viewController = StoryboardScene.Dashboard.feedsListViewController.instantiate()
        
        return viewController
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()
        configureFilterChipCollectionView()
        configureFeedContentCollectionView()
    }
}


// MARK: -  Private Helpers

extension FeedsListViewController {
    
    private func loadData() {
        mediaTypes = getFeedMediaTypes()
        latestPodcastEpisodes = getLatestPodcastEpisodes()
        subscribedPodcastFeeds = getSubscribedPodcastFeeds()
    }
    
    
    // TODO: These should probably be strongly-typed and dynamically generated in some way.
    private func getFeedMediaTypes() -> [String] {
        [
            "All",
            "Listen",
            "Watch",
            "Read",
            "Play",
        ]
    }
    
    
    private func getLatestPodcastEpisodes() -> [PodcastEpisode] {
        samplePodcastEpisodes
    }
    
    
    private func getSubscribedPodcastFeeds() -> [PodcastFeed] {
        samplePodcastFeeds
    }
    
    
    private func handleContentCellSelection(cellItem: DashboardPodcastCollectionViewItem) {
        AlertHelper.showAlert(title: "Selected Content Item", message: cellItem.title)
    }
    
    
    
    
    private func configureFilterChipCollectionView() {
//        feedFilterChipCollectionView.registerCell(FeedFilterChipCollectionViewCell.self)
//
//        feedFilterChipDataSource = FeedFilterChipDataSource(
//            collectionView: feedFilterChipCollectionView,
//            mediaTypes: mediaTypes,
//            cellDelegate: self
//        )
//
//        feedFilterChipCollectionView.delegate = feedFilterChipDataSource
//        feedFilterChipCollectionView.dataSource = feedFilterChipDataSource
//        feedFilterChipCollectionView.reloadData()

        
        let filterChipCollectionViewController = FeedFilterChipsCollectionViewController
            .instantiate(
                mediaTypes: mediaTypes,
                cellDelegate: self
            )
        
//        let filterChipCollectionViewController = FeedFilterChipsCollectionViewController(
//            mediaTypes: mediaTypes,
//            cellDelegate: self
//        )
        
//        let filterChipCollectionViewController = FeedFilterChipsCollectionViewController()
//
//        filterChipCollectionViewController.mediaTypes = mediaTypes
//        filterChipCollectionViewController.cellDelegate = self
        
        addChildVC(
            child: filterChipCollectionViewController,
            container: filterChipCollectionViewContainer
        )
    }
    
    
    private func configureFeedContentCollectionView() {
        let feedContentCollectionViewController = FeedContentCollectionViewController
            .instantiate(
                latestPodcastEpisodes: latestPodcastEpisodes,
                subscribedPodcastFeeds: subscribedPodcastFeeds,
                onItemSelected: handleContentCellSelection(cellItem:)
            )
        
//        let feedContentCollectionViewController = FeedContentCollectionViewController(
//            newEpisodePodcastFeeds: newEpisodePodcastFeeds,
//            subscribedPodcastFeeds: subscribedPodcastFeeds,
//            cellDelegate: self
//        )
        
//        let feedContentCollectionViewController = FeedContentCollectionViewController()
//
//        feedContentCollectionViewController.newEpisodePodcastFeeds = newEpisodePodcastFeeds
//        feedContentCollectionViewController.subscribedPodcastFeeds = subscribedPodcastFeeds
//        feedContentCollectionViewController.cellDelegate = self
        
        addChildVC(
            child: feedContentCollectionViewController,
            container: feedContentCollectionViewContainer
        )
    }

}


extension FeedsListViewController: FeedFilterChipCollectionViewCellDelegate {
    
    func collectionViewCell(
        _ cell: FeedFilterChipCollectionViewCell,
        didSelectMediaType mediaType: String
    ) {
        AlertHelper.showAlert(title: "Selected Media Type", message: mediaType)
    }
}


//extension FeedsListViewController: PodcastFeedCollectionViewCellDelegate {
//    func collectionViewCell(
//        _ cell: PodcastFeedCollectionViewCell,
//        didSelect podcastFeed: PodcastFeed
//    ) {
//        AlertHelper.showAlert(
//            title: "Selected Podcast Feed",
//            message: podcastFeed.title
//        )
//    }
//}
