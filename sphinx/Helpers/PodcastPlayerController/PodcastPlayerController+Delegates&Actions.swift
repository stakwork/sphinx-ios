//
//  PodcastPlayerController+Delegates&Actions.swift
//  sphinx
//
//  Created by Tomas Timinskas on 13/01/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import AVFoundation

extension PodcastPlayerController {
    
    func addDelegate(
        _ delegate: PlayerDelegate,
        withKey key: String
    ) {
        self.delegates[key] = delegate
    }
    
    func removeFromDelegatesWith(key: String) {
        self.delegates.removeValue(forKey: key)
    }
    
    func submitAction(_ action: UserAction) {
        switch(action) {
        case .Play(let podcastData):
            play(podcastData)
        case .Pause(let podcastData):
            pause(podcastData)
        case .Seek(let podcastData):
            seek(podcastData)
        case .AdjustSpeed(let podcastData):
            adjustSpeed(podcastData)
        case .TogglePlay(let podcastData):
            if (
                isPlaying &&
                podcastData.episodeId == self.podcastData?.episodeId &&
                podcastData.clipInfo?.messageId == self.podcastData?.clipInfo?.messageId
            ) {
                pause(podcastData)
            } else {
                play(podcastData)
            }
        }
    }
}

extension PodcastPlayerController {
    
    func preloadAll() {
        
        let context = CoreDataManager.sharedManager.getBackgroundContext()
        
        context.perform {
            let sortedPodcasts = PodcastFeed.getAll(context: context).sorted { (first, second) in
                let firstDate = first.dateLastConsumed ?? Date.init(timeIntervalSince1970: 0)
                let secondDate = second.dateLastConsumed ?? Date.init(timeIntervalSince1970: 0)
                
                if (firstDate == secondDate) {
                    let firstDate = first.itemsArray.first?.datePublished ?? Date.init(timeIntervalSince1970: 0)
                    let secondDate = second.itemsArray.first?.datePublished ?? Date.init(timeIntervalSince1970: 0)
                    
                    return firstDate > secondDate
                }
                
                return firstDate > secondDate
            }
            
            for feed in sortedPodcasts {
                let podcast = PodcastFeed.convertFrom(contentFeed: feed)
                let episodes = podcast.getEpisodesToCache()
                
                for episode in episodes {
                    self.preloadEpisode(episode)
                }
            }
        }
    }
    
    func preloadEpisode(_ episode: PodcastEpisode) {
        if !ConnectivityHelper.isConnectedToInternet {
            return
        }
        
        guard let url = episode.getAudioUrl() else {
            return
        }

        let urlPath = url.absoluteString

        if episode.isDownloaded {
            return
        }

        if allItems[urlPath] != nil {
            return
        }

        dispatchSemaphore.wait()

        let asset = AVURLAsset(url: url)
        let item = CachingPlayerItem(asset: asset, automaticallyLoadedAssetKeys: ["playable"])
        self.allItems[urlPath] = item
        self.dispatchSemaphore.signal()
    }
    
    func getPreloadedItem(url: String) -> CachingPlayerItem? {
        return podcastItems[url] ?? allItems[url]
    }

