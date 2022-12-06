//
//  RecommendationFeedPlayerContainerViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/12/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

protocol CommonPlayerViewController: UIViewController {
    var recommendation: RecommendationResult! { get set }
}

class RecommendationFeedPlayerContainerViewController: UIViewController {
    
    @IBOutlet weak var playerContainerView: UIView!
    @IBOutlet weak var recommendationDetailsView: RecommendationDetailsView!
    @IBOutlet weak var collectionViewContainer: UIView!
    
    static let kRecommendationPodcastId = "Recommendations-Feed"
    
    var recommendations: [RecommendationResult]!
    
    var recommendation: RecommendationResult! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard
                    let self = self,
                    let recommendation = self.recommendation
                else { return }
                
                self.collectionViewController
                    .updateWithNew(recommendation: recommendation)
                
                self.recommendationDetailsView.configure(
                    withRecommendation: recommendation,
                    podcast: self.podcast,
                    andDelegate: self
                )
                
                self.youtubeVideoPlayerViewController.videoItem = recommendation
                self.podcastPlayerViewController.podcastItem = recommendation
            }
        }
    }
    
    internal lazy var podcast: PodcastFeed = {
        let podcast = PodcastFeed(nil, RecommendationFeedPlayerContainerViewController.kRecommendationPodcastId, false)
        
        podcast.title = "Recommendations"
        podcast.podcastDescription = "Feed Recommendations"
        
        var episodes: [PodcastEpisode] = []
        
        for item in recommendations {
            if (item.isPodcast) {
                let episode = PodcastEpisode(nil, item.id)
                episode.title = item.title
                episode.episodeDescription = item.subtitle
                episode.datePublished = Date(timeIntervalSince1970: TimeInterval(item.date ?? 0))
                episode.dateUpdated = Date(timeIntervalSince1970: TimeInterval(item.date ?? 0))
                episode.urlPath = item.link
                episode.imageURLPath = item.imageURLPath
                episode.linkURLPath = item.link
                episode.feed = podcast
                
                episodes.append(episode)
            }
        }
        
        podcast.episodes = episodes
        
        return podcast
    }()

    internal lazy var youtubeVideoPlayerViewController: YoutubeRecommendationFeedPlayerViewController = {
        YoutubeRecommendationFeedPlayerViewController.instantiate(videoItem: recommendation)
    }()
    
    internal lazy var podcastPlayerViewController: PodcastRecommendationFeedPlayerViewController = {
        PodcastRecommendationFeedPlayerViewController.instantiate(podcastItem: recommendation, andPodcast: podcast)
    }()
    
    internal lazy var collectionViewController: RecommendationFeedItemsCollectionViewController = {
        RecommendationFeedItemsCollectionViewController.instantiate(
            recommendation: recommendation,
            recommendations: recommendations,
            onRecommendationCellSelected: handleRecommendationCellSelection(_:)
        )
    }()
    
    var playerHelper: PodcastPlayerHelper = PodcastPlayerHelper.sharedInstance
}

// MARK: -  Static Methods
extension RecommendationFeedPlayerContainerViewController {
    
    static func instantiate(
        recommendations: [RecommendationResult],
        recommendation: RecommendationResult
    ) -> RecommendationFeedPlayerContainerViewController {
        let viewController = StoryboardScene
            .Recommendations
            .recommendationFeedPlayerContainerViewController
            .instantiate()
        
        viewController.recommendations = recommendations
        viewController.recommendation = recommendation
    
        return viewController
    }
}

// MARK: -  Lifecycle
extension RecommendationFeedPlayerContainerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setPlayingEpisode()
        configurePlayerView()
        configureCollectionView()
        
        if playerHelper.isPlaying(podcast.feedID) {
            return
        }
        loadAndPlayEpisode(recommendationId: recommendation.id)
    }
}

// MARK: -  Private Helpers
extension RecommendationFeedPlayerContainerViewController {
    
    private func setPlayingEpisode() {
        if playerHelper.isPlaying(podcast.feedID) {
            if let playingEpisodeId = podcast.getCurrentEpisode()?.itemID,
                let recommendation = recommendations.filter({ $0.id == playingEpisodeId }).first {
                
                self.recommendation = recommendation
            }
        }
    }
    
