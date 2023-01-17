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
                return
            } else {
                pausePlaying()
            }
        }
        
        for d in self.delegates.values {
            d.loadingState(podcastData)
        }
        
        self.podcastData = podcastData
        
        loadEpisodeImage()
        
        if isPlayerItemSetWith(episodeUrl: podcastData.episodeUrl) {
            
            player?.seek(to: CMTime(seconds: Double(podcastData.currentTime ?? 0), preferredTimescale: 1))
            player?.playImmediately(atRate: podcastData.speed)
            
            if let playerItem = player?.currentItem {
                self.didStartPlaying(playerItem)
            }
            
        } else {
            
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
        if let sound = sounds.randomElement() {
            soundsPlayer.playSound(name: sound)
        }
        
        if !isPlaying(podcastId: podcastData.podcastId) {
            return
        }
        
        if let player = player,
           let _ = player.currentItem,
           let currentTime = podcastData.currentTime {
            
            self.podcastData?.currentTime = currentTime
            
            self.invalidateTime()
            
            player.seek(to: CMTime(seconds: Double(currentTime), preferredTimescale: 1)) { _ in
                self.configureTimer()
            }
            
            configurePlayingInfoCenterWith()
        }
    }
    
    func adjustSpeed(
        _ podcastData: PodcastData
    ) {
        if !isPlaying(podcastId: podcastData.podcastId) {
            return
        }
        
        self.podcastData?.speed = podcastData.speed
        
        if let player = player {
            player.playImmediately(atRate: podcastData.speed)
        }
        
        configureTimer()
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
        
        self.podcastData?.currentTime = currentTime
        
        guard let podcastData = podcastData else {
            return
        }
         
        for d in delegates.values {
            d.playingState(podcastData)
        }
        
        configurePlayingInfoCenterWith()
        
        if currentTime >= duration {
            didEndEpisode()
        }
    }
    
    func didEndEpisode() {
//        trackItemFinished(shouldSaveAction: true)
        pausePlaying()

        self.podcastData?.currentTime = 0
        
        guard let podcastData = self.podcastData else {
            return
        }
        
        for d in delegates.values {
            d.endedState(podcastData)
        }
    }
    
    @objc func updatePlayedTime() {
//        playedSeconds = playedSeconds + 1
//        
//        if playedSeconds > 0 && playedSeconds % PodcastPlayerHelper.kSecondsBeforePMT == 0 {
//            DispatchQueue.global().async {
//                self.processPayment()
//            }
//        }
    }
}

