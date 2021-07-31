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
    
    
    var contentFilterOptions: Set<ContentFilterOption> = .init(ContentFilterOption.allCases)
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
        latestPodcastEpisodes = getLatestPodcastEpisodes()
        subscribedPodcastFeeds = getSubscribedPodcastFeeds()
    }
    
    private func getContentFilterOptions() -> [ContentFilterOption] {
        Array(ContentFilterOption.allCases)
    }
    
    
    private func getLatestPodcastEpisodes() -> [PodcastEpisode] {
        samplePodcastEpisodes
    }
    
    
    private func getSubscribedPodcastFeeds() -> [PodcastFeed] {
        samplePodcastFeeds
    }

    
    private func handleFilterChipCellSelection(_ filterOption: ContentFilterOption) {
        var updatedOption = filterOption
        updatedOption.isActive.toggle()
        
        var newOptions = Set(ContentFilterOption.allCases)
        newOptions.remove(filterOption)
        newOptions.insert(updatedOption)
        
        filterChipCollectionViewController.contentFilterOptions = newOptions
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
    struct ContentFilterOption {
        let id = UUID()
        
        var titleForDisplay: String
        var isActive: Bool = false
        var displayOrder: Int
        
        static var all: Self = .init(
            titleForDisplay: "dashboard.feeds.filters.all".localized,
            displayOrder: 1
        )
        static var listen: Self = .init(
            titleForDisplay: "dashboard.feeds.filters.listen".localized,
            displayOrder: 2
        )
        static var watch: Self = .init(
            titleForDisplay: "dashboard.feeds.filters.watch".localized,
            displayOrder: 3
        )
        static var read: Self = .init(
            titleForDisplay: "dashboard.feeds.filters.read".localized,
            displayOrder: 4
        )
        static var play: Self = .init(
            titleForDisplay: "dashboard.feeds.filters.play".localized,
            displayOrder: 5
        )
    }
}


extension FeedsListViewController.ContentFilterOption: CaseIterable {
    static var allCases: [Self] {
        [
        .all,
        .listen,
        .watch,
        .read,
        .play,
        ]
    }
}

extension FeedsListViewController.ContentFilterOption: Hashable {}
extension FeedsListViewController.ContentFilterOption: Identifiable {}