    private func configurePlayerView() {
        if recommendation.isPodcast {
            addPodcastPlayerView()
        } else if recommendation.isYoutubeVideo {
            addVideoPlayerView()
        }
    }
    
    private func addVideoPlayerView() {
        removeChildVC(child: podcastPlayerViewController)
        
        addChildVC(
            child: youtubeVideoPlayerViewController,
            container: playerContainerView
        )
        
        playerHelper.stopPlaying()
        playerHelper.removeFromDelegatesWith(key: PodcastPlayerHelper.DelegateKeys.recommendationsPlayer.rawValue)
    }
    
    private func addPodcastPlayerView() {
        removeChildVC(child: youtubeVideoPlayerViewController)
        
        addChildVC(
            child: podcastPlayerViewController,
            container: playerContainerView
        )
        
        playerHelper.addDelegate(
            self,
            withKey: PodcastPlayerHelper.DelegateKeys.recommendationsPlayer.rawValue
        )

    }

    private func configureCollectionView() {
        addChildVC(
            child: collectionViewController,
            container: collectionViewContainer
        )
    }
}

// MARK: -  Action Handling
extension RecommendationFeedPlayerContainerViewController {
    
    private func handleRecommendationCellSelection(
        _ recommendationId: String
    ) {
        guard
            let recommendation = recommendations.filter({ $0.id == recommendationId }).first
        else {
            preconditionFailure()
        }
        
        self.recommendation = recommendation
        
        configurePlayerView()
        
        loadAndPlayEpisode(recommendationId: recommendationId)
    }
    
    func loadAndPlayEpisode(recommendationId: String) {
        if let index = podcast.episodesArray.firstIndex(where: { $0.itemID == recommendationId }) {
            didTapEpisodeAt(index: index)
        }
    }
    
    func didTapEpisodeAt(index: Int) {
        playerHelper.prepareEpisodeWith(
            index: index,
            in: podcast,
            autoPlay: true,
            completion: {
                self.configureControls()
            }
        )
        podcastPlayerViewController.showTimeInfo()
    }
}

// MARK: -  Picker Delegate
extension RecommendationFeedPlayerContainerViewController : RecommendationPlayerViewDelegate, PickerViewDelegate {
    func shouldShowSpeedPicker() {
        let selectedValue = podcast.playerSpeed
        let pickerVC = PickerViewController.instantiate(values: ["0.5", "0.8", "1.0", "1.2", "1.5", "2.1"], selectedValue: "\(selectedValue)", delegate: self)
        self.present(pickerVC, animated: false, completion: nil)
    }
    
    func didSelectValue(value: String) {
        if let floatValue = Float(value), floatValue >= 0.5 && floatValue <= 2.1 {
            playerHelper.changeSpeedTo(value: floatValue, on: podcast)
            configureControls()
        }
    }
    
    func configureControls(
        playing: Bool? = nil
    ) {
        recommendationDetailsView.configureControls(
            playing: playing ?? playerHelper.isPlaying(podcast.feedID),
            speedDescription: podcast.playerSpeed.speedDescription
        )
    }
}

// MARK: -  Podcast Player Delegate
extension RecommendationFeedPlayerContainerViewController : PodcastPlayerDelegate {
    func playingState(podcastId: String, duration: Int, currentTime: Int) {
        guard podcastId == podcast.feedID else {
            return
        }
        configureControls(playing: true)
        podcastPlayerViewController.playingState(podcastId: podcastId, duration: duration, currentTime: currentTime)
    }
    
    func pausedState(podcastId: String, duration: Int, currentTime: Int) {
        guard podcastId == podcast.feedID else {
            return
        }
        configureControls(playing: false)
        podcastPlayerViewController.pausedState(podcastId: podcastId, duration: duration, currentTime: currentTime)
    }
    
    func loadingState(podcastId: String, loading: Bool) {
        guard podcastId == podcast.feedID else {
            return
        }
        podcastPlayerViewController.loadingState(podcastId: podcastId, loading: loading)
    }
}
