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
    var clipInfo: ClipInfo? = nil
    
    init(
        _ chatId: Int?,
        _ podcastId: String,
        _ episodeId: String,
        _ episodeUrl: URL,
        _ currentTime: Int? = nil,
        _ duration: Int? = nil,
        _ speed: Float = 1,
        _ downloaded: Bool = false,
        _ clipInfo: ClipInfo? = nil
    ) {
        self.chatId = chatId
        self.podcastId = podcastId
        self.episodeId = episodeId
        self.episodeUrl = episodeUrl
        self.currentTime = currentTime
        self.duration = duration
        self.speed = speed
        self.downloaded = downloaded
        self.clipInfo = clipInfo
    }
    
    struct ClipInfo {
        var messageId: Int
        var rowIndex: Int
        var messageUUID: String?
        var clipSenderPubKey: String? = nil
        
        init(
            _ messageId: Int,
            _ rowIndex: Int,
            _ messageUUID: String? = nil,
            _ clipSenderPubKey: String? = nil
        ) {
            self.messageId = messageId
            self.rowIndex = rowIndex
            self.messageUUID = messageUUID
            self.clipSenderPubKey = clipSenderPubKey
        }
    }
}

extension PodcastFeed {
    
    func getPodcastData(
        episodeId: String? = nil,
        currentTime: Int? = nil,
        playerSpeed: Float? = nil,
        clipInfo: PodcastData.ClipInfo? = nil
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
            clipInfo
        )
    }
}
