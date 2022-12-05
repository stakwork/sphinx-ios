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
    private lazy var loadingViewController = LoadingViewController()
    
    private var avPlayerAsset: AVAsset!
    private var avPlayerItem: AVPlayerItem!
    private var avPlayer: AVPlayer!
    
    
    private let requiredAssetKeys = [
        "playable",
        "hasProtectedContent"
    ]
    
    // Key-value observing context
    private var playerItemContext = 0
    
    
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
        playerViewController.entersFullScreenWhenPlaybackBegins = false
        playerViewController.exitsFullScreenWhenPlaybackEnds = true
        
        return playerViewController
    }
    
    
    func addAVPlayerViewController() {
        addChildVC(
            child: avPlayerViewController,
            container: videoPlayerView
        )
    }
    
    private func removeAVPlayerViewController() {
        removeChildVC(child: avPlayerViewController)
    }

    
    
    private func addPlayerErrorView() {
        // 📝 TODO:  Design / define how errors here should be presented to users
//        addChildVC(
//            child: playerErrorViewController,
//            container: videoPlayerView
//        )
    }
    
    private func removePlayerErrorView() {
        // 📝 TODO:  Design / define how errors here should be presented to users
//        removeChildVC(child: playerErrorViewController)
    }
    
    
    private func addPlayerLoadingView() {
        addChildVC(
            child: loadingViewController,
            container: videoPlayerView
        )
    }

    
    private func removePlayerLoadingView() {
        removeChildVC(child: loadingViewController)
    }
    
    
    
    private func updateVideoPlayer(withNewEpisode video: Video) {
        guard let mediaURL = video.mediaURL else { return }
        
        removeAVPlayerViewController()
        removePlayerErrorView()
        addPlayerLoadingView()

        setupPlayerAsset(usingURL: mediaURL)

        episodeTitleLabel.text = videoPlayerEpisode.titleForDisplay
        episodeViewCountLabel.text = "\(Int.random(in: 100...999)) Views"
        episodePublishDateLabel.text = videoPlayerEpisode.publishDateText
    }
    
    
    private func setupPlayerAsset(usingURL mediaURL: URL) {
        avPlayerAsset = AVAsset(url: mediaURL)
        avPlayerItem = AVPlayerItem(asset: avPlayerAsset)
        
        
        // Register as an observer of the player item's status property
        avPlayerItem.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.status),
            options: [.old, .new],
            context: &playerItemContext
        )
        
        
        if avPlayer == nil {
            avPlayer = AVPlayer(playerItem: avPlayerItem)
            avPlayerViewController.player = avPlayer
        } else {
            avPlayer!.replaceCurrentItem(with: avPlayerItem!)
        }
    }
}


// MARK: -  AVPlayerItem status observation
extension GeneralVideoFeedEpisodePlayerViewController {
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        // Only handle observations for the playerItemContext
        guard context == &playerItemContext else {
            super.observeValue(
                forKeyPath: keyPath,
                of: object,
                change: change,
                context: context
            )
            
            return
        }
        
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Switch over status value
            switch status {
            case .readyToPlay:
                // Player item is ready to play.
                removePlayerLoadingView()
                removePlayerErrorView()
                
                addAVPlayerViewController()
            case .failed:
                // Player item failed. See error.
                removeAVPlayerViewController()
                removePlayerLoadingView()
                
                addPlayerErrorView()
            case .unknown:
                // Player item is not yet ready.
                removeAVPlayerViewController()
                removePlayerErrorView()
                
                addPlayerLoadingView()
            }
        }
    }
}


// MARK: -  AVPlayerViewControllerDelegate
extension GeneralVideoFeedEpisodePlayerViewController: AVPlayerViewControllerDelegate {
    
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
    ) {
        playerViewController.player = avPlayer
    }
}
