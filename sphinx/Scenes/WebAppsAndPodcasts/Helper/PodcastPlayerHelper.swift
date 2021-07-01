//
//  PodcastPlayerHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 08/10/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
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
            return (UserDefaults.standard.value(forKey: "current-episode-\(chat?.id ?? -1)") as? Int) ?? 0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "current-episode-\(chat?.id ?? -1)")
        }
    }
    
    var currentEpisodeId: Int {
        get {
            return (UserDefaults.standard.value(forKey: "current-episode-id-\(chat?.id ?? -1)") as? Int) ?? -1
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "current-episode-id-\(chat?.id ?? -1)")
        }
    }
    
    var lastEpisodeId: Int? {
        get {
            return (UserDefaults.standard.value(forKey: "last-episode-id-\(chat?.id ?? -1)") as? Int)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "last-episode-id-\(chat?.id ?? -1)")
        }
    }
    
    var currentTime: Int {
        get {
            return (UserDefaults.standard.value(forKey: "current-time-\(chat?.id ?? -1)") as? Int) ?? 0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "current-time-\(chat?.id ?? -1)")
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
    
    func loadPodcastFeed(chat: Chat?, callback: @escaping (Bool) -> ()) {
        if !ConnectivityHelper.isConnectedToInternet || chat?.tribesInfo?.feedUrl == nil {
            processLocalPodcastFeed(chat: chat, callback: callback)
            return
        }
        
        guard let url = chat?.tribesInfo?.feedUrl else {
            callback(false)
            return
        }
        
        if let podcastChatId = self.podcast?.chatId, let chatId = chat?.id, podcastChatId == chatId && isPlaying() {
            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                callback(true)
            })
            return
        }
        
        resetPodcast()
        
        let tribesServerURL = "https://tribes.sphinx.chat/podcast?url=\(url)"
        
        API.sharedInstance.getPodcastFeed(url: tribesServerURL, callback: { json in
            DispatchQueue.main.async {
                self.processPodcastFeed(json: json, chat: chat)
                callback(true)
            }
        }, errorCallback: {
            callback(false)
        })
    }
    
    func processLocalPodcastFeed(chat: Chat?, callback: @escaping (Bool) -> ()) {
        if let json = chat?.getPodcastFeed() {
            processPodcastFeed(json: json, chat: chat)
            callback(true)
        }
    }
    
    func processPodcastFeed(json: JSON, chat: Chat?) {
        if json["episodes"].arrayValue.count <= 0 {
            return
        }
        chat?.savePodcastFeed(json: json)
        self.chat = chat
        
        var podcastFeed = PodcastFeed()
        podcastFeed.chatId = chat?.id
        podcastFeed.id = json["id"].intValue
        podcastFeed.title = json["title"].stringValue
        podcastFeed.description = json["description"].stringValue
        podcastFeed.author = json["author"].stringValue
        podcastFeed.image = json["image"].stringValue
        
        var episodes = [PodcastEpisode]()
        
        for e in json["episodes"].arrayValue {
            let episode = PodcastEpisode()
            episode.id = e["id"].intValue
            episode.title = e["title"].stringValue
            episode.description = e["description"].stringValue
            episode.image = e["image"].stringValue
            episode.link = e["link"].stringValue
            episode.url = e["enclosureUrl"].stringValue
            episode.downloaded = DownloadService.sharedInstance.isEpisodeDownloaded(episode)
            episodes.append(episode)
        }
        
        let value = JSON(json["value"])
        let model = JSON(value["model"])
        
        var podcastModel = PodcastModel()
        podcastModel.type = model["type"].stringValue
        let suggestedAmount = model["suggested"].doubleValue
        podcastModel.suggested = suggestedAmount
        podcastModel.suggestedSats = Int(round(suggestedAmount * 100000000))
        podcastFeed.model = podcastModel
        
        var destinations = [PodcastDestination]()
        
        for d in value["destinations"].arrayValue {
            var destination = PodcastDestination()
            destination.address = d["address"].stringValue
            destination.type = d["type"].stringValue
            destination.split = d["split"].doubleValue
            
            destinations.append(destination)
        }
        podcastFeed.destinations = destinations
        podcastFeed.episodes = episodes
        
        self.podcast = podcastFeed
    }
    
    func getBoostMessage(amount: Int) -> String? {
        guard let podcast = self.podcast else {
            return nil
        }
        
        guard let feedID = podcast.id, feedID > 0 else {
            return nil
        }
        
        guard let itemID = getCurrentEpisode()?.id, itemID > 0 else {
            return nil
        }
        
        if amount == 0 {
            return nil
        }
        
        return "{\"feedID\":\(feedID),\"itemID\":\(itemID),\"ts\":\(currentTime),\"amount\":\(amount)}"
    }
    
    func getEpisodes() -> [PodcastEpisode] {
        return self.podcast?.episodes ?? []
    }
    
    func getCurrentEpisode() -> PodcastEpisode? {
        let currentEpisodeIndex = getCurrentEpisodeIndex()
        let podcastFeed = self.podcast
        if (podcastFeed?.episodes ?? []).count > 0 {
            let episode = podcastFeed?.episodes[currentEpisodeIndex]
            return episode
        }
        return nil
    }
    
    func getCurrentEpisodeIndex() -> Int {
        if currentEpisodeId > 0 {
            for i in 0..<(self.podcast?.episodes ?? []).count {
                let e = (self.podcast?.episodes ?? [])[i]
                if e.id == currentEpisodeId {
                    return i
                }
            }
        }
        return currentEpisode
    }
    
    func getIndexFor(episode: PodcastEpisode) -> Int? {
        for i in 0..<(self.podcast?.episodes ?? []).count {
            let e = (self.podcast?.episodes ?? [])[i]
            if e.id == episode.id {
                return i
            }
        }
        return nil
    }
    
    func getEpisodeInfo() -> (String, String) {
        let episode = getCurrentEpisode()
        return (episode?.title ?? "Episode with no title", episode?.image ?? "")
    }
    
    func getImageURL() -> URL? {
        let (_, episodeImage) = getEpisodeInfo()
        if let imageURL = URL(string: episodeImage), !episodeImage.isEmpty {
            return imageURL
        }
        let podcastImage = self.podcast?.image ?? ""
        if let imageURL = URL(string: podcastImage), !podcastImage.isEmpty {
            return imageURL
        }
        return nil
    }
    
    func getPodcastComment() -> PodcastComment {
        let podcastFeed = self.podcast
        let episode = getCurrentEpisode()
        
        var comment = PodcastComment()
        comment.feedId = podcastFeed?.id
        comment.itemId = episode?.id
        comment.title = episode?.title
        comment.url = episode?.url
        
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
        
        if podcast.episodes.count <= index {
            return
        }
        
        let episode = podcast.episodes[index]
        
        if !episode.isAvailable() {
            completion()
            return
        }
        
        guard let episodeUrl = episode.url, !episodeUrl.isEmpty else {
            return
        }
        
        loading = true
        
        currentEpisode = index
        currentEpisodeId = episode.id ?? -1
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
        if isPlaying() {
            getCurrentEpisode()?.shouldDeleteFile(deleteCompletion: ({
                self.delegate?.shouldUpdateEpisodeInfo?()
            }))
        }
        
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
        let itemId = getCurrentEpisode()?.id ?? 0
        self.podcastPaymentsHelper.processPaymentsFor(podcastFeed: self.podcast, boostAmount: amount, itemId: itemId, currentTime: self.currentTime)
    }
    
    func togglePlayState() {
        if isPlaying() {
            shouldPause()
        } else {
            shouldPlay()
        }
        chat?.updateMetaData()
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
            MPMediaItemPropertyPodcastPersistentID: "\(podcast.id ?? 0)",
            MPMediaItemPropertyTitle: episode.title ?? "",
            MPMediaItemPropertyArtist: podcast.author ?? "",
            MPMediaItemPropertyPlaybackDuration: "\(duration)",
            MPNowPlayingInfoPropertyElapsedPlaybackTime: "\(currentTime)",
            MPMediaItemPropertyAlbumTrackCount: "\(getEpisodes().count)",
            MPMediaItemPropertyAlbumTrackNumber: "\(currentEpisode)",
            MPMediaItemPropertyAssetURL: episode.url ?? ""
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
