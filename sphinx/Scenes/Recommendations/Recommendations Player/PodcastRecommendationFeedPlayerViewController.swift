//
//  PodcastRecommendationFeedPlayerViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/12/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit
import AVFoundation

class PodcastRecommendationFeedPlayerViewController: UIViewController {

    @IBOutlet weak var recommendationItemImageView: UIImageView!
    @IBOutlet weak var podcastPlaybackSliderView: PodcastPlayerPlaybackSliderView!
    
    var podcast: PodcastFeed! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                if let item = self.podcast.getCurrentEpisode() {
                    self.updatePodcastPlayer(withEpisode: item)
                }
            }
        }

    }
    
    var audioLoading = false {
        didSet {
            podcastPlaybackSliderView?.audioLoading = audioLoading
        }
    }
    
}

// MARK: -  Life cycle
extension PodcastRecommendationFeedPlayerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        podcastPlaybackSliderView.configureWith(podcast: podcast)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        PodcastPlayerHelper.sharedInstance.finishAndSaveContentConsumed()
    }
}

// MARK: -  Static Methods
extension PodcastRecommendationFeedPlayerViewController {
    
    static func instantiate(
        podcast: PodcastFeed
    ) -> PodcastRecommendationFeedPlayerViewController {
        let viewController = StoryboardScene
            .Recommendations
            .podcastRecommendationFeedPlayerViewController
            .instantiate()
        
        viewController.podcast = podcast
    
        return viewController
    }
}

// MARK: -  Private Helpers
extension PodcastRecommendationFeedPlayerViewController {
    
    private func updatePodcastPlayer(withEpisode item: PodcastEpisode) {
        if let imageURLString = item.imageURLPath, let url = URL(string: imageURLString) {
            recommendationItemImageView?.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: item.placeholderImageName ?? "podcastPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            recommendationItemImageView?.image = UIImage(named: item.placeholderImageName ?? "podcastPlaceholder")
        }
        
        if let startTime = item.clipStartTime {
            podcast.currentTime = startTime
        }
    }
}

// MARK: -  Podcast Player Delegate
extension PodcastRecommendationFeedPlayerViewController {
    func playingState(podcastId: String, duration: Int, currentTime: Int) {
        let didChangeTime = setProgress(duration: duration, currentTime: currentTime)
        audioLoading = !didChangeTime
    }
    
    func pausedState(podcastId: String, duration: Int, currentTime: Int) {
        let _ = setProgress(duration: duration, currentTime: currentTime)
        audioLoading = false
    }
    
    func loadingState(podcastId: String, loading: Bool) {
        audioLoading = loading
        showTimeInfo()
    }
    
    func errorState(podcastId: String) {
        audioLoading = false
    }
    
    func showTimeInfo() {
        audioLoading = true
        loadTime()
    }
    
    func loadTime() {
        let episode = podcast.getCurrentEpisode()
        
        if let duration = episode?.duration {
            let _ = setProgress(
                duration: duration,
                currentTime: podcast.currentTime
            )
            audioLoading = false
        } else if let url = episode?.getAudioUrl() {
            let asset = AVAsset(url: url)
            asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                let duration = Int(Double(asset.duration.value) / Double(asset.duration.timescale))
                episode?.duration = duration
                
                DispatchQueue.main.async {
                    let _ = self.setProgress(
                        duration: duration,
                        currentTime: self.podcast.currentTime
                    )
                    self.audioLoading = false
                }
            })
        }
    }
    
    private func setProgress(
        duration: Int,
        currentTime: Int
    ) -> Bool {
        let episode = podcast.getCurrentEpisode()
        
        let didChangeTime = podcastPlaybackSliderView?.setProgress(
            duration: duration,
            currentTime: currentTime,
            clipStartTime: episode?.clipStartTime,
            clipEndTime: episode?.clipEndTime
        ) ?? false
        
        return didChangeTime
    }
}
