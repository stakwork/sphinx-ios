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
    @IBOutlet weak var filterChipCollectionViewContainer: UIView!
    @IBOutlet weak var feedContentCollectionViewContainer: UIView!
    
    private var filterChipCollectionViewController: FeedFilterChipsCollectionViewController!
    private var feedContentCollectionViewController: FeedContentCollectionViewController!
    
    
    var contentFilterOptions: [ContentFilterOption] = []
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
        contentFilterOptions = getContentFilterOptions()
        latestPodcastEpisodes = getLatestPodcastEpisodes()
        subscribedPodcastFeeds = getSubscribedPodcastFeeds()
    }
    
    // TODO: These should probably be strongly-typed and dynamically generated in some way.
    private func getContentFilterOptions() -> [ContentFilterOption] {
        ContentFilterOption.allCases
    }
    
    
    private func getLatestPodcastEpisodes() -> [PodcastEpisode] {
        samplePodcastEpisodes
    }
    
    
    private func getSubscribedPodcastFeeds() -> [PodcastFeed] {
        samplePodcastFeeds
    }

    
    private func handleFilterChipCellSelection(_ filterOption: ContentFilterOption) {
        AlertHelper.showAlert(
            title: "Selected Filter Option",
            message: filterOption.titleForDisplay
        )
        
        filterChipCollectionViewController.activeFilterOption = filterOption
        filterChipCollectionViewController.updateSnapshot()
    }
    
    private func handleLatestEpisodeCellSelection(_ podcastEpisode: PodcastEpisode) {
        AlertHelper.showAlert(
            title: "Selected Podcast Episode",
            message: podcastEpisode.title
        )
    }
    
    private func handleLatestFeedCellSelection(_ podcastFeed: PodcastFeed) {
        AlertHelper.showAlert(
            title: "Selected Podcast Feed",
            message: podcastFeed.title
        )
    }
    
    
    private func configureFilterChipCollectionView() {
        filterChipCollectionViewController = FeedFilterChipsCollectionViewController
            .instantiate(
                contentFilterOptions: contentFilterOptions,
                activeFilterOption: contentFilterOptions[1],
                onCellSelected: handleFilterChipCellSelection(_:)
            )
        
        
        addChildVC(
            child: filterChipCollectionViewController,
            container: filterChipCollectionViewContainer
        )
    }
    
    
    private func configureFeedContentCollectionView() {
        feedContentCollectionViewController = FeedContentCollectionViewController
            .instantiate(
                latestPodcastEpisodes: latestPodcastEpisodes,
                subscribedPodcastFeeds: subscribedPodcastFeeds,
                onPodcastEpisodeCellSelected: handleLatestEpisodeCellSelection(_:),
                onPodcastFeedCellSelected: handleLatestFeedCellSelection(_:)
            )
        
        addChildVC(
            child: feedContentCollectionViewController,
            container: feedContentCollectionViewContainer
        )
    }
}


extension FeedsListViewController {
    enum ContentFilterOption {
        case all
        case listen
        case watch
        case read
        case play
    }
}


extension FeedsListViewController.ContentFilterOption {
    
    var titleForDisplay: String {
        switch self {
        case .all:
            return "dashboard.feeds.filters.all".localized
        case .listen:
            return "dashboard.feeds.filters.listen".localized
        case .watch:
            return "dashboard.feeds.filters.watch".localized
        case .read:
            return "dashboard.feeds.filters.read".localized
        case .play:
            return "dashboard.feeds.filters.play".localized
        }
    }
}


extension FeedsListViewController.ContentFilterOption: CaseIterable {}
extension FeedsListViewController.ContentFilterOption: Hashable {}
