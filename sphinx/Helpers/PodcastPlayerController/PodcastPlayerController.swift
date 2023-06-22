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

enum UserAction {
    case Play(PodcastData)
    case Pause(PodcastData)
    case Seek(PodcastData)
    case AdjustSpeed(PodcastData)
    case TogglePlay(PodcastData)
}

enum PodcastDelegateKeys: String {
    case ChatSmallPlayerBar = "ChatSmallPlayerBar"
    case PodcastPlayerView = "PodcastPlayerView"
    case DashboardView = "DashboardView"
    case DashboardSmallPlayerBar = "DashboardSmallPlayerBar"
    case RecommendationsPlayerView = "RecommendationsPlayerView"
    case ChatDataSource = "ChatDataSource"
}

let kSecondsBeforePMT = 60

let kSkipBackSeconds = 15
let kSkipForwardSeconds = 30

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
    
    var allItems: [String: CachingPlayerItem] = [:]
    var podcastItems: [String: CachingPlayerItem] = [:]
    
    var playingTimer : Timer? = nil
    var paymentsTimer : Timer? = nil
    var syncPodcastTimer : Timer? = nil
    
    var playedSeconds: Int = 0
    
    var isLoadingOrPlaying = false
    var isSoundPlaying: Bool = false
    
    var playingEpisodeImage: UIImage? = nil
    
    var podcast: PodcastFeed? = nil
    var podcastData: PodcastData? = nil {
        didSet {
            if self.podcast?.feedID == podcastData?.podcastId {
                return
            }
            self.podcast = getPodcastFrom(podcastData: podcastData)
            
            self.resetPlayedSeconds()
        }
    }
    
    class var sharedInstance : PodcastPlayerController {
        
        struct Static {
            static let instance = PodcastPlayerController()
        }
        
        return Static.instance
    }
    
    let dispatchSemaphore = DispatchSemaphore(value: 1)
    
    init() {
        setupNowPlayingInfoCenter()
        preloadAll()
    }
    
    func saveState() {
        podcast?.duration = podcastData?.duration ?? 0
        podcast?.currentTime = podcastData?.currentTime ?? 0
        
        if let episodeId = podcastData?.episodeId {
            podcast?.currentEpisodeId = episodeId
        }
    }
    
    func getPodcastFrom(podcastData: PodcastData?) -> PodcastFeed? {
        if let contentFeed = ContentFeed.getFeedById(feedId: podcastData?.podcastId ?? "") {
            return PodcastFeed.convertFrom(contentFeed: contentFeed)
        } else if podcastData?.podcastId == RecommendationsHelper.kRecommendationPodcastId {
            return RecommendationsHelper.sharedInstance.recommendationsPodcast
        }
        return nil
    }

}
