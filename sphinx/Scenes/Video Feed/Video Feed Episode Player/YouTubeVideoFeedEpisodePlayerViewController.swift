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
    
    let actionsManager = ActionsManager.sharedInstance
    let podcastPlayer = PodcastPlayerHelper.sharedInstance
    
    var videoPlayerEpisode: Video! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.updateVideoPlayer(withNewEpisode: self.videoPlayerEpisode, previousEpisode: oldValue)
            }
        }
    }
    
    var currentTime: Float = 0
    var currentState: YTPlayerState = .unknown
    
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
        episodeViewCountLabel.text = "\(Int.random(in: 100...999)) Views"
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
    
    
    private func updateVideoPlayer(withNewEpisode video: Video, previousEpisode: Video?) {
        if let previousEpisode = previousEpisode {
            currentState = .ended
            
            trackItemFinished(
                videoId: previousEpisode.videoID,
                currentTime,
                shouldSaveAction: true
            )
        }
        
        videoPlayerView.load(withVideoId: videoPlayerEpisode.youtubeVideoID)
        
        episodeTitleLabel.text = videoPlayerEpisode.titleForDisplay
        episodeViewCountLabel.text = "\(Int.random(in: 100...999)) Views"
        episodePublishDateLabel.text = videoPlayerEpisode.publishDateText
    }
}


// MARK: -  YTPlayerViewDelegate
extension YouTubeVideoFeedEpisodePlayerViewController: YTPlayerViewDelegate {
    func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {
        currentTime = playTime
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        currentState = state
        
        playerView.currentTime({ (time, error) in
            switch (state) {
            case .playing:
                self.videoPlayerEpisode?.videoFeed?.chat?.updateWebAppLastDate()

                self.trackItemStarted(
                    videoId: self.videoPlayerEpisode.videoID,
                    time
                )
                break
            case .paused:
                self.trackItemFinished(
                    videoId: self.videoPlayerEpisode.videoID,
                    self.currentTime
                )
                break
            case .ended:
                self.trackItemFinished(
                    videoId: self.videoPlayerEpisode.videoID,
                    time,
                    shouldSaveAction: true
                )
                break
            default:
                break
            }
        })
    }
    
    func trackItemStarted(
        videoId: String,
        _ currentTime: Float
    ) {
        if let feedItem: ContentFeedItem = ContentFeedItem.getItemWith(itemID: videoId) {
            let time = Int(round(currentTime)) * 1000
            actionsManager.trackItemConsumed(item: feedItem, startTimestamp: time)
        }
    }

    func trackItemFinished(
        videoId: String,
        _ currentTime: Float,
        shouldSaveAction: Bool = false
    ) {
        if let feedItem: ContentFeedItem = ContentFeedItem.getItemWith(itemID: videoId) {
            let time = Int(round(currentTime)) * 1000
            actionsManager.trackItemFinished(item: feedItem, timestamp: time, shouldSaveAction: shouldSaveAction)
        }
    }
}
