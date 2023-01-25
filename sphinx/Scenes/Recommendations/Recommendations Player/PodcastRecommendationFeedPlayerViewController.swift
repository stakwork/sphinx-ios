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
                    self.showTimeInfo()
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
        
        PodcastPlayerController.sharedInstance.finishAndSaveContentConsumed()
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
        
        if let startTime = item.clipStartTime, item.currentTime == nil {
            item.currentTime = startTime
        }
    }
}

// MARK: -  Podcast Player Delegate
extension PodcastRecommendationFeedPlayerViewController {
    func loadingState(_ podcastData: PodcastData) {
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        audioLoading = true
        showTimeInfo()
    }
    
    func playingState(_ podcastData: PodcastData) {
        audioLoading = false
        setProgress(duration: podcastData.duration ?? 0, currentTime: podcastData.currentTime ?? 0)
    }
    
    func pausedState(_ podcastData: PodcastData) {
        audioLoading = false
        setProgress(duration: podcastData.duration ?? 0, currentTime: podcastData.currentTime ?? 0)
    }
    
    func endedState(_ podcastData: PodcastData) {
        showTimeInfo()
    }
    
    func errorState(_ podcastData: PodcastData) {
        audioLoading = false
    }
    
    func showTimeInfo() {
        audioLoading = true
        loadTime()
    }
    
    func loadTime() {
        let episode = podcast.getCurrentEpisode()
        
        audioLoading = true
        
        if let duration = episode?.duration {
            
            let _ = setProgress(
                duration: duration,
                currentTime: podcast.currentTime
            )
            
            audioLoading = false
            
        } else if let url = episode?.getAudioUrl() {
            
            setProgress(
                duration: 0,
                currentTime: 0
            )
            
            let asset = AVAsset(url: url)
            asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                let duration = Int(Double(asset.duration.value) / Double(asset.duration.timescale))
                episode?.duration = duration

                DispatchQueue.main.async {
                    if duration > 0 {
                        let _ = self.setProgress(
                            duration: duration,
                            currentTime: self.podcast.currentTime
                        )
                    }
                    
                    self.audioLoading = false
                }
            })
        }
    }
    
    func setProgress(
        duration: Int,
        currentTime: Int
    ) {
        let episode = podcast.getCurrentEpisode()
        
        podcastPlaybackSliderView?.setProgress(
            duration: duration,
            currentTime: currentTime,
            clipStartTime: episode?.clipStartTime,
            clipEndTime: episode?.clipEndTime
        )
    }
}
