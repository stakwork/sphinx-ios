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
    func shouldUpdateLabels(duration: Int, currentTime: Int)
    func shouldToggleLoadingWheel(loading: Bool)
    @objc optional func shouldUpdatePlayButton()
    @objc optional func shouldUpdateEpisodeInfo()
    @objc optional func shouldInsertMessagesFor(currentTime: Int)
}

class PodcastPlayerHelper {
    
    weak var delegate: PodcastPlayerDelegate?
    
    var player: AVPlayer?
    var playingTimer : Timer? = nil
    var paymentsTimer : Timer? = nil
    var playingEpisodeImage: UIImage? = nil
    
    var chat: Chat? = nil
    
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
            let speed = (UserDefaults.standard.value(forKey: "player-speed-\(chat?.id ?? -1)") as? Float) ?? 1.0
            return speed >= 0.5 && speed <= 2.1 ? speed : 1.0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "player-speed-\(chat?.id ?? -1)")
        }
    }

    
    var playedSeconds: Int = 0
    
    public static let kClipPrefix = "clip::"
    public static let kBoostPrefix = "boost::"
    public static let kSecondsBeforePMT = 60
    
    var podcast: PodcastFeed? = nil
    
    var podcastPaymentsHelper = PodcastPaymentsHelper()
    
    var isConfigured : Bool {
        get {
            return self.podcast != nil
        }
    }
    
    var loading = false {
        didSet {
            delegate?.shouldToggleLoadingWheel(loading: loading)
        }
    }
    
    
    func resetPodcast() {
        stopPlaying()
        
        self.podcast = nil
    }
    
    
    func toggleFeedSubscriptionState() {
        podcast?.isSubscribedToFromSearch.toggle()
        CoreDataManager.sharedManager.saveContext()
    }
    
    
    func loadPodcastFeed(chat: Chat?, callback: @escaping (Bool) -> ()) {
        guard
            ConnectivityHelper.isConnectedToInternet,
            chat?.tribeInfo?.feedUrl != nil
        else {
            processLocalPodcastFeed(chat: chat, callback: callback)
            return
        }
        
        guard let url = chat?.tribeInfo?.feedUrl else {
            callback(false)
            return
        }
        
        if
            let podcastChatId = podcast?.chat?.id,
            let chatId = chat?.id,
            podcastChatId == chatId && isPlaying()
        {
            DelayPerformedHelper.performAfterDelay(seconds: 0.5) {
                callback(true)
            }
            return
        }
        
        resetPodcast()
        
        chat?.fetchContentFeed(at: url) { [weak self] result in
            if case let .success(contentFeed) = result {
                self?.podcast = PodcastFeed.convertedFrom(contentFeed: contentFeed)
            }

            callback(true)
        }
    }
    
    func processLocalPodcastFeed(chat: Chat?, callback: @escaping (Bool) -> ()) {
        if let podcastFeed = chat?.podcastFeed {
            callback(true)
        }
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
    
    func getIndexFor(episode: PodcastEpisode) -> Int? {
        podcast?.episodesArray.firstIndex(where: { $0.id == episode.id })
    }
    
    
    func getEpisodeInfo() -> (String, String) {
        let episode = getCurrentEpisode()
        
        return (episode?.title ?? "Episode with no title", episode?.imageURLPath ?? "")
    }
    
    
    func getImageURL() -> URL? {
        let (_, episodeImage) = getEpisodeInfo()
        if let imageURL = URL(string: episodeImage), !episodeImage.isEmpty {
            return imageURL
        }
        let urlPath = self.podcast?.imageURLPath ?? ""
        if let imageURL = URL(string: urlPath), !urlPath.isEmpty {
            return imageURL
        }
        return nil
    }
    
    func getPodcastComment() -> PodcastComment {
        let podcastFeed = self.podcast
        let episode = getCurrentEpisode()
        
        var comment = PodcastComment()
        comment.feedId = podcastFeed.map(\.id).map(Int.init)
        comment.itemId = episode.map(\.id).map(Int.init)
        comment.title = episode?.title
        comment.url = episode?.urlPath
        
        let currentTime = Int(Double(player?.currentTime().value ?? 0) / Double(player?.currentTime().timescale ?? 1))
        comment.timestamp = currentTime
        
        return comment
    }
    
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
                self.delegate?.shouldUpdatePlayButton?()
            default:
                break
            }
        }
    }
    
    func preparePlayer(completion: @escaping () -> ()) {
        if player != nil {
            completion()
            return
        }
        
        let currentEpisodeIndex = getCurrentEpisodeIndex()
        setupNowPlayingInfoCenter()
        prepareEpisode(index: currentEpisodeIndex, completion: completion)
    }
    
    func prepareEpisode(index: Int,
                        autoPlay: Bool = false,
                        resetTime: Bool = false,
                        completion: @escaping () -> ()) {
        
        guard let podcast = self.podcast else {
            return
        }

        if podcast.episodesArray.count <= index {
            return
        }
        
        let episode = podcast.episodesArray[index]
        
        if !episode.isAvailable() {
            completion()
            return
        }
        
        guard let episodeUrl = episode.urlPath, !episodeUrl.isEmpty else {
            return
        }
        
        loading = true
        
        currentEpisode = index
        currentEpisodeId = Int(episode.itemID) ?? -1
        currentTime = resetTime ? 0 : currentTime
        
        loadEpisodeImage()
        delegate?.shouldUpdateLabels(duration: 0, currentTime: 0)
        
        loadEpisode(autoPlay: autoPlay, completion: completion)
    }
    
    func getCurrentEpisodeUrl() -> URL? {
        return getCurrentEpisode()?.getAudioUrl()
    }
    
    func loadEpisode(autoPlay: Bool, completion: @escaping () -> ()) {
        shouldPause()
        
        if let url = getCurrentEpisodeUrl() {
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
                    self.updateCurrentTime()
                    
                    if autoPlay {
                        self.shouldPlay()
                    } else {
                        self.player?.pause()
                        self.loading = false
                    }
                    completion()
                }
            })
        }
    }
    
    func loadEpisodeImage() {
        self.playingEpisodeImage = nil
        
        if let url = getImageURL() {
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
        guard let player = player, let item = player.currentItem else {
            return
        }
        
        let duration = Int(Double(item.asset.duration.value) / Double(item.asset.duration.timescale))
        let currentTime = Int(round(Double(player.currentTime().value) / Double(player.currentTime().timescale)))
         
        if currentTime == self.currentTime + 1 {
            delegate?.shouldInsertMessagesFor?(currentTime: currentTime)
            
            configurePlayingInfoCenter(duration: duration, currentTime: currentTime)
        }
        delegate?.shouldUpdateLabels(duration: duration, currentTime: currentTime)
        self.currentTime = currentTime
        
        if currentTime >= duration {
            didEndEpisode()
        }
    }
    
    func didEndEpisode() {
        shouldPause()
        delegate?.shouldUpdatePlayButton?()
        
        let _ = self.moveToEpisode(index: currentEpisode - 1)
        chat?.updateMetaData()
    }
    
    @objc func updatePlayedTime() {
        loading = false
        
        playedSeconds = playedSeconds + 1
        
        if playedSeconds > 0 && playedSeconds % PodcastPlayerHelper.kSecondsBeforePMT == 0 {
            DispatchQueue.global().async {
                self.processPayment()
            }
        }
    }
    
    func changeSpeedTo(value: Float) {
        playerSpeed = value
        
        if let player = player, isPlaying() {
            player.playImmediately(atRate: value)
        }
        chat?.updateMetaData()
    }
    
    
    func processPayment(amount: Int? = nil) {
        let itemId = Int(getCurrentEpisode()?.itemID ?? "") ?? -1
        
        podcastPaymentsHelper
            .processPaymentsFor(
                podcastFeed: podcast,
                boostAmount: amount,
                itemId: itemId,
                currentTime: currentTime
            )
    }
    
    
    func togglePlayState() {
        if isPlaying() {
            shouldPause()
        } else {
            shouldPlay()
        }
        chat?.updateMetaData()
    }
    
    func shouldDeleteEpisode(episode: PodcastEpisode) {
        episode.shouldDeleteFile(deleteCompletion: ({
            self.delegate?.shouldUpdateEpisodeInfo?()
        }))
    }
    
    func shouldPause() {
        player?.pause()
        playingTimer?.invalidate()
        paymentsTimer?.invalidate()
    }
    
    func shouldPlay() {
        setAudioSession()
        
        loading = true
        
        if let player = player {
            player.seek(to: CMTime(seconds: Double(currentTime), preferredTimescale: 1))
            player.playImmediately(atRate: self.playerSpeed)
            
            if currentTime == 0 {
                delegate?.shouldInsertMessagesFor?(currentTime: currentTime)
            }
            configureTimer()
            didStartPlaying()
        } else {
            prepareEpisode(index: currentEpisode, autoPlay: true, completion: {})
        }
    }
    
    func didStartPlaying() {
        PodcastPlayerHelper.stopPlayingPodcast(newChatId: chat?.id)
        chat?.updateWebAppLastDate()
    }
    
    func isPlaying() -> Bool {
        return player?.timeControlStatus == AVPlayer.TimeControlStatus.playing || player?.timeControlStatus == AVPlayer.TimeControlStatus.waitingToPlayAtSpecifiedRate
    }
    
    func stopPlaying() {
        player?.pause()
        player = nil
        
        playingTimer?.invalidate()
        playingTimer = nil
        
        paymentsTimer?.invalidate()
        paymentsTimer = nil
    }
    
    func seekTo(progress: Double, play: Bool) {
        if let player = player, let item = player.currentItem {
            let duration = Double(item.asset.duration.value) / Double(item.asset.duration.timescale)
            player.seek(to: CMTime(seconds: round(duration * progress), preferredTimescale: 1))
            self.currentTime = Int(duration * progress)
            
            configurePlayingInfoCenter(duration: Int(duration), currentTime: currentTime, forceUpdate: play)
        }
        
        if play { shouldPlay() }
    }
    
    func seekTo(seconds: Double) {
        let wasPlaying = isPlaying()
        self.shouldPause()
        
        if let player = player, let item = player.currentItem {
            let playing = isPlaying()
            player.pause()
            
            let duration = Int(Double(item.asset.duration.value) / Double(item.asset.duration.timescale))
            player.seek(to: CMTime(seconds: (Double(currentTime) + seconds), preferredTimescale: 1))
            self.currentTime = self.currentTime + Int(seconds)
            
            if playing {
                player.playImmediately(atRate: self.playerSpeed)
            } else {
                delegate?.shouldUpdateLabels(duration: duration, currentTime: currentTime)
            }
            
            configurePlayingInfoCenter(duration: duration, currentTime: currentTime, forceUpdate: true)
        }
        if wasPlaying { shouldPlay() }
    }
    
    func shouldUpdateTimeLabels(progress: Double? = nil) {
        guard let player = player, let item = player.currentItem else {
            return
        }
        
        let duration = Double(item.asset.duration.value) / Double(item.asset.duration.timescale)
        if let progress = progress {
            let currentTime = (duration * progress)
            delegate?.shouldUpdateLabels(duration: Int(duration), currentTime: Int(currentTime))
        } else {
            delegate?.shouldUpdateLabels(duration: Int(duration), currentTime: Int(currentTime))
        }
    }
    
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
            self.delegate?.shouldUpdatePlayButton?()
            return .success
        }
        MPRemoteCommandCenter.shared().pauseCommand.addTarget {event in
            self.shouldPause()
            self.delegate?.shouldUpdatePlayButton?()
            return .success
        }
        MPRemoteCommandCenter.shared().skipBackwardCommand.addTarget {event in
            self.seekTo(seconds: -15)
            return .success
        }
        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget {event in
            self.seekTo(seconds: 30)
            return .success
        }
    }
    
    func moveToEpisode(index: Int) -> Bool {
        if index < self.getEpisodes().count && index >= 0 {
            prepareEpisode(index: index, autoPlay: isPlaying(), resetTime: true, completion: {
                self.delegate?.shouldUpdateEpisodeInfo?()
            })
            return true
        }
        return false
    }
    
    func goToLastEpisode() {
        if let lastEId = self.lastEpisodeId {
            currentEpisodeId = lastEId
            let index = getCurrentEpisodeIndex()
            let _ = moveToEpisode(index: index)
        }
    }
    
    public static var playingChatId: Int? = nil
    
    public static func stopPlayingPodcast(newChatId: Int?) {
        if let chatId = playingChatId, chatId != newChatId {
            let chat = Chat.getChatWith(id: chatId)
            chat?.podcastPlayer?.stopPlaying()
        }
        playingChatId = newChatId
    }
}
