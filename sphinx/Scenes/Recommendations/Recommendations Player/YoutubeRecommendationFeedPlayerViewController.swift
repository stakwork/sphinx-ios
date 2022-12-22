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
                
                if let youtubeVideoId = self.podcast.getCurrentEpisode()?.youtubeVideoId {
                    self.trackItemStarted(
                        videoId: youtubeVideoId,
                        startTime ?? time
                    )
                }
                break
            case .paused:
                if let youtubeVideoId = self.podcast.getCurrentEpisode()?.youtubeVideoId {
                    self.trackItemFinished(
                        videoId: youtubeVideoId,
                        time
                    )
                }
                break
            case .ended:
                if let youtubeVideoId = self.podcast.getCurrentEpisode()?.youtubeVideoId {
                    self.trackItemFinished(
                        videoId: youtubeVideoId,
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
        videoId: String,
        _ currentTime: Float
    ) {
//        if let feedItem: ContentFeedItem = ContentFeedItem.getItemWith(itemID: videoId) {
//            let time = Int(round(currentTime)) * 1000
//            actionsManager.trackItemConsumed(item: feedItem, startTimestamp: time)
//        }
    }

    func trackItemFinished(
        videoId: String,
        _ currentTime: Float,
        shouldSaveAction: Bool = false
    ) {
//        if let feedItem: ContentFeedItem = ContentFeedItem.getItemWith(itemID: videoId) {
//            let time = Int(round(currentTime)) * 1000
//            actionsManager.trackItemFinished(item: feedItem, timestamp: time, shouldSaveAction: shouldSaveAction)
//        }
    }
}
