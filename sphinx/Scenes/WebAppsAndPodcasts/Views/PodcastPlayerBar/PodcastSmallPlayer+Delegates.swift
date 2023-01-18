//
//  PodcastSmallPlayer+Delegates.swift
//  sphinx
//
//  Created by Tomas Timinskas on 17/01/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension PodcastSmallPlayer {
    func getPodcastData(
        episodeId: String? = nil,
        currentTime: Int? = nil
    ) -> PodcastData? {
        
        guard let podcast = podcast else {
            return nil
        }
        
        var episode: PodcastEpisode? = nil
        
        if let episodeId = episodeId {
            episode = podcast.getEpisodeWith(id: episodeId)
        } else {
            episode = podcast.getCurrentEpisode()
        }
        
        guard let episode = episode, let url = episode.getAudioUrl() else {
            return nil
        }
        
        let currentTime = currentTime ?? episode.currentTime
        
        return PodcastData(
            podcast.chat?.id,
            podcast.feedID,
            episode.itemID,
            url,
            currentTime,
            episode.duration,
            podcast.playerSpeed
        )
    }
}

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
    }
}
