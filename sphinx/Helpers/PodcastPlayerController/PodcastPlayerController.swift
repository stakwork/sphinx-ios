//
//  AudioPlayerHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 13/01/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import AVKit

protocol PlayerDelegate : class {
    func loadingState(_ podcastData: PodcastData)
    func playingState(_ podcastData: PodcastData)
    func pausedState(_ podcastData: PodcastData)
    func endedState(_ podcastData: PodcastData)
    func errorState(_ podcastData: PodcastData)
}

struct PodcastData {
    
    var chatId: Int?
    var podcastId: String
    var episodeId: String
    var episodeUrl: URL
    var currentTime: Int? = nil
    var duration: Int? = nil
    var speed: Float = 1
//    var satsPerMinute: Int = 0
//    var destinations: [ContentFeedPaymentDestination] = 0
    
    init(
        _ chatId: Int?,
        _ podcastId: String,
        _ episodeId: String,
        _ episodeUrl: URL,
        _ currentTime: Int? = nil,
        _ duration: Int? = nil,
        _ speed: Float = 1
    ) {
        self.chatId = chatId
        self.podcastId = podcastId
        self.episodeId = episodeId
        self.episodeUrl = episodeUrl
        self.currentTime = currentTime
        self.duration = duration
        self.speed = speed
    }
}

enum UserAction {
    case Play(PodcastData)
    case Pause(PodcastData)
    case Seek(PodcastData)
    case AdjustSpeed(PodcastData)
}

enum PodcastDelegateKeys: String {
    case ChatSmallPlayerBar = "ChatSmallPlayerBar"
    case PodcastPlayerView = "PodcastPlayerView"
    case DashboardView = "DashboardView"
    case DashboardSmallPlayerBar = "DashboardSmallPlayerBar"
    case RecommendationsPlayerView = "RecommendationsPlayerView"
}

let kSecondsBeforePMT = 60

let sounds = [
    "skip30v1.caf",
    "skip30v2.caf",
    "skip30v3.caf",
    "skip30v4.caf"
]

class PodcastPlayerController {
    
    var delegates = [String : PlayerDelegate]()
    
    let soundsPlayer = SoundsPlayer()
    let podcastPaymentsHelper = PodcastPaymentsHelper()
    let actionsManager = ActionsManager.sharedInstance
    
    var player: AVPlayer?
    var playingTimer : Timer? = nil
    var paymentsTimer : Timer? = nil
    var playedSeconds: Int = 0
    
    var podcastData: PodcastData? = nil
    
    class var sharedInstance : PodcastPlayerController {
        
        struct Static {
            static let instance = PodcastPlayerController()
        }
        
        return Static.instance
    }
    
    init() {
        setupNowPlayingInfoCenter()
    }
    
    func saveState() {
        if let podcastData = podcastData, let contentFeed = ContentFeed.getFeedWith(feedId: podcastData.podcastId) {
            let podcast = PodcastFeed.convertFrom(contentFeed: contentFeed)
            podcast.currentTime = podcastData.currentTime ?? 0
            podcast.currentEpisodeId = podcastData.episodeId
        }
    }

}
