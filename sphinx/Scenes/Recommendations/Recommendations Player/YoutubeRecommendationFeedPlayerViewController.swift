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
    
    var videoItem: RecommendationResult! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.updateVideoPlayer(withNewEpisode: self.videoItem)
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
        videoItem: RecommendationResult
    ) -> YoutubeRecommendationFeedPlayerViewController {
        let viewController = StoryboardScene
            .Recommendations
            .youtubeRecommendationFeedPlayerViewController
            .instantiate()
        
        viewController.videoItem = videoItem
    
        return viewController
    }
}

// MARK: -  Private Helpers
extension YoutubeRecommendationFeedPlayerViewController {
    
    private func setupViews() {
        videoPlayerView.delegate = self
    }
    
    
    private func updateVideoPlayer(withNewEpisode video: RecommendationResult) {
        var youtubeVideoId: String? = nil
        
        if let range = videoItem.link.range(of: "v=") {
            youtubeVideoId = String(videoItem.link[range.upperBound...])
        } else if let range = videoItem.link.range(of: "v/") {
            youtubeVideoId = String(videoItem.link[range.upperBound...])
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
