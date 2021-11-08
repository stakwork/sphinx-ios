// GeneralVideoFeedEpisodePlayerViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit
import AVKit


class GeneralVideoFeedEpisodePlayerViewController: UIViewController, VideoFeedEpisodePlayerViewController {
    @IBOutlet private weak var videoPlayerView: UIView!
    @IBOutlet private weak var episodeTitleLabel: UILabel!
    @IBOutlet private weak var episodeViewCountLabel: UILabel!
    @IBOutlet private weak var episodeSubtitleCircularDivider: UIView!
    @IBOutlet private weak var episodePublishDateLabel: UILabel!
    
    
    private lazy var avPlayerViewController = makeAVPlayerViewController()
    private var avPlayerItem: AVPlayerItem?
    private var avPlayer: AVPlayer?
    
    
    var videoPlayerEpisode: Video! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.updateVideoPlayer(withNewEpisode: self.videoPlayerEpisode)
            }
        }
    }
}


// MARK: -  Static Methods
extension GeneralVideoFeedEpisodePlayerViewController {
    
    static func instantiate(
        videoPlayerEpisode: Video
    ) -> GeneralVideoFeedEpisodePlayerViewController {
        let viewController = StoryboardScene
            .VideoFeed
            .generalVideoFeedEpisodePlayerViewController
            .instantiate()
        
        viewController.videoPlayerEpisode = videoPlayerEpisode
    
        return viewController
    }
}


// MARK: -  Lifecycle
extension GeneralVideoFeedEpisodePlayerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupAVPlayerViewController()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        avPlayerViewController.player?.pause()
        avPlayerViewController.player = nil
    }
}


// MARK: - Computeds
extension GeneralVideoFeedEpisodePlayerViewController {
}


// MARK: -  Action Handling
extension GeneralVideoFeedEpisodePlayerViewController {
}


// MARK: -  Private Helpers
extension GeneralVideoFeedEpisodePlayerViewController {
    
    private func setupViews() {
        episodeSubtitleCircularDivider.makeCircular()
        
        episodeTitleLabel.text = videoPlayerEpisode.titleForDisplay
        episodeViewCountLabel.text = "\(Int.random(in: 100...999)) Views"
        episodePublishDateLabel.text = videoPlayerEpisode.publishDateText
    }
    
    
    private func makeAVPlayerViewController() -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()

        playerViewController.delegate = self
        playerViewController.showsPlaybackControls = true
        playerViewController.entersFullScreenWhenPlaybackBegins = true
        playerViewController.exitsFullScreenWhenPlaybackEnds = true
        
        return playerViewController
    }
        
    
    private func setupAVPlayerViewController() {
        addChildVC(
            child: avPlayerViewController,
            container: videoPlayerView
        )
    }
    
    
    private func updateVideoPlayer(withNewEpisode video: Video) {
        guard let mediaURL = video.mediaURL else { return }
  
        avPlayerItem = .init(asset: AVURLAsset(url: mediaURL))
        
        if avPlayer == nil {
            avPlayer = AVPlayer(playerItem: avPlayerItem)
            avPlayerViewController.player = avPlayer
        } else {
            avPlayer!.replaceCurrentItem(with: avPlayerItem!)
        }
        
        episodeTitleLabel.text = videoPlayerEpisode.titleForDisplay
        episodeViewCountLabel.text = "\(Int.random(in: 100...999)) Views"
        episodePublishDateLabel.text = videoPlayerEpisode.publishDateText
    }
}


extension GeneralVideoFeedEpisodePlayerViewController: AVPlayerViewControllerDelegate {
    
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
    ) {
        playerViewController.player = avPlayer
    }
}
