// VideoFeedEpisodePlayerViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit


class VideoFeedEpisodePlayerViewController: UIViewController {
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

    }
}



// MARK: -  Private Helpers
extension VideoFeedEpisodePlayerViewController {
}
