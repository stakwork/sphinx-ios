//
//  PodcastFeed+PlayerPodcastData.swift
//  sphinx
//
//  Created by Tomas Timinskas on 18/01/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension PodcastFeed {
    
    func getPodcastData(
        episodeId: String? = nil,
        currentTime: Int? = nil,
        playerSpeed: Float? = nil
    ) -> PodcastData? {
        
        var episode: PodcastEpisode? = nil
        
        if let episodeId = episodeId {
            episode = self.getEpisodeWith(id: episodeId)
        } else {
            episode = self.getCurrentEpisode()
        }
        
        guard let episode = episode, let url = episode.getAudioUrl() else {
            return nil
        }
        
        let currentTime = currentTime ?? episode.currentTime
        
        return PodcastData(
            self.chat?.id,
            self.feedID,
            episode.itemID,
            url,
            currentTime,
            episode.duration,
            playerSpeed ?? self.playerSpeed
        )
    }
}
