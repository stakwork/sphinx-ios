//
//  PodcastSmallPlayer+Delegates.swift
//  sphinx
//
//  Created by Tomas Timinskas on 17/01/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension PodcastSmallPlayer : PlayerDelegate {
    func loadingState(_ podcastData: PodcastData) {
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        audioLoading = true
        configureControls(playing: true)
        showEpisodeInfo()
    }
    
    func playingState(_ podcastData: PodcastData) {
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        isHidden = false
        showEpisodeInfo()
        configureControls(playing: true)
        audioLoading = false
    }
    
    func pausedState(_ podcastData: PodcastData) {
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        showEpisodeInfo()
        configureControls(playing: false)
        audioLoading = false
    }
    
    func endedState(_ podcastData: PodcastData) {
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        showEpisodeInfo()
        configureControls(playing: false)
    }
    
    func errorState(_ podcastData: PodcastData) {
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        delegate?.didFailPlayingPodcast()
        configureControls(playing: false)
        audioLoading = false
    }
}
