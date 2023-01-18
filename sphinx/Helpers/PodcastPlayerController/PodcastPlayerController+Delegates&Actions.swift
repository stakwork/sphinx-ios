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
        }
    }
}

extension PodcastPlayerController {

    func play(
        _ podcastData: PodcastData
    ) {
        setAudioSession()
        
        if let pd = self.podcastData, isPlaying {
            if podcastData.episodeId == pd.episodeId {
                ///If playing same episode, then return
                return
            } else {
                ///If playing another episode, then pause first
                pausePlaying()
            }
        }
        
        for d in self.delegates.values {
            d.loadingState(podcastData)
        }
        
        self.podcastData = podcastData
        
        updatePodcastObject(
            podcastId: podcastData.podcastId,
            episodeId: podcastData.episodeId,
            currentTime: podcastData.currentTime,
            duration: podcastData.duration,
            playerSpeed: podcastData.speed
        )
        
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
            
            let asset = AVAsset(url: podcastData.episodeUrl)
            let playerItem = AVPlayerItem(asset: asset)
            
            asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                DispatchQueue.main.async {
                    
                    if self.player == nil {
                        self.player = AVPlayer(playerItem: playerItem)
                        self.player?.automaticallyWaitsToMinimizeStalling = false
                        self.player?.rate = podcastData.speed
                    } else {
                        self.player?.replaceCurrentItem(with: playerItem)
                    }
                    
                    self.player?.pause()
                    self.player?.seek(to: CMTime(seconds: Double(podcastData.currentTime ?? 0), preferredTimescale: 1))
                    self.player?.playImmediately(atRate: podcastData.speed)
                    
                    self.didStartPlaying(playerItem)
                }
            })
        }
    }
    
    func didStartPlaying(_ playerItem: AVPlayerItem) {
        guard let podcastData = self.podcastData else {
            return
        }
        
        let duration = Int(Double(playerItem.asset.duration.value) / Double(playerItem.asset.duration.timescale))
        
        self.podcastData?.duration = duration
        
        updatePodcastObject(
            podcastId: podcastData.podcastId,
            duration: duration
        )
        
        if (duration > 0) {
            
            for d in self.delegates.values {
                d.playingState(podcastData)
            }
            
            self.configureTimer()
            
//                    trackItemStarted(endTimestamp: previousItemTimestamp)
        } else {
            self.player?.pause()
            
            for d in self.delegates.values {
                d.errorState(podcastData)
            }
        }
    }
    
    func pause(
        _ podcastData: PodcastData
    ) {
        pausePlaying()
        
//      trackItemFinished()

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
            duration: duration
        )
        
        guard let podcastData = self.podcastData else {
           return
        }

        for d in delegates.values {
            d.pausedState(podcastData)
        }
    }
    
    func pausePlaying() {
        player?.pause()
        invalidateTime()
    }
    
    func invalidateTime() {
        playingTimer?.invalidate()
        playingTimer = nil
        
        paymentsTimer?.invalidate()
        paymentsTimer = nil
    }
    
    func seek(
        _ podcastData: PodcastData
    ) {
        guard let currentTime = podcastData.currentTime else {
            return
        }
        
        updatePodcastObject(
            podcastId: podcastData.podcastId,
            currentTime: currentTime
        )
        
        if self.podcastData == nil {
            ///If seeking on player before playing, podcastData is nil, then it needs to be set
            self.podcastData = podcastData
        }
        
        if self.podcastData?.podcastId != podcastData.podcastId {
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
                    /// If playing start time again to update UI every X seconds
                    self.configureTimer()
                } else {
                    /// If not playing run pause state delegate to update UI in case seek was triggered from control center
                    for d in self.delegates.values {
                        d.pausedState(podcastData)
                    }
                }
            }
        }
    }
    
    func adjustSpeed(
        _ podcastData: PodcastData
    ) {
        if self.podcastData?.podcastId != podcastData.podcastId {
            ///Avoid player actions if performing actions for a podcast that is not the current on set on player controller
            return
        }
        
        self.podcastData?.speed = podcastData.speed
        
        if let player = player, isPlaying {
            player.playImmediately(atRate: podcastData.speed)
            configureTimer()
        }
    }
    
    func isPlaying(
        podcastId: String
    ) -> Bool {
        return isPlaying && podcastData?.podcastId == podcastId
    }
    
    func isPlaying(
        episodeId: String
    ) -> Bool {
        return isPlaying && podcastData?.episodeId == episodeId
    }
    
    func isPlayerItemSetWith(
        episodeUrl: URL
    ) -> Bool {
        return ((player?.currentItem?.asset) as? AVURLAsset)?.url.absoluteString == episodeUrl.absoluteString
    }
    
    var isPlaying: Bool {
        get {
            return player?.timeControlStatus == AVPlayer.TimeControlStatus.playing ||
                   player?.timeControlStatus == AVPlayer.TimeControlStatus.waitingToPlayAtSpecifiedRate
        }
    }
    
    func configureTimer() {
        playingTimer?.invalidate()
        playingTimer = Timer.scheduledTimer(
            timeInterval: Double(1) / Double(podcastData?.speed ?? 1.0),
            target: self,
            selector: #selector(updateCurrentTime),
            userInfo: nil,
            repeats: true
        )
        
        paymentsTimer?.invalidate()
        paymentsTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(updatePlayedTime),
            userInfo: nil,
            repeats: true
        )
    }
    
    @objc func updateCurrentTime() {
        guard let player = player, let item = player.currentItem else {
            return
        }
        
        let duration = Int(Double(item.asset.duration.value) / Double(item.asset.duration.timescale))
        let currentTime = Int(round(Double(player.currentTime().value) / Double(player.currentTime().timescale)))

        guard let podcastData = podcastData else {
            return
        }
        
        self.podcastData?.currentTime = currentTime
        self.podcastData?.duration = duration
        
        updatePodcastObject(
            podcastId: podcastData.podcastId,
            currentTime: currentTime,
            duration: duration
        )

        for d in delegates.values {
            d.playingState(podcastData)
        }

        configurePlayingInfoCenter()

        if currentTime >= duration {
            didEndEpisode()
        }
    }
    
    func didEndEpisode() {
//        trackItemFinished(shouldSaveAction: true)
        pausePlaying()
        
        guard let podcastData = self.podcastData else {
            return
        }
        
        self.podcastData?.currentTime = 0
        
        updatePodcastObject(
            podcastId: podcastData.podcastId,
            currentTime: 0
        )
        
        for d in delegates.values {
            d.endedState(podcastData)
        }
    }
}

extension PodcastPlayerController {
    func updatePodcastObject(
        podcastId: String,
        episodeId: String? = nil,
        currentTime: Int? = nil,
        duration: Int? = nil,
        playerSpeed: Float? = nil
    ) {
        ///Updates attributes on podcast object to be persisted in UserDeftaults
        
        guard let podcast = getPodcastWith(podcastId: podcastId) else {
            return
        }
        
        if let episodeId = episodeId {
            podcast.currentEpisodeId = episodeId
        }
        
        if let currentTime = currentTime {
            podcast.currentTime = currentTime
        }
        
        if let duration = duration {
            podcast.duration = duration
        }
        
        if let playerSpeed = playerSpeed {
            podcast.playerSpeed = playerSpeed
        }
        
    }
    
    func getPodcastWith(podcastId: String) -> PodcastFeed? {
        var podcast: PodcastFeed? = nil
        
        if let pd = self.podcast, pd.feedID == podcastId {
            podcast = pd
        } else {
            if let contentFeed = ContentFeed.getFeedWith(feedId: podcastId) {
                let podcastFeed = PodcastFeed.convertFrom(contentFeed: contentFeed)
                
                podcast = podcastFeed
            }
        }
        
        return podcast
    }
}

