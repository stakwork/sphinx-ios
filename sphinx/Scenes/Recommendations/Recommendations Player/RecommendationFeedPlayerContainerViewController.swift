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
    
    var podcastPlayerController = PodcastPlayerController.sharedInstance
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
        
        configurePlayerView()
        setPlayingEpisode()
        configureCollectionView()
        configurePodcastPlayer()
    }
    
    override func endAppearanceTransition() {
        super.endAppearanceTransition()
        
        if isBeingDismissed {
            podcastPlayerController.finishAndSaveContentConsumed()
            podcastPlayerController.removeFromDelegatesWith(key: PodcastDelegateKeys.PodcastPlayerView.rawValue)
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
    }
    
    private func addPodcastPlayerView() {
        removeChildVC(child: youtubeVideoPlayerViewController)
        
        addChildVC(
            child: podcastPlayerViewController,
            container: playerContainerView
        )
    }

    private func configureCollectionView() {
        addChildVC(
            child: collectionViewController,
            container: collectionViewContainer
        )
    }
    
    private func configurePodcastPlayer() {
        podcastPlayerController.addDelegate(self, withKey: PodcastDelegateKeys.RecommendationsPlayerView.rawValue)
    }
}

// MARK: -  Action Handling
extension RecommendationFeedPlayerContainerViewController {
    
    private func handleRecommendationCellSelection(
        _ recommendationId: String
    ) {
        if podcastPlayerController.isPlaying(episodeId: recommendationId) {
            recommendationDetailsView.togglePlayState()
            return
        }
        
        if let episode = podcast.getEpisodeWith(id: recommendationId) {
            shouldPlay(episode)
        }
        
        setPlayingEpisode()
        configurePlayerView()
    }
    
    func shouldPlay(_ episode: PodcastEpisode) {
        let currentTime = ((episode.currentTime ?? 0) > 0) ? episode.currentTime : (episode.clipStartTime ?? 0)
        
        guard let podcastData = podcast.getPodcastData(
            episodeId: episode.itemID,
            currentTime: currentTime
        ) else {
            return
        }
        
        podcastPlayerController.submitAction(
            UserAction.Play(podcastData)
        )
    }
}

// MARK: -  Picker Delegate
extension RecommendationFeedPlayerContainerViewController : RecommendationPlayerViewDelegate, PickerViewDelegate {
    func shouldShowSpeedPicker() {
        let selectedValue = podcast.playerSpeed
        let pickerVC = PickerViewController.instantiate(values: ["0.5", "0.8", "1.0", "1.2", "1.5", "2.1"], selectedValue: "\(selectedValue)", delegate: self)
        self.present(pickerVC, animated: false, completion: nil)
    }
    
    func shouldSetProgress(
        duration: Int,
        currentTime: Int
    ) {
        podcastPlayerViewController.setProgress(
            duration: duration,
            currentTime: currentTime
        )
    }
    
    func shouldReloadList() {
        collectionViewController.updateSnapshot()
    }
    
    func didSelectValue(value: String) {
        if let newSpeed = Float(value), newSpeed >= 0.5 && newSpeed <= 2.1 {
            
            guard let podcastData = podcast.getPodcastData(
                playerSpeed: newSpeed
            ) else {
                return
            }
            
            podcastPlayerController.submitAction(
                UserAction.AdjustSpeed(podcastData)
            )
            
            configureControls()
        }
    }
    
    func configureControls(
        playing: Bool? = nil
    ) {
        recommendationDetailsView.configureControls(
            playing: playing ?? podcastPlayerController.isPlaying(podcastId: podcast.feedID),
            speedDescription: podcast.playerSpeed.speedDescription
        )
    }
}

// MARK: -  Podcast Player Delegate
extension RecommendationFeedPlayerContainerViewController : PlayerDelegate {
    func loadingState(_ podcastData: PodcastData) {
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        configureControls(playing: true)
        setPlayingEpisode()
        podcastPlayerViewController.loadingState(podcastData)
    }
    
    func playingState(_ podcastData: PodcastData) {
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        configureControls(playing: true)
        podcastPlayerViewController.playingState(podcastData)
    }
    
    func pausedState(_ podcastData: PodcastData) {
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        configureControls(playing: false)
        podcastPlayerViewController.pausedState(podcastData)
    }
    
    func endedState(_ podcastData: PodcastData) {
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        podcastPlayerViewController.endedState(podcastData)
    }
    
    func errorState(_ podcastData: PodcastData) {
        configureControls(playing: false)
        AlertHelper.showAlert(title: "generic.error.title".localized, message: "error.playing".localized)
    }
}
