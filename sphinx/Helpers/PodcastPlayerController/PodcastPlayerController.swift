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
    var episodeUrl: String
    var currentTime: Int? = nil
    var duration: Int? = nil
    var speed: Float = 1
//    var satsPerMinute: Int = 0
//    var destinations: [ContentFeedPaymentDestination] = 0
    
    init(
        chatId: Int?,
        podcastId: String,
        episodeId: String,
        episodeUrl: String
    ) {
        self.chatId = chatId
        self.podcastId = podcastId
        self.episodeId = episodeId
        self.episodeUrl = episodeUrl
    }
}

enum UserAction {
    case Play(PodcastData)
    case Pause(PodcastData)
    case Seek(PodcastData)
    case AdjustSpeed(PodcastData)
}

enum DelegateKeys: String {
    case smallPlayer = "smallPlayer"
    case podcastPlayerVC = "podcastPlayerVC"
    case dashboard = "dashboardSmallPlayer"
    case recommendationsPlayer = "recommendationsPlayer"
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

}
