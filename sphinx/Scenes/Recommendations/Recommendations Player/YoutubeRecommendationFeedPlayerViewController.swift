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
        
        videoPlayerView.stopVideo()
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
        videoPlayerView.delegate = self
    }
    
    
    private func updateVideoPlayer(withEpisode video: PodcastEpisode) {
        var youtubeVideoId: String? = nil
        
        if let urlPath = video.linkURLPath {
            if let range = urlPath.range(of: "v=") {
                youtubeVideoId = String(urlPath[range.upperBound...])
            } else if let range = urlPath.range(of: "v/") {
                youtubeVideoId = String(urlPath[range.upperBound...])
            }
        }
        
        if let youtubeVideoId = youtubeVideoId {
            videoPlayerView.load(withVideoId: youtubeVideoId)
        }
    }
}


// MARK: -  YTPlayerViewDelegate
extension YoutubeRecommendationFeedPlayerViewController: YTPlayerViewDelegate {
    func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        playerView.currentTime({ (time, error) in
            switch (state) {
            case .playing:
                break
            case .paused:
                break
            case .ended:
                break
            default:
                break
            }
        })
    }
}
