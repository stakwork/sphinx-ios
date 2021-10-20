// VideoFeedEpisodePlayerViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit
import youtube_ios_player_helper


class VideoFeedEpisodePlayerViewController: UIViewController {
    @IBOutlet private weak var videoPlayerView: YTPlayerView!
    @IBOutlet private weak var dismissButton: UIButton!
    @IBOutlet private weak var episodeTitleLabel: UILabel!
    @IBOutlet private weak var episodeViewCountLabel: UILabel!
    @IBOutlet weak var episodeSubtitleCircularDivider: UIView!
    @IBOutlet private weak var episodePublishDateLabel: UILabel!
    
    
    var videoPlayerEpisode: Video!
    var dismissButtonStyle: ModalDismissButtonStyle = .downArrow
    var onDismiss: (() -> Void)?
}


// MARK: -  Static Methods
extension VideoFeedEpisodePlayerViewController {
    
    static func instantiate(
        videoPlayerEpisode: Video,
        dismissButtonStyle: ModalDismissButtonStyle = .downArrow,
        onDismiss: (() -> Void)?
    ) -> VideoFeedEpisodePlayerViewController {
        let viewController = StoryboardScene
            .VideoFeed
            .videoFeedEpisodePlayerViewController
            .instantiate()
        
        viewController.videoPlayerEpisode = videoPlayerEpisode
        viewController.dismissButtonStyle = dismissButtonStyle
        viewController.onDismiss = onDismiss
    
        return viewController
    }
}


// MARK: -  Lifecycle
extension VideoFeedEpisodePlayerViewController {
    
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
extension VideoFeedEpisodePlayerViewController {
}


// MARK: -  Action Handling
extension VideoFeedEpisodePlayerViewController {
    
    @IBAction func dismissButtonTouched() {
        onDismiss?()
    }
}


// MARK: -  Private Helpers
extension VideoFeedEpisodePlayerViewController {
    
    private func setupViews() {
        videoPlayerView.delegate = self
        videoPlayerView.load(withVideoId: videoPlayerEpisode.videoID)
        
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
}


// MARK: -  YTPlayerViewDelegate
extension VideoFeedEpisodePlayerViewController: YTPlayerViewDelegate {
    
}
