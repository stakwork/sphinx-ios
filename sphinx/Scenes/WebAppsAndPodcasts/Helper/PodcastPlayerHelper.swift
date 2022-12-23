//
//  PodcastPlayerHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 08/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import AVKit
import MediaPlayer
import SwiftyJSON

@objc protocol PodcastPlayerDelegate : class {
    func playingState(podcastId: String, duration: Int, currentTime: Int)
    func pausedState(podcastId: String, duration: Int, currentTime: Int)
    func loadingState(podcastId: String, loading: Bool)
    func errorState(podcastId: String)
}

class PodcastPlayerHelper {
    
    class var sharedInstance : PodcastPlayerHelper {
        
        struct Static {
            static let instance = PodcastPlayerHelper()
        }
        
        return Static.instance
    }
    
    init() {
        setupNowPlayingInfoCenter()
    }
    
    var delegates = [String : PodcastPlayerDelegate]()
    
    enum DelegateKeys: String {
        case smallPlayer = "smallPlayer"
        case podcastPlayerVC = "podcastPlayerVC"
        case dashboard = "dashboardSmallPlayer"
        case recommendationsPlayer = "recommendationsPlayer"
    }
    
    func addDelegate(
        _ delegate: PodcastPlayerDelegate,
        withKey key: String
    ) {
        self.delegates[key] = delegate
    }
    
    func removeFromDelegatesWith(key: String) {
        self.delegates.removeValue(forKey: key)
    }
    
    var player: AVPlayer?
    var playingTimer : Timer? = nil
    var paymentsTimer : Timer? = nil
    var playingEpisodeImage: UIImage? = nil
    var playedSeconds: Int = 0
    
    func setAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP, .duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {}
        
        let session = AVAudioSession.sharedInstance()
        
