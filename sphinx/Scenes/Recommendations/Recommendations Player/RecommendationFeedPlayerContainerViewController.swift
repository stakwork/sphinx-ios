//
//  RecommendationFeedPlayerContainerViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/12/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

class RecommendationFeedPlayerContainerViewController: UIViewController {
    
    @IBOutlet weak var playerContainerView: UIView!
    @IBOutlet weak var recommendationDetailsView: RecommendationDetailsView!
    @IBOutlet weak var collectionViewContainer: UIView!
    
    var podcast: PodcastFeed!

    internal lazy var youtubeVideoPlayerViewController: YoutubeRecommendationFeedPlayerViewController = {
        YoutubeRecommendationFeedPlayerViewController.instantiate(podcast: podcast)
    }()
    
    internal lazy var podcastPlayerViewController: PodcastRecommendationFeedPlayerViewController = {
        PodcastRecommendationFeedPlayerViewController.instantiate(podcast: podcast)
    }()
    
    internal lazy var collectionViewController: RecommendationFeedItemsCollectionViewController = {
        RecommendationFeedItemsCollectionViewController.instantiate(
            podcast: podcast,
            onRecommendationCellSelected: handleRecommendationCellSelection(_:)
        )
    }()
    
    var playerHelper: PodcastPlayerHelper = PodcastPlayerHelper.sharedInstance
}

// MARK: -  Static Methods
extension RecommendationFeedPlayerContainerViewController {
    
    static func instantiate(
        podcast: PodcastFeed
    ) -> RecommendationFeedPlayerContainerViewController {
        let viewController = StoryboardScene
            .Recommendations
            .recommendationFeedPlayerContainerViewController
            .instantiate()
        
        viewController.podcast = podcast
    
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
        
        if let item = podcast.getCurrentEpisode() {
            loadAndPlayEpisode(recommendationId: item.itemID)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isBeingDismissed {
            playerHelper.removeFromDelegatesWith(key: PodcastPlayerHelper.DelegateKeys.recommendationsPlayer.rawValue)
        }
    }
}

// MARK: -  Private Helpers
extension RecommendationFeedPlayerContainerViewController {
    
    private func setPlayingEpisode() {
        guard
            let episode = self.podcast.getCurrentEpisode()
        else { return }

        self.recommendationDetailsView.configure(withPodcast: podcast, andDelegate: self)

        if (episode.isMusicClip) {
            self.podcastPlayerViewController.podcast = podcast
        } else if (episode.isYoutubeVideo) {
            self.youtubeVideoPlayerViewController.podcast = podcast
        }
    }
    
    private func configurePlayerView() {
        if let item = podcast.getCurrentEpisode() {
            if item.isMusicClip {
                addPodcastPlayerView()
            } else if item.isYoutubeVideo {
                addVideoPlayerView()
            }
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
        loadAndPlayEpisode(recommendationId: recommendationId)
        setPlayingEpisode()
        configurePlayerView()
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
    
    func errorState(podcastId: String) {
        configureControls(playing: false)
        AlertHelper.showAlert(title: "Error", message: "This clip can't be played", on: self)
    }
}
