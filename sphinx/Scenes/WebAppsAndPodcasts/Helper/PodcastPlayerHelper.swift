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
}

class PodcastPlayerHelper {
    
    class var sharedInstance : PodcastPlayerHelper {
        
        struct Static {
            static let instance = PodcastPlayerHelper()
        }
        
        return Static.instance
    }
    
    var delegates = [String : PodcastPlayerDelegate]()
    
    enum DelegateKeys: String {
        case smallPlayer = "smallPlayer"
        case podcastPlayerVC = "podcastPlayerVC"
        case dashboard = "dashboard"
    }
    
    func addDelegate(
        _ del: PodcastPlayerDelegate,
        withKey key: String
    ) {
        self.delegates[key] = del
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
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {}
        
        let session = AVAudioSession.sharedInstance()
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleInterruption(notification:)), name: AVAudioSession.interruptionNotification, object: session)
    }
    
    @objc func handleInterruption(notification: NSNotification) {
        if notification.name != AVAudioSession.interruptionNotification || notification.userInfo == nil{
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
    
    var chat: Chat? {
        get {
            return podcast?.chat
        }
    }
    
    var currentEpisode: Int {
        get {
            return podcast?.currentEpisode ?? 0
        }
        set {
            podcast?.currentEpisode = newValue
        }
    }
    
    var currentEpisodeId: Int {
        get {
            return podcast?.currentEpisodeId ?? -1
        }
        set {
            podcast?.currentEpisodeId = newValue
        }
    }
    
    var lastEpisodeId: Int? {
        get {
            return podcast?.lastEpisodeId
        }
        set {
            podcast?.lastEpisodeId = newValue
        }
    }
    
    var currentTime: Int {
        get {
            return podcast?.currentTime ?? 0
        }
        set {
            podcast?.currentTime = newValue
        }
    }
    
    var playerSpeed: Float {
        get {
            return podcast?.playerSpeed ?? 1
        }
        set {
            podcast?.playerSpeed = newValue
        }
    }
    
    var isConfigured : Bool {
        get {
            return self.podcast != nil
        }
    }
    
    func resetPodcast(_ podcast: PodcastFeed) {
        stopPlaying()
        self.podcast = podcast
    }
    
    func getBoostMessage(amount: Int) -> String? {
        guard let podcast = self.podcast else {
            return nil
        }
        
        let feedID = Int(podcast.feedID) ?? -1
        let itemID = Int(getCurrentEpisode()?.itemID ?? "") ?? -1
        
        guard feedID > 0 else {
            return nil
        }
        
        guard itemID > 0 else {
            return nil
        }
        
        if amount == 0 {
            return nil
        }
        
        return "{\"feedID\":\(feedID),\"itemID\":\(itemID),\"ts\":\(currentTime),\"amount\":\(amount)}"
    }
    
    
    func getEpisodes() -> [PodcastEpisode] {
        podcast?.episodesArray ?? []
    }
    
    
    func getCurrentEpisode() -> PodcastEpisode? {
        return podcast?.getCurrentEpisode()
    }
    
    func getCurrentEpisodeIndex() -> Int {
        return podcast?.getCurrentEpisodeIndex() ?? 0
    }
    
    func getIndexFor(episode: PodcastEpisode, in podcast: PodcastFeed) -> Int? {
        podcast.episodesArray.firstIndex(where: { $0.itemID == episode.itemID })
    }
    
    func prepareEpisode(
        index: Int,
        in podcast: PodcastFeed,
        autoPlay: Bool = false,
        resetTime: Bool = false,
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
        
        for d in self.delegates.values {
            d.loadingState(podcastId: podcast.feedID, loading: true)
        }
        
        currentEpisode = index
        currentEpisodeId = Int(episode.itemID) ?? -1
        currentTime = resetTime ? 0 : currentTime
        
        loadEpisodeImage()
        
        loadAndPlayEpisode(autoPlay: autoPlay, completion: completion)
    }
    
    func loadAndPlayEpisode(autoPlay: Bool, completion: @escaping () -> ()) {
        shouldPause()
        
        if let url = getCurrentEpisode()?.getAudioUrl() {
            
            let asset = AVAsset(url: url)
            
            asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                
                let playerItem = AVPlayerItem(asset: asset)
                
                if self.player == nil {
                    self.player = AVPlayer(playerItem:playerItem)
                    self.player?.rate = self.playerSpeed;
                } else {
                    self.player?.replaceCurrentItem(with: playerItem)
                }
                
                self.player?.seek(to: CMTime(seconds: Double(self.currentTime), preferredTimescale: 1))
                
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
    
    func loadEpisodeImage() {
        self.playingEpisodeImage = nil
        
        if let url = podcast?.getImageURL() {
            MediaLoader.loadDataFrom(URL: url, includeToken: false, completion: { (data, fileName) in
                if let img = UIImage(data: data) {
                    self.playingEpisodeImage = img
                }
            }, errorCompletion: {
                self.playingEpisodeImage = nil
            })
        }
        
        configurePlayingInfoCenter(duration: 0, currentTime: 0)
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
         
        if currentTime == self.currentTime + 1 {
            
            for d in delegates.values {
                d.playingState(podcastId: podcast.feedID, duration: duration, currentTime: currentTime)
            }
            
            configurePlayingInfoCenter(duration: duration, currentTime: currentTime)
        }
        
        self.currentTime = currentTime
        
        if currentTime >= duration {
            didEndEpisode()
        }
    }
    
    func didEndEpisode() {
        shouldPause()
        
        if let podcast = self.podcast {
            let _ = move(podcast, toEpisodeWith: currentEpisode - 1)
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
        podcastPaymentsHelper
            .processPaymentsFor(
                podcastFeed: podcast,
                boostAmount: amount,
                itemId: getCurrentEpisode()?.itemID ?? "",
                currentTime: currentTime
            )
    }
    
    func shouldPause() {
        if isPlaying() {
            player?.pause()
            playingTimer?.invalidate()
            paymentsTimer?.invalidate()
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
    
    func shouldPlay() {
        guard let podcast = podcast else {
            return
        }
        
        setAudioSession()
        
        for d in delegates.values {
            d.loadingState(podcastId: podcast.feedID, loading: true)
        }
        
        if let player = player {
            player.seek(to: CMTime(seconds: Double(currentTime), preferredTimescale: 1))
            player.playImmediately(atRate: self.playerSpeed)
            
            guard let item = player.currentItem else {
                return
            }
            
            let duration = Int(Double(item.asset.duration.value) / Double(item.asset.duration.timescale))
            
            for d in delegates.values {
                d.playingState(podcastId: podcast.feedID, duration: duration, currentTime: currentTime)
            }
            
            configureTimer()
        } else {
            prepareEpisode(index: currentEpisode, in: podcast, autoPlay: true, completion: {})
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
        
        playerSpeed = value
        
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
    
    func shouldUpdateTimeLabels(
        progress: Double,
        podcastId: String
    ) {
        guard let podcast = podcast else {
            return
        }
        
        guard let player = player, let item = player.currentItem else {
            return
        }
        
        let playing = isPlaying(podcastId)
        let duration = Double(item.asset.duration.value) / Double(item.asset.duration.timescale)
        let currentTime = (duration * progress)
        
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
            return
        }
        
        if let player = player, let item = player.currentItem {
            let duration = Double(item.asset.duration.value) / Double(item.asset.duration.timescale)
            player.seek(to: CMTime(seconds: round(duration * progress), preferredTimescale: 1))
            self.currentTime = Int(duration * progress)
            
            configurePlayingInfoCenter(duration: Int(duration), currentTime: currentTime, forceUpdate: playAfterSeek)
        }
        
        if playAfterSeek { shouldPlay() }
    }
    
    func seek(
        _ podcast: PodcastFeed,
        to seconds: Double
    ) {
        if podcast.feedID != self.podcast?.feedID {
            return
        }
        
        let wasPlaying = isPlaying(podcast.feedID)
        
        self.shouldPause()
        
        if let player = player, let item = player.currentItem {
            let playing = isPlaying(podcast.feedID)
            player.pause()
            
            let duration = Int(Double(item.asset.duration.value) / Double(item.asset.duration.timescale))
            player.seek(to: CMTime(seconds: (Double(currentTime) + seconds), preferredTimescale: 1))
            
            let newTime = self.currentTime + Int(seconds)
            self.currentTime = (newTime > 0) ? newTime : 0
            
            if playing {
                player.playImmediately(atRate: self.playerSpeed)
            }
            
            configurePlayingInfoCenter(duration: duration, currentTime: currentTime, forceUpdate: true)
            
            if let sound = sounds.randomElement() {
                audioPlayerHelper.playSound(name: sound)
            }
        }
        
        if wasPlaying {
            shouldPlay()
        }
    }
    
    func move(
        _ podcast: PodcastFeed,
        toEpisodeWith index: Int
    ) -> Bool {
        if podcast.feedID != self.podcast?.feedID {
            resetPodcast(podcast)
        }
        
        if index < self.getEpisodes().count && index >= 0 {
            prepareEpisode(
                index: index,
                in: podcast,
                autoPlay: isPlaying(podcast.feedID),
                resetTime: true,
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

        guard let episode = getCurrentEpisode() else {
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
            MPMediaItemPropertyAlbumTrackCount: "\(getEpisodes().count)",
            MPMediaItemPropertyAlbumTrackNumber: "\(currentEpisode)",
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
}
