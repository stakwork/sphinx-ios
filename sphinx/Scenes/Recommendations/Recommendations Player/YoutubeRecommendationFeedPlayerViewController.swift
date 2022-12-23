//
//  YoutubeRecommendationFeedPlayerViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/12/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit
import youtube_ios_player_helper

class YoutubeRecommendationFeedPlayerViewController: UIViewController {
    
    @IBOutlet private weak var videoPlayerView: YTPlayerView!
    @IBOutlet private weak var dismissButton: UIButton!
    
    let podcastPlayer = PodcastPlayerHelper.sharedInstance
    let actionsManager = ActionsManager.sharedInstance
    
    var podcast: PodcastFeed! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                if let item = self.podcast.getCurrentEpisode() {
                    self.updateVideoPlayer(withEpisode: item)
                }
            }
        }
    }
    
    private var currentTime: Float = 0
    private var didSeekToStartTime = false
}

// MARK: -  Lifecycle
extension YoutubeRecommendationFeedPlayerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        podcastPlayer.shouldPause()
        podcastPlayer.finishAndSaveContentConsumed()

        setupViews()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        videoPlayerView?.stopVideo()
        podcastPlayer.finishAndSaveContentConsumed()
    }
}

// MARK: -  Static Methods
extension YoutubeRecommendationFeedPlayerViewController {
    
    static func instantiate(
        podcast: PodcastFeed
    ) -> YoutubeRecommendationFeedPlayerViewController {
        let viewController = StoryboardScene
            .Recommendations
            .youtubeRecommendationFeedPlayerViewController
            .instantiate()
        
        viewController.podcast = podcast
    
        return viewController
    }
}

// MARK: -  Private Helpers
extension YoutubeRecommendationFeedPlayerViewController {
    
    private func setupViews() {
        videoPlayerView?.delegate = self
    }
    
    
    private func updateVideoPlayer(withEpisode video: PodcastEpisode) {
        if let youtubeVideoId = video.youtubeVideoId {
            didSeekToStartTime = false
            videoPlayerView?.load(withVideoId: youtubeVideoId)
        }
    }
}


// MARK: -  YTPlayerViewDelegate
extension YoutubeRecommendationFeedPlayerViewController: YTPlayerViewDelegate {
    func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {
        currentTime = playTime
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        playerView.currentTime({ (time, error) in
            switch (state) {
            case .playing:
                let startTime = self.seekToStartTime()
                
                if let episode = self.podcast.getCurrentEpisode() {
                    self.trackItemStarted(
                        episode: episode,
                        startTime ?? time
                    )
                }
                break
            case .paused:
                if let episode = self.podcast.getCurrentEpisode() {
                    self.trackItemFinished(
                        episode: episode,
                        time
                    )
                }
                break
            case .ended:
                if let episode = self.podcast.getCurrentEpisode() {
                    self.trackItemFinished(
                        episode: episode,
                        time,
                        shouldSaveAction: true
                    )
                }
                break
            default:
                break
            }
        })
    }
    
    private func seekToStartTime() -> Float? {
        if let startTime = podcast.getCurrentEpisode()?.clipEndTime {
            if (!didSeekToStartTime) {
                videoPlayerView?.seek(toSeconds: Float(startTime), allowSeekAhead: true)
                didSeekToStartTime = true
                
                return Float(startTime)
            }
        }
        return nil
    }
    
    func trackItemStarted(
        episode: PodcastEpisode,
        _ currentTime: Float
    ) {
        let time = Int(round(currentTime)) * 1000
        actionsManager.trackItemConsumed(item: episode, podcast: podcast, startTimestamp: time)
    }

    func trackItemFinished(
        episode: PodcastEpisode,
        _ currentTime: Float,
        shouldSaveAction: Bool = false
    ) {
        let time = Int(round(currentTime)) * 1000
        actionsManager.trackItemFinished(item: episode, podcast: podcast, timestamp: time, shouldSaveAction: shouldSaveAction)
    }
}
