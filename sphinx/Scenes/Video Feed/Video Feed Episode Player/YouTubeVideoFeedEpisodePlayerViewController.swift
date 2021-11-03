// YouTubeVideoFeedEpisodePlayerViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit
import youtube_ios_player_helper


class YouTubeVideoFeedEpisodePlayerViewController: UIViewController, VideoFeedEpisodePlayerViewController {
    @IBOutlet private weak var videoPlayerView: YTPlayerView!
    @IBOutlet private weak var dismissButton: UIButton!
    @IBOutlet private weak var episodeTitleLabel: UILabel!
    @IBOutlet private weak var episodeViewCountLabel: UILabel!
    @IBOutlet weak var episodeSubtitleCircularDivider: UIView!
    @IBOutlet private weak var episodePublishDateLabel: UILabel!
    
    
    var videoPlayerEpisode: Video! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.updateVideoPlayer(withNewEpisode: self.videoPlayerEpisode)
            }
        }
    }
    
    
    var dismissButtonStyle: ModalDismissButtonStyle = .downArrow
    var onDismiss: (() -> Void)?
}


// MARK: -  Static Methods
extension YouTubeVideoFeedEpisodePlayerViewController {
    
    static func instantiate(
        videoPlayerEpisode: Video,
        dismissButtonStyle: ModalDismissButtonStyle = .downArrow,
        onDismiss: (() -> Void)?
    ) -> YouTubeVideoFeedEpisodePlayerViewController {
        let viewController = StoryboardScene
            .VideoFeed
            .youtubeVideoFeedEpisodePlayerViewController
            .instantiate()
        
        viewController.videoPlayerEpisode = videoPlayerEpisode
        viewController.dismissButtonStyle = dismissButtonStyle
        viewController.onDismiss = onDismiss
    
        return viewController
    }
}


// MARK: -  Lifecycle
extension YouTubeVideoFeedEpisodePlayerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        videoPlayerView.stopVideo()
    }
}


// MARK: - Computeds
extension YouTubeVideoFeedEpisodePlayerViewController {
}


// MARK: -  Action Handling
extension YouTubeVideoFeedEpisodePlayerViewController {
    
    @IBAction func dismissButtonTouched() {
        onDismiss?()
    }
}


// MARK: -  Private Helpers
extension YouTubeVideoFeedEpisodePlayerViewController {
    
    private func setupViews() {
        videoPlayerView.delegate = self
        
        episodeSubtitleCircularDivider.makeCircular()
        
        episodeTitleLabel.text = videoPlayerEpisode.titleForDisplay
        episodeViewCountLabel.text = "View Count"
        episodePublishDateLabel.text = videoPlayerEpisode.publishDateText
        
        setupDismissButton()
    }
    
    
    private func setupDismissButton() {
        switch dismissButtonStyle {
        case .downArrow:
            dismissButton.setImage(
                UIImage(systemName: "chevron.down"),
                for: .normal
            )
        case .backArrow:
            dismissButton.setImage(
                UIImage(systemName: "chevron.backward"),
                for: .normal
            )
        }
    }
    
    
    private func updateVideoPlayer(withNewEpisode video: Video) {
        videoPlayerView.load(withVideoId: videoPlayerEpisode.videoID)
    }
}


// MARK: -  YTPlayerViewDelegate
extension YouTubeVideoFeedEpisodePlayerViewController: YTPlayerViewDelegate {
    
}
