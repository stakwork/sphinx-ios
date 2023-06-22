//
//  PodcastFeed+PlayerPodcastData.swift
//  sphinx
//
//  Created by Tomas Timinskas on 18/01/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

struct PodcastData {
    
    var chatId: Int?
    var podcastId: String
    var episodeId: String
    var episodeUrl: URL
    var currentTime: Int? = nil
    var duration: Int? = nil
    var speed: Float = 1
    var downloaded: Bool = false
    var messageId: Int? = nil
    var rowIndex: Int? = nil
    
    init(
        _ chatId: Int?,
        _ podcastId: String,
        _ episodeId: String,
        _ episodeUrl: URL,
        _ currentTime: Int? = nil,
        _ duration: Int? = nil,
        _ speed: Float = 1,
        _ downloaded: Bool = false,
        _ messageId: Int? = nil,
        _ rowIndex: Int? = nil
    ) {
        self.chatId = chatId
        self.podcastId = podcastId
        self.episodeId = episodeId
        self.episodeUrl = episodeUrl
        self.currentTime = currentTime
        self.duration = duration
        self.speed = speed
        self.downloaded = downloaded
        self.messageId = messageId
        self.rowIndex = rowIndex
    }
}

extension PodcastFeed {
    
    func getPodcastData(
        episodeId: String? = nil,
        currentTime: Int? = nil,
        playerSpeed: Float? = nil,
        messageId: Int? = nil,
        rowIndex: Int? = nil
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
            playerSpeed ?? self.playerSpeed,
            episode.isDownloaded,
            messageId,
            rowIndex
        )
    }
}