    func play(
        _ podcastData: PodcastData
    ) {
        setAudioSession()
        
        if let pd = self.podcastData, isPlaying {
            if
                podcastData.episodeId == pd.episodeId,
                podcastData.clipInfo?.messageId == pd.clipInfo?.messageId
            {
                ///If playing same episode, then return
                return
            } else {
                ///If playing another episode, then pause first
                trackItemFinished(shouldSaveAction: true)
                pausePlaying()
                runPausedStateUpdate()
            }
        }
        
        FeedsManager.sharedInstance.updateLastConsumedWithFeedID(feedID: podcastData.podcastId)
        
        self.isSoundPlaying = false
        self.podcastData = podcastData
        
        updatePodcastObject(
            podcastId: podcastData.podcastId,
            episodeId: podcastData.episodeId,
            currentTime: podcastData.currentTime,
            duration: podcastData.duration,
            playerSpeed: podcastData.speed,
            clipInfo: podcastData.clipInfo
        )
        
        if !ConnectivityHelper.isConnectedToInternet && !podcastData.downloaded {
            self.runErrorStateUpdate()
            return
        }
        
        if let episode = podcast?.getCurrentEpisode(), !episode.isMusicClip {
            ///If playing video on recommendations player
            resetPlayingInfoCenter()
            return
        }
        
        runLoadingStateUpdate()
        
        if let player = player, isPlayerItemSetWith(episodeUrl: podcastData.episodeUrl) {
            ///If same item is set on player, then just seek and play without loading duration asynchronously
            ///Avoid loading episode image again
            player.seek(to: CMTime(seconds: Double(podcastData.currentTime ?? 0), preferredTimescale: 1))
            player.playImmediately(atRate: podcastData.speed)
            
            if let playerItem = player.currentItem {
                self.didStartPlaying(playerItem)
            }
            
        } else {
            ///If new item will be played, then load episode image for info center and load duration asynchronously to prevent
            ///UI lock when start playing
            loadEpisodeImage()
            
            let item = getPreloadedItem(url: podcastData.episodeUrl.absoluteString)
            
            DispatchQueue.global(qos: .userInitiated).async {
                if let item = item {
                    DispatchQueue.main.async {
                        playAssetAfterLoad(item)
                    }
                    return
                }
                
                let asset = AVURLAsset(url: podcastData.episodeUrl)
                let item = CachingPlayerItem(asset: asset, automaticallyLoadedAssetKeys: nil)
                
                self.podcastItems[podcastData.episodeUrl.absoluteString] = item
                
                DispatchQueue.main.async {
                    playAssetAfterLoad(item)
                }
            }
        }
        
        func playAssetAfterLoad(_ playerItem: CachingPlayerItem) {
            if self.player == nil {
                self.player = AVPlayer(playerItem: playerItem)
            } else {
                self.player?.replaceCurrentItem(with: playerItem)
            }
            
            self.player?.rate = podcastData.speed
            self.player?.pause()
            self.player?.automaticallyWaitsToMinimizeStalling = false
            
            if let currentTime = podcastData.currentTime, currentTime > 0 {
                self.player?.seek(to: CMTime(seconds: Double(currentTime), preferredTimescale: 1)) { _ in
                    self.player?.play()
                    self.didStartPlaying(playerItem)
                }
            } else {
                self.player?.play()
                self.didStartPlaying(playerItem)
            }
        }
    }
    
    func didStartPlaying(_ playerItem: AVPlayerItem) {
        guard let podcastData = self.podcastData else {
            return
        }
        
        let duration = getDuration(playerItem: playerItem)
        self.podcastData?.duration = duration
        
        updatePodcastObject(
            podcastId: podcastData.podcastId,
            duration: duration,
            clipInfo: podcastData.clipInfo
        )
        
        if (duration > 0) {
            shouldSyncPodcast()
            
            runPlayingStateUpdate()
            configureTimer()
            
            preloadNextEpisode()
            trackItemStarted()
        } else {
            player?.pause()

            runErrorStateUpdate()
        }
    }
    
    func preloadNextEpisode() {
        if let nextEpisode = podcast?.getNextEpisode() {
            let dispatchQueue = DispatchQueue.global(qos: .userInitiated)
            dispatchQueue.async {
                self.preloadEpisode(nextEpisode)
            }
        }
    }
    
    func pause(
        _ podcastData: PodcastData
    ) {
        pausePlaying()
                
        trackItemFinished()

        guard let player = player, let item = player.currentItem else {
            return
        }

        let duration = Int(Double(item.asset.duration.value) / Double(item.asset.duration.timescale))
        let currentTime = Int(round(Double(player.currentTime().value) / Double(player.currentTime().timescale)))
        
        self.podcastData?.currentTime = currentTime
        self.podcastData?.duration = duration
        
        updatePodcastObject(
            podcastId: podcastData.podcastId,
            currentTime: currentTime,
            duration: duration,
            clipInfo: podcastData.clipInfo
        )

        runPausedStateUpdate()
    }
    
    func pausePlaying() {
        player?.pause()
        invalidateTime()
    }
    
    func pausePlayingClip() {
        if let podcastData = podcastData, let _ = podcastData.clipInfo?.messageId {
            pausePlaying()
        }
    }
    
    func seek(
        _ podcastData: PodcastData
    ) {
        let previousTime = self.podcastData?.currentTime
        
        guard let currentTime = podcastData.currentTime else {
            return
        }
        
        updatePodcastObject(
            podcastId: podcastData.podcastId,
            currentTime: currentTime,
            clipInfo: podcastData.clipInfo
        )
        
        if self.podcastData?.podcastId != podcastData.podcastId {
            runPausedStateUpdateFor(podcastData: podcastData)
            ///Avoid player actions if performing actions for a podcast that is not the current set on player controller
            return
        }
        
        if let messageId = self.podcastData?.clipInfo?.messageId, messageId != podcastData.clipInfo?.messageId {
            runPausedStateUpdateFor(podcastData: podcastData)
            ///Avoid player actions if performing actions for a podcast that is not the current set on player controller
            return
        }
        
        self.podcastData?.currentTime = currentTime
        
        if let sound = sounds.randomElement() {
            soundsPlayer.playSound(name: sound)
        }
        
        if let player = player,
           let _ = player.currentItem {
            
            configurePlayingInfoCenter()
            invalidateTime()
            
            player.seek(to: CMTime(seconds: Double(currentTime), preferredTimescale: 1)) { _ in
                if self.isPlaying {
                    self.trackItemStarted(endTimestamp: previousTime)
                    /// If playing start timer again to update UI every X seconds
                    self.configureTimer()
                } else {
                    /// If not playing run pause state delegate to update UI in case seek was triggered from control center
                    self.runPausedStateUpdate()
                }
            }
        }
    }
    
