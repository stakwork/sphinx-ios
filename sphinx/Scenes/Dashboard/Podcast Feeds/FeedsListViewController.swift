//
//  FeedsListViewController.swift
//  FeedsListViewController
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit



class FeedsListViewController: UIViewController {
    @IBOutlet weak var filterChipCollectionViewContainer: UIView!
    @IBOutlet weak var feedContentCollectionViewContainer: UIView!
    
    private var filterChipCollectionViewController: FeedFilterChipsCollectionViewController!
    private var feedContentCollectionViewController: FeedContentCollectionViewController!
    
    
    var contentFilterOptions: [ContentFilterOption] = []
    var activeFilterOption: ContentFilterOption = .allContent
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
    
    
    private func getContentFilterOptions() -> [ContentFilterOption] {
        ContentFilterOption
            .allCases
            .map {
                var startingOption = $0
                
                if startingOption.id == activeFilterOption.id {
                    startingOption.isActive = true
                }
                
                return startingOption
            }
    }
    
    
    private func getLatestPodcastEpisodes() -> [PodcastEpisode] {
        Self.samplePodcastEpisodes
    }
    
    
    private func getSubscribedPodcastFeeds() -> [PodcastFeed] {
        Self.samplePodcastFeeds
    }

    
    private func handleFilterChipActivation(
        _ filterOption: ContentFilterOption
    ) {
        var updatedOption = filterOption
        updatedOption.isActive = true
        activeFilterOption = updatedOption

        let newOptions = ContentFilterOption
            .allCases
            .filter { $0.id != activeFilterOption.id }
            + [activeFilterOption]
        
        filterChipCollectionViewController.contentFilterOptions = newOptions
        filterChipCollectionViewController.updateSnapshot()
    }
    
    
    private func handleLatestEpisodeCellSelection(_ podcastEpisode: PodcastEpisode) {
        AlertHelper.showAlert(
            title: "Selected Podcast Episode",
            message: podcastEpisode.title ?? "Unknown Title"
        )
    }
    
    private func handleLatestFeedCellSelection(_ podcastFeed: PodcastFeed) {
        AlertHelper.showAlert(
            title: "Selected Podcast Feed",
            message: podcastFeed.title ?? "Unknown Title"
        )
    }
    
    
    private func configureFilterChipCollectionView() {
        filterChipCollectionViewController = FeedFilterChipsCollectionViewController
            .instantiate(
                contentFilterOptions: Array(contentFilterOptions),
                onCellSelected: handleFilterChipActivation(_:)
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
    
    static let samplePodcastFeeds: [PodcastFeed] = {
        let managedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        let feed1 = PodcastFeed(context: managedObjectContext)
        
        feed1.id = 1
        feed1.title = "Sample Podcast 1"
        feed1.author = "Satoshi Nakamoto"
        feed1.podcastDescription = "Sample Podcast Description 1"
        feed1.imageURLPath = "cashAppIcon"
        feed1.chat = nil
        feed1.destinations = nil
        feed1.episodes = []
        feed1.model = nil
        
        let feed2 = PodcastFeed(context: managedObjectContext)
        
        feed2.id = 2
        feed2.title = "Sample Podcast 2"
        feed2.author = "Satoshi Nakamoto"
        feed2.imageURLPath = "appPinIcon"
        feed2.podcastDescription = "Sample Podcast Description 2"
        feed2.chat = nil
        feed2.destinations = nil
        feed2.episodes = []
        feed2.model = nil
        
        let feed3 = PodcastFeed(context: managedObjectContext)
        
        feed3.id = 3
        feed3.title = "Sample Podcast 3"
        feed3.author = "Satoshi Nakamoto"
        feed2.imageURLPath = "welcomeLogo"
        feed3.podcastDescription = "Sample Podcast Description 3"
        feed3.chat = nil
        feed3.destinations = nil
        feed3.episodes = []
        feed3.model = nil
        
        
        return [
            feed1,
            feed2,
            feed3,
        ]
    }()
    
    
    static let samplePodcastEpisodes: [PodcastEpisode] = {
        let managedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        let episode1 = PodcastEpisode(context: managedObjectContext)
        
        episode1.id = 1
        episode1.title = "Sample Episode 1"
        episode1.imageURLPath = "cashAppIcon"
        episode1.episodeDescription = "Sample Episode Description 1"
        
        let episode2 = PodcastEpisode(context: managedObjectContext)
        
        episode2.id = 2
        episode2.title = "Sample Episode 2"
        episode2.imageURLPath = "appPinIcon"
        episode2.episodeDescription = "Sample Episode Description 2"
        
        let episode3 = PodcastEpisode(context: managedObjectContext)
        
        episode3.id = 3
        episode3.title = "Sample Episode 3"
        episode3.imageURLPath = "welcomeLogo"
        episode3.episodeDescription = "Sample Episode Description 3"
        
        
        return [
            episode1,
            episode2,
            episode3,
        ]
    }()
}
