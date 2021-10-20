// VideoFeedEpisodePlayerViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit
import youtube_ios_player_helper


class VideoFeedEpisodePlayerViewController: UIViewController {
    @IBOutlet private weak var videoPlayerView: YTPlayerView!
    
    var videoPlayerEpisode: Video!
}


// MARK: -  Static Methods
extension VideoFeedEpisodePlayerViewController {
    
    static func instantiate(
        videoPlayerEpisode: Video
    ) -> VideoFeedEpisodePlayerViewController {
        let viewController = StoryboardScene
            .VideoFeed
            .videoFeedEpisodePlayerViewController
            .instantiate()
        
        viewController.videoPlayerEpisode = videoPlayerEpisode
    
        return viewController
    }
}


// MARK: -  Lifecycle
extension VideoFeedEpisodePlayerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }
}



// MARK: -  Private Helpers
extension VideoFeedEpisodePlayerViewController {
    
    private func setupViews() {
        videoPlayerView.delegate = self
        videoPlayerView.load(withVideoId: videoPlayerEpisode.videoID)
    }
}


// MARK: -  YTPlayerViewDelegate
extension VideoFeedEpisodePlayerViewController: YTPlayerViewDelegate {
    
}