    func adjustSpeed(
        _ podcastData: PodcastData
    ) {
        updatePodcastObject(
            podcastId: podcastData.podcastId,
            playerSpeed: podcastData.speed,
            clipInfo: podcastData.clipInfo
        )
        
        if self.podcastData?.podcastId != podcastData.podcastId {
            ///Avoid player actions if performing actions for a podcast that is not the current on set on player controller
            return
        }
        
        if let messageId = self.podcastData?.clipInfo?.messageId, messageId != podcastData.clipInfo?.messageId {
            ///Avoid player actions if performing actions for a podcast that is not the current set on player controller
            return
        }
        
        self.podcastData?.speed = podcastData.speed
        
        if let player = player, isPlaying {
            player.playImmediately(atRate: podcastData.speed)
            configureTimer()
        }
    }
}

extension PodcastPlayerController {
    func runLoadingStateUpdate() {
        isLoadingOrPlaying = true
        
        guard let podcastData = podcastData else {
            return
        }
        
        for (k, d) in self.delegates {
            
            ///Avoid calling delegates when playing chat clip
            if let _ = podcastData.clipInfo?.messageId, k != PodcastDelegateKeys.ChatDataSource.rawValue {
                continue
            }
            
            d.loadingState(podcastData)
        }
    }
    
    func runPlayingStateUpdate() {
        isLoadingOrPlaying = true
        
        guard let podcastData = podcastData else {
            return
        }
        
        for (k, d) in self.delegates {
            
            ///Avoid calling delegates when playing chat clip
            if let _ = podcastData.clipInfo?.messageId, k != PodcastDelegateKeys.ChatDataSource.rawValue {
                continue
            }
            
            d.playingState(podcastData)
        }
    }
    
    func runPausedStateUpdate() {
        isLoadingOrPlaying = false
        
        guard let podcastData = podcastData else {
            return
        }
        
        for (k, d) in self.delegates {
            
            ///Avoid calling delegates when playing chat clip
            if let _ = podcastData.clipInfo?.messageId, k != PodcastDelegateKeys.ChatDataSource.rawValue {
                continue
            }
            
            d.pausedState(podcastData)
        }
        
        shouldSyncPodcast()
    }
    
    func runPausedStateUpdateFor(podcastData: PodcastData) {
        for (k, d) in self.delegates {
            
            ///Avoid calling delegates when playing chat clip
            if let _ = podcastData.clipInfo?.messageId, k != PodcastDelegateKeys.ChatDataSource.rawValue {
                continue
            }
            
            d.pausedState(podcastData)
        }
    }
    
    func runEndedStateUpdate() {
        isLoadingOrPlaying = false
        
        guard let podcastData = podcastData else {
            return
        }
        
        for (k, d) in self.delegates {
            
            ///Avoid calling delegates when playing chat clip
            if let _ = podcastData.clipInfo?.messageId, k != PodcastDelegateKeys.ChatDataSource.rawValue {
                continue
            }
            
            d.endedState(podcastData)
        }
        
        shouldSyncPodcast()
        handlePodcastQueue()
    }
    
    func runErrorStateUpdate() {
        isLoadingOrPlaying = false
        
        guard let podcastData = podcastData else {
            return
        }
        
        for (k, d) in self.delegates {
            
            ///Avoid calling delegates when playing chat clip
            if let _ = podcastData.clipInfo?.messageId, k != PodcastDelegateKeys.ChatDataSource.rawValue {
                continue
            }
            
            d.errorState(podcastData)
        }
    }
    
    func handlePodcastQueue(){
        if let nextTrack = FeedsManager.sharedInstance.queuedPodcastEpisodes.first,
           let data = nextTrack.feed?.getPodcastData(episodeId: nextTrack.itemID){
            FeedsManager.sharedInstance.queuedPodcastEpisodes.removeAll(where: {$0.itemID == nextTrack.itemID})
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.play(data)
            })
        }
    }
}

