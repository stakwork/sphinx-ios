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

class FeedsListViewController: UIViewController {
    @IBOutlet weak var feedFilterChipCollectionView: UICollectionView!
    @IBOutlet weak var feedContentCollectionView: UICollectionView!
    
    var feedFilterChipDataSource: FeedFilterChipDataSource!
    var feedContentDataSource: FeedContentDataSource!
    
    // TODO: These should probably be strongly-typed and dynamically generated in some way.
    var mediaTypes: [String] = []
    
    var newEpisodePodcastFeeds: [PodcastFeed] = []
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
        newEpisodePodcastFeeds = getNewEpisodePodcastFeeds()
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
    
    
    private func getNewEpisodePodcastFeeds() -> [PodcastFeed] {
        samplePodcastFeeds
    }
    
    
    private func getSubscribedPodcastFeeds() -> [PodcastFeed] {
        samplePodcastFeeds
    }
    
    
    
    private func configureFilterChipCollectionView() {
        feedFilterChipCollectionView.registerCell(FeedFilterChipCollectionViewCell.self)
        
        feedFilterChipDataSource = FeedFilterChipDataSource(
            collectionView: feedFilterChipCollectionView,
            mediaTypes: mediaTypes,
            cellDelegate: self
        )
        
        feedFilterChipCollectionView.delegate = feedFilterChipDataSource
        feedFilterChipCollectionView.dataSource = feedFilterChipDataSource
        feedFilterChipCollectionView.reloadData()
    }
    
    
    private func configureFeedContentCollectionView() {
        feedContentCollectionView.registerCell(PodcastFeedCollectionViewCell.self)
        
        let nib = UINib(
            nibName: String(describing: PodcastFeedCollectionViewSectionHeader.self),
            bundle: .main
        )
        
        feedContentCollectionView.register(
            nib,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "PodcastFeedCollectionViewSectionHeader"
        )
        
        feedContentDataSource = FeedContentDataSource(
            collectionView: feedContentCollectionView,
            newEpisodePodcastFeeds: newEpisodePodcastFeeds,
            subscribedPodcastFeeds: subscribedPodcastFeeds,
            cellDelegate: self
        )
        
        feedContentCollectionView.delegate = feedContentDataSource
        feedContentCollectionView.dataSource = feedContentDataSource
        feedContentCollectionView.reloadData()
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


extension FeedsListViewController: PodcastFeedCollectionViewCellDelegate {
    
    func collectionViewCell(
        _ cell: PodcastFeedCollectionViewCell,
        didSelect podcastFeed: PodcastFeed
    ) {
        AlertHelper.showAlert(
            title: "Selected Podcast Feed",
            message: podcastFeed.title ?? "Title Not Found"
        )
    }
}