        NotificationCenter.default.removeObserver(
            self,
            name: AVAudioSession.interruptionNotification,
            object: session
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handleInterruption(notification:)),
            name: AVAudioSession.interruptionNotification,
            object: session
        )
    }
    
    @objc func handleInterruption(notification: NSNotification) {
        if notification.name != AVAudioSession.interruptionNotification ||
            notification.userInfo == nil {
            
            return
        }
        let info = notification.userInfo!
        var intValue: UInt = 0
        
        (info[AVAudioSessionInterruptionTypeKey] as! NSValue).getValue(&intValue)
        
        if let interruptionType = AVAudioSession.InterruptionType(rawValue: intValue) {
            switch interruptionType {
            case .began:
                self.shouldPause()
            default:
                break
            }
        }
    }
    
    let audioPlayerHelper = PlayAudioHelper()
    let podcastPaymentsHelper = PodcastPaymentsHelper()
    let actionsManager = ActionsManager.sharedInstance
    
    public static let kClipPrefix = "clip::"
    public static let kBoostPrefix = "boost::"
    public static let kSecondsBeforePMT = 60
    
    let sounds = [
        "skip30v1.caf",
        "skip30v2.caf",
        "skip30v3.caf",
        "skip30v4.caf"
    ]
    
    var podcast: PodcastFeed? = nil
    var recommendationsPodcast: PodcastFeed? = nil
    
    var chat: Chat? {
        get {
            return podcast?.chat
        }
    }
    
    func resetPodcast(_ podcast: PodcastFeed) {
        trackItemFinished(shouldSaveAction: true)
        stopPlaying()
        self.podcast = podcast
    }
    
    func getBoostMessage(amount: Int) -> String? {
        guard let podcast = self.podcast else {
            return nil
        }
        
        let feedID = Int(podcast.feedID) ?? -1
        let itemID = Int(podcast.getCurrentEpisode()?.itemID ?? "") ?? -1
        
        guard feedID > 0 else {
            return nil
        }
        
        guard itemID > 0 else {
            return nil
        }
        
        if amount == 0 {
            return nil
        }
        
        return "{\"feedID\":\(feedID),\"itemID\":\(itemID),\"ts\":\(podcast.currentTime),\"amount\":\(amount)}"
    }
    
    func loadEpisodeImage() {
        self.playingEpisodeImage = nil
        
        if let url = podcast?.getImageURL() {
            MediaLoader.loadDataFrom(
                URL: url,
                includeToken: false,
                completion: { (data, fileName) in
                    
                    if let img = UIImage(data: data) {
                        self.playingEpisodeImage = img
                    }
                }, errorCompletion: {
                    self.playingEpisodeImage = nil
                }
            )
        }
        
        configurePlayingInfoCenter(duration: 0, currentTime: 0)
    }
    
    func getIndexFor(
        episode: PodcastEpisode,
        in podcast: PodcastFeed
    ) -> Int? {
        podcast.episodesArray.firstIndex(where: { $0.itemID == episode.itemID })
    }
    
    func prepareEpisodeWith(
        index: Int,
        in podcast: PodcastFeed,
        autoPlay: Bool = false,
        completion: @escaping () -> ()
    ) {
        
        if podcast.feedID != self.podcast?.feedID {
            resetPodcast(podcast)
        }
        
        guard let podcast = self.podcast else {
            return
        }

        if podcast.episodesArray.count <= index {
            return
        }
        
        let episode = podcast.episodesArray[index]
        
        if !episode.isAvailable() {
            return
        }
        
        guard let episodeUrl = episode.urlPath, !episodeUrl.isEmpty else {
            return
        }
        
        let didChangeEpisode = setNewEpisodeWith(
            index: index,
            in: podcast,
            episodeId: episode.itemID
        )
        
        for d in self.delegates.values {
            d.loadingState(podcastId: podcast.feedID, loading: true)
        }
        
        if didChangeEpisode {
            shouldPause()
            
            podcast.currentTime = 0
            
            for d in self.delegates.values {
                d.playingState(podcastId: podcast.feedID, duration: 0, currentTime: 0)
            }
        }
        
        loadEpisodeImage()
        
        loadAndPlayEpisodeOn(
            podcast,
            autoPlay: autoPlay,
            completion: completion
        )
    }
    
    func setNewEpisodeWith(
        index: Int,
        in podcast: PodcastFeed,
        episodeId: String
    ) -> Bool {
        podcast.currentEpisodeIndex = index
        
        if (podcast.currentEpisodeId != episodeId) {
            
            trackItemFinished(shouldSaveAction: true)
            
            podcast.currentEpisodeId = episodeId
            
            return true
        }
        return false
    }
    
    func setNewEpisodeWith(
        episodeId: String,
        in podcast: PodcastFeed
    ) -> Bool {
        if (podcast.currentEpisodeId != episodeId) {
            
            self.podcast = podcast
            
            trackItemFinished(shouldSaveAction: true)
            
            podcast.currentEpisodeId = episodeId
            podcast.currentEpisodeIndex = podcast.getCurrentEpisodeIndex()
            
            return true
        }
        return false
    }
    
    func loadAndPlayEpisodeOn(
        _ podcast: PodcastFeed,
        autoPlay: Bool,
        completion: @escaping () -> ()
    ) {
        if let url = podcast.getCurrentEpisode()?.getAudioUrl() {
            
            let asset = AVAsset(url: url)
            
            asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                
                let playerItem = AVPlayerItem(asset: asset)
                
                if self.player == nil {
                    self.player = AVPlayer(playerItem:playerItem)
                    self.player?.rate = podcast.playerSpeed;
                } else {
                    self.player?.replaceCurrentItem(with: playerItem)
                }
                
                self.player?.seek(
                    to: CMTime(seconds: Double(podcast.currentTime), preferredTimescale: 1)
                )
                
                DispatchQueue.main.async {
                    if autoPlay {
                        self.shouldPlay()
                    } else {
                        self.shouldPause()
                    }
                    completion()
                }
            })
        }
    }
    
    func configureTimer() {
        playingTimer?.invalidate()
        playingTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(updateCurrentTime), userInfo: nil, repeats: true)
        
        paymentsTimer?.invalidate()
        paymentsTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updatePlayedTime), userInfo: nil, repeats: true)
    }
    
    @objc func updateCurrentTime() {
        guard let podcast = podcast else {
            return
        }
        
        guard let player = player, let item = player.currentItem else {
            return
        }
        
        let duration = Int(Double(item.asset.duration.value) / Double(item.asset.duration.timescale))
        let currentTime = Int(round(Double(player.currentTime().value) / Double(player.currentTime().timescale)))
         
        if currentTime == podcast.currentTime + 1 {
            
            for d in delegates.values {
                d.playingState(podcastId: podcast.feedID, duration: duration, currentTime: currentTime)
            }
            
            configurePlayingInfoCenter(duration: duration, currentTime: currentTime)
        }
        
        podcast.currentTime = currentTime
        
        if currentTime >= duration {
            didEndEpisode()
        }
    }
    
    func didEndEpisode() {
        trackItemFinished(shouldSaveAction: true)
        shouldPause()
        
        if let podcast = self.podcast {
            let _ = move(podcast, toEpisodeWith: podcast.currentEpisodeIndex - 1)
            chat?.updateMetaData()
        }
    }
    
    @objc func updatePlayedTime() {
        playedSeconds = playedSeconds + 1
        
        if playedSeconds > 0 && playedSeconds % PodcastPlayerHelper.kSecondsBeforePMT == 0 {
            DispatchQueue.global().async {
                self.processPayment()
            }
        }
    }
    
    func processPayment(amount: Int? = nil) {
        guard let podcast = podcast else {
            return
        }
        
        podcastPaymentsHelper
            .processPaymentsFor(
                podcastFeed: podcast,
                boostAmount: amount,
                itemId: podcast.getCurrentEpisode()?.itemID ?? "",
                currentTime: podcast.currentTime
            )
    }
    
    func didStartDraggingProgressFor(
        _ podcast: PodcastFeed
    ) {
        if podcast.feedID != self.podcast?.feedID {
            return
        }
        shouldPause()
    }
    
    func shouldPause() {
        if isPlaying() {
            player?.pause()
            playingTimer?.invalidate()
            paymentsTimer?.invalidate()
            
            trackItemFinished()
        }
        
        guard let podcast = podcast else {
            return
        }
        
        guard let player = player, let item = player.currentItem else {
            return
        }
        
        let duration = Int(Double(item.asset.duration.value) / Double(item.asset.duration.timescale))
        let currentTime = Int(round(Double(player.currentTime().value) / Double(player.currentTime().timescale)))
        
        for d in delegates.values {
            d.pausedState(podcastId: podcast.feedID, duration: duration, currentTime: currentTime)
        }
    }
    
    func shouldPlay(
        previousItemTimestamp: Int? = nil
    ) {
        guard let podcast = podcast else {
            return
        }
        
        setAudioSession()
        
        for d in delegates.values {
            d.loadingState(podcastId: podcast.feedID, loading: true)
        }
        
        if let player = player {
            player.seek(to: CMTime(seconds: Double(podcast.currentTime), preferredTimescale: 1))
            player.playImmediately(atRate: podcast.playerSpeed)
            
            guard let item = player.currentItem else {
                return
            }
            
            let duration = Int(Double(item.asset.duration.value) / Double(item.asset.duration.timescale))
            
            if (duration > 0) {
                for d in delegates.values {
                    d.playingState(podcastId: podcast.feedID, duration: duration, currentTime: podcast.currentTime)
                }
                
                configureTimer()
                
                trackItemStarted(endTimestamp: previousItemTimestamp)
            } else {
                for d in delegates.values {
                    d.errorState(podcastId: podcast.feedID)
                }
            }
        } else {
            prepareEpisodeWith(index: podcast.currentEpisodeIndex, in: podcast, autoPlay: true, completion: {})
        }
    }
    
    func isPlaying(_ chatId: Int) -> Bool {
        
        let playing = player?.timeControlStatus == AVPlayer.TimeControlStatus.playing ||
                    player?.timeControlStatus == AVPlayer.TimeControlStatus.waitingToPlayAtSpecifiedRate
        
        return playing && self.chat?.id == chatId
    }
    
    func isPlaying(
        _ podcastId: String? = nil
    ) -> Bool {
        
        let playing = player?.timeControlStatus == AVPlayer.TimeControlStatus.playing ||
                    player?.timeControlStatus == AVPlayer.TimeControlStatus.waitingToPlayAtSpecifiedRate
        
        guard let podcastId = podcastId else {
            return playing
        }
        
        return playing && self.podcast?.feedID == podcastId
    }
    
    func isPlayingRecommendations() -> Bool {
        return (isPlaying() && podcast?.isRecommendationsPodcast == true)
    }
    
    func togglePlayStateFor(
        _ podcast: PodcastFeed
    ) {
        if podcast.feedID != self.podcast?.feedID {
            resetPodcast(podcast)
        }
        if isPlaying(podcast.feedID) {
            shouldPause()
        } else {
            shouldPlay()
        }
        chat?.updateMetaData()
    }
    
    func changeSpeedTo(
        value: Float,
        on podcast: PodcastFeed
    ) {
        if podcast.feedID != self.podcast?.feedID {
            podcast.playerSpeed = value
            podcast.chat?.updateMetaData()
            return
        }
        
        podcast.playerSpeed = value
        
        if let player = player, isPlaying(podcast.feedID) {
            player.playImmediately(atRate: value)
        }
        chat?.updateMetaData()
    }
    
    func stopPlaying() {
        player?.pause()
        player = nil
        
        playingTimer?.invalidate()
        playingTimer = nil
        
        paymentsTimer?.invalidate()
        paymentsTimer = nil
    }
    
    func shouldUpdateTimeLabelsTo(
        progress: Double,
        with duration: Int,
        in podcast: PodcastFeed
    ) {
        let playing = isPlaying(podcast.feedID)
        let currentTime = Double(duration) * progress
        
        for d in delegates.values {
            if playing {
                d.playingState(podcastId: podcast.feedID, duration: Int(duration), currentTime: Int(currentTime))
            } else {
                d.pausedState(podcastId: podcast.feedID, duration: Int(duration), currentTime: Int(currentTime))
            }
        }
    }
    
    func seek(
        _ podcast: PodcastFeed,
        to progress: Double,
        playAfterSeek: Bool
    ) {
        if podcast.feedID != self.podcast?.feedID {
            if let episode = podcast.getCurrentEpisode(), let duration = episode.duration {
                podcast.currentTime = Int(Double(duration) * progress)
            }
            return
        }
        
        if let player = player, let item = player.currentItem {
            let duration = Double(item.asset.duration.value) / Double(item.asset.duration.timescale)
            seekTo(newTime: round(duration * progress), playAfterSeek: playAfterSeek)
        }
    }
    
    func seek(
        _ podcast: PodcastFeed,
        to seconds: Double
    ) {
        var newTime = podcast.currentTime + Int(seconds)
        newTime = newTime > 0 ? newTime : 0
        
        if podcast.feedID != self.podcast?.feedID {
            podcast.currentTime = newTime
            return
        }
        
        if let player = player, let _ = player.currentItem {
            seekTo(newTime: Double(newTime), playAfterSeek: true)
        }
    }
    
    func seekTo(
        newTime: Double,
        playAfterSeek: Bool
    ) {
        guard let podcast = podcast else {
            return
        }
        
        let endTimestamp = isPlaying() ? podcast.currentTime : nil
        
        if let player = player, let item = player.currentItem {
            let duration = Double(item.asset.duration.value) / Double(item.asset.duration.timescale)
            player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
            
            podcast.currentTime = Int(newTime)
            
            configurePlayingInfoCenter(duration: Int(duration), currentTime: Int(newTime), forceUpdate: playAfterSeek)
        }
        
        if playAfterSeek {
            if let sound = sounds.randomElement() {
                audioPlayerHelper.playSound(name: sound)
            }
            
            shouldPlay(previousItemTimestamp: endTimestamp)
        }
    }
    
    func move(
        _ podcast: PodcastFeed,
        toEpisodeWith index: Int
    ) -> Bool {
        if index < podcast.episodesArray.count && index >= 0 {
            prepareEpisodeWith(
                index: index,
                in: podcast,
                autoPlay: isPlaying(podcast.feedID),
                completion: {}
            )
            return true
        }
        return false
    }
    
    func toggleFeedSubscriptionState() {
        podcast?.isSubscribedToFromSearch.toggle()
        CoreDataManager.sharedManager.saveContext()
    }
    
    //Info Center
    func configurePlayingInfoCenter(duration: Int, currentTime: Int, forceUpdate: Bool = false) {
        let playingCenter = MPNowPlayingInfoCenter.default()

        guard let podcast = self.podcast else {
            playingCenter.nowPlayingInfo = nil
            return
        }

        guard let episode = podcast.getCurrentEpisode() else {
            playingCenter.nowPlayingInfo = nil
            return
        }
        
        let size = self.playingEpisodeImage?.size ?? CGSize.zero
        let artwork = MPMediaItemArtwork.init(boundsSize: size, requestHandler: { (size) -> UIImage in
            return self.playingEpisodeImage ?? UIImage()
        })
        
        if player?.timeControlStatus != AVPlayer.TimeControlStatus.playing && !forceUpdate {
            return
        }
        
        playingCenter.nowPlayingInfo = [
            MPMediaItemPropertyMediaType: "\(MPMediaType.podcast)",
            MPMediaItemPropertyPodcastTitle: podcast.title ?? "",
            MPMediaItemPropertyArtwork: artwork,
            MPMediaItemPropertyPodcastPersistentID: podcast.id,
            MPMediaItemPropertyTitle: episode.title ?? "",
            MPMediaItemPropertyArtist: podcast.author ?? "",
            MPMediaItemPropertyPlaybackDuration: "\(duration)",
            MPNowPlayingInfoPropertyElapsedPlaybackTime: "\(currentTime)",
            MPNowPlayingInfoPropertyPlaybackRate: podcast.playerSpeed,
            MPMediaItemPropertyAlbumTrackCount: "\(podcast.episodesArray.count)",
            MPMediaItemPropertyAlbumTrackNumber: "\(podcast.currentEpisodeIndex)",
            MPMediaItemPropertyAssetURL: episode.urlPath ?? ""
        ]
    }
    
    func setupNowPlayingInfoCenter() {
        MPRemoteCommandCenter.shared().playCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().pauseCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().nextTrackCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().previousTrackCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().skipBackwardCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().skipForwardCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().seekForwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().seekBackwardCommand.isEnabled = true
        
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            if let changePlaybackPositionCommandEvent = event as? MPChangePlaybackPositionCommandEvent
            {
                let positionTime = changePlaybackPositionCommandEvent.positionTime
                self.seekTo(newTime: positionTime, playAfterSeek: true)
                return .success
            } else {
                return .commandFailed
            }
        }
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled = true
        
        MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [15]
        MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [30]
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        MPRemoteCommandCenter.shared().playCommand.addTarget {event in
            self.shouldPlay()
            return .success
        }
        MPRemoteCommandCenter.shared().pauseCommand.addTarget {event in
            self.shouldPause()
            return .success
        }
        MPRemoteCommandCenter.shared().skipBackwardCommand.addTarget {event in
            if let podcast = self.podcast {
                self.seek(podcast, to: -15)
                return .success
            }
            return .commandFailed
        }
        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget {event in
            if let podcast = self.podcast {
                self.seek(podcast, to: 30)
                return .success
            }
            return .commandFailed
        }
    }
    
    func trackItemStarted(
        endTimestamp: Int? = nil
    ) {
        if let podcast = podcast,
            let episode = podcast.getCurrentEpisode() {
            
            if let feedItem: ContentFeedItem = ContentFeedItem.getItemWith(itemID: episode.itemID) {
                actionsManager.trackItemConsumed(
                    item: feedItem,
                    startTimestamp: podcast.currentTime,
                    endTimestamp: endTimestamp
                )
            } else if podcast.isRecommendationsPodcast {
                actionsManager.trackItemConsumed(
                    item: episode,
                    podcast: podcast,
                    startTimestamp: podcast.currentTime,
                    endTimestamp: endTimestamp
                )
            }
        }
    }

    func trackItemFinished(
        shouldSaveAction: Bool = false
    ) {
        if let podcast = podcast,
            let episode = podcast.getCurrentEpisode() {
            
            if let feedItem: ContentFeedItem = ContentFeedItem.getItemWith(itemID: episode.itemID) {
                actionsManager.trackItemFinished(
                    item: feedItem,
                    timestamp: podcast.currentTime,
                    shouldSaveAction: shouldSaveAction
                )
            } else if podcast.isRecommendationsPodcast {
                actionsManager.trackItemFinished(
                    item: episode,
                    podcast: podcast,
                    timestamp: podcast.currentTime,
                    shouldSaveAction: shouldSaveAction
                )
            }
        }
    }
    
    func finishAndSaveContentConsumed() {
        if !isPlaying() {
            actionsManager.finishAndSaveContentConsumed()
        }
    }
}
