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
    
    var podcastItem: RecommendationResult! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.updatePodcastPlayer(withNewEpisode: self.podcastItem)
            }
        }
    }
    
    var podcast: PodcastFeed!
    
    var audioLoading = false {
        didSet {
            podcastPlaybackSliderView.audioLoading = audioLoading
        }
    }
    
}

// MARK: -  Life cycle
extension PodcastRecommendationFeedPlayerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        podcastPlaybackSliderView.configureWith(podcast: podcast)
    }
}

// MARK: -  Static Methods
extension PodcastRecommendationFeedPlayerViewController {
    
    static func instantiate(
        podcastItem: RecommendationResult,
        andPodcast podcast: PodcastFeed
    ) -> PodcastRecommendationFeedPlayerViewController {
        let viewController = StoryboardScene
            .Recommendations
            .podcastRecommendationFeedPlayerViewController
            .instantiate()
        
        viewController.podcastItem = podcastItem
        viewController.podcast = podcast
    
        return viewController
    }
}

// MARK: -  Private Helpers
extension PodcastRecommendationFeedPlayerViewController {
    
    private func updatePodcastPlayer(withNewEpisode item: RecommendationResult) {
        if let imageURLString = item.imageURLPath, let url = URL(string: imageURLString) {
            recommendationItemImageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: item.placeholderImageName ?? "podcastPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            recommendationItemImageView.image = UIImage(named: item.placeholderImageName ?? "podcastPlaceholder")
        }
    }
}

// MARK: -  Podcast Player Delegate
extension PodcastRecommendationFeedPlayerViewController {
    func playingState(podcastId: String, duration: Int, currentTime: Int) {
        let didChangeTime = podcastPlaybackSliderView.setProgress(duration: duration, currentTime: currentTime)
        audioLoading = !didChangeTime
    }
    
    func pausedState(podcastId: String, duration: Int, currentTime: Int) {
        let _ = podcastPlaybackSliderView.setProgress(duration: duration, currentTime: currentTime)
        audioLoading = false
    }
    
    func loadingState(podcastId: String, loading: Bool) {
        audioLoading = loading
        showTimeInfo()
    }
    
    func showTimeInfo() {
        audioLoading = true
        loadTime()
    }
    
    func loadTime() {
        let episode = podcast.getCurrentEpisode()
        
        if let duration = episode?.duration {
            let _ = podcastPlaybackSliderView.setProgress(
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
                    let _ = self.podcastPlaybackSliderView.setProgress(
                        duration: duration,
                        currentTime: self.podcast.currentTime
                    )
                    self.audioLoading = false
                }
            })
        }
    }
}
