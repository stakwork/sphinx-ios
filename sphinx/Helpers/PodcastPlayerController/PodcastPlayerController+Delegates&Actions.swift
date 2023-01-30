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
                trackItemFinished(shouldSaveAction: true)
                pausePlaying()
                runPausedStateUpdate()
            }
        }
        
        self.podcastData = podcastData
        
        updatePodcastObject(
            podcastId: podcastData.podcastId,
            episodeId: podcastData.episodeId,
            currentTime: podcastData.currentTime,
            duration: podcastData.duration,
            playerSpeed: podcastData.speed
        )
        
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
            
            let asset = AVAsset(url: podcastData.episodeUrl)
            let playerItem = AVPlayerItem(asset: asset)
            
            asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                DispatchQueue.main.async {
                    
                    if self.player == nil {
                        self.player = AVPlayer(playerItem: playerItem)
                        self.player?.rate = podcastData.speed
                    } else {
                        self.player?.replaceCurrentItem(with: playerItem)
                    }
                    
                    self.player?.pause()
                    
                    self.player?.seek(to: CMTime(seconds: Double(podcastData.currentTime ?? 0), preferredTimescale: 1)) { _ in
                        self.player?.playImmediately(atRate: podcastData.speed)
                        self.didStartPlaying(playerItem)
                    }
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
            self.runPlayingStateUpdate()
            self.configureTimer()
            
            self.trackItemStarted()
        } else {
            self.player?.pause()

            runErrorStateUpdate()
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
            duration: duration
        )

        runPausedStateUpdate()
    }
    
    func pausePlaying() {
        player?.pause()
        invalidateTime()
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
            currentTime: currentTime
        )
        
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
            playerSpeed: podcastData.speed
        )
        
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
}

extension PodcastPlayerController {
    func runLoadingStateUpdate() {
        guard let podcastData = podcastData else {
            return
        }
        
        for d in self.delegates.values {
            d.loadingState(podcastData)
        }
    }
    
    func runPlayingStateUpdate() {
        guard let podcastData = podcastData else {
            return
        }
        
        for d in self.delegates.values {
            d.playingState(podcastData)
        }
    }
    
    func runPausedStateUpdate() {
        guard let podcastData = podcastData else {
            return
        }
        
        for d in self.delegates.values {
            d.pausedState(podcastData)
        }
    }
    
    func runEndedStateUpdate() {
        guard let podcastData = podcastData else {
            return
        }
        
        for d in self.delegates.values {
            d.endedState(podcastData)
        }
    }
    
    func runErrorStateUpdate() {
        guard let podcastData = podcastData else {
            return
        }
        
        for d in self.delegates.values {
            d.errorState(podcastData)
        }
    }
}

