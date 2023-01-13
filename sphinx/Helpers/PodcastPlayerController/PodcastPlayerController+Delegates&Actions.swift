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
            break
        }
    }
}

extension PodcastPlayerController {
    
    func stopPlaying() {
        player?.pause()
        player = nil
        
        playingTimer?.invalidate()
        playingTimer = nil
        
        paymentsTimer?.invalidate()
        paymentsTimer = nil
    }
    
    func play(
        _ podcastData: PodcastData
    ) {
        if podcastData.podcastId != self.podcastData?.podcastId {
            //Podcast changed. Need to reload some data
            
            pausePlaying()
            
            for d in self.delegates.values {
                d.loadingState(podcastData)
            }
        }
        
        self.podcastData = podcastData
        
        if let url = URL(string: podcastData.episodeUrl) {
            
            let asset = AVAsset(url: url)
            
            asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                
                let playerItem = AVPlayerItem(asset: asset)
                
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
            })
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
        playingTimer?.invalidate()
        paymentsTimer?.invalidate()
    }
    
    func seek(
        _ podcastData: PodcastData
    ) {
        if podcastData.episodeId != self.podcastData?.episodeId {
            //Update current time on podcastData
            return
        }
        
        if let player = player,
           let _ = player.currentItem,
           let currentTime = podcastData.currentTime {
            
            player.seek(to: CMTime(seconds: Double(currentTime), preferredTimescale: 1))
            
            configurePlayingInfoCenterWith(podcastData)
        }
    }
    
    func configureTimer() {
        playingTimer?.invalidate()
        playingTimer = Timer.scheduledTimer(
            timeInterval: 0.2,
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
        
        guard let podcastData = podcastData else {
            return
        }
        
        let duration = Int(Double(item.asset.duration.value) / Double(item.asset.duration.timescale))
        let currentTime = Int(round(Double(player.currentTime().value) / Double(player.currentTime().timescale)))
        
        self.podcastData?.currentTime = currentTime
         
        for d in delegates.values {
            d.playingState(podcastData)
        }
        
        configurePlayingInfoCenterWith(podcastData)
        
        //Set current time on podcast episode
        
        if currentTime >= duration {
            didEndEpisode()
        }
    }
    
    func didEndEpisode() {
//        trackItemFinished(shouldSaveAction: true)
//        pausePlaying()
        
//            let _ = move(podcast, toEpisodeWith: podcast.currentEpisodeIndex - 1)
//            chat?.updateMetaData()
        
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
