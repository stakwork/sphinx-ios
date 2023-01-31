//
//  FeedsManager.swift
//  sphinx
//
//  Created by James Carucci on 1/5/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import CoreData
import AVFoundation

class FeedsManager : NSObject {
    
    class var sharedInstance : FeedsManager {
        struct Static {
            static let instance = FeedsManager()
        }
        return Static.instance
    }
    
    let podcastPlayerController = PodcastPlayerController.sharedInstance
    
    static func fetchFeeds() -> [ContentFeed]{
        var followedFeeds: [ContentFeed] = []
        let fetchRequest = ContentFeed.FetchRequests.followedFeeds()
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        do {
            followedFeeds = try managedContext.fetch(fetchRequest)
            return followedFeeds
        } catch let error as NSError {
            print("Error: " + error.localizedDescription)
            return []
        }
    }
    
    func saveContentFeedInBackground() {
        let dispatchQueue = DispatchQueue.global()
        dispatchQueue.async {
            self.saveContentFeedStatus()
        }
    }
    
    func getContentFeedStatus(
        for contentFeed: ContentFeed
    ) -> ContentFeedStatus {
        
        let status = ContentFeedStatus()
        status.feedID = contentFeed.feedID
        status.feedURL = contentFeed.feedURL?.absoluteString ?? ""
        status.subscriptionStatus = contentFeed.isSubscribedToFromSearch
        
        if let valid_chat = contentFeed.chat {
            status.chatID = valid_chat.id
        }
        
        if contentFeed.isPodcast {
            let podFeed = PodcastFeed.convertFrom(contentFeed: contentFeed)
            status.satsPerMinute = podFeed.satsPerMinute
            status.playerSpeed = podFeed.playerSpeed
            status.itemID = podFeed.currentEpisodeId
            
            status.episodeStatus = [EpisodeStatus]()
            
            for episode in podFeed.episodes ?? [PodcastEpisode]() {
                
                let episodeData = EpisodeData()
                episodeData.duration = episode.duration ?? 0
                episodeData.current_time = episode.currentTime ?? 0
                
                let episodeStatus = EpisodeStatus()
                episodeStatus.episodeID = episode.itemID
                episodeStatus.episodeData = episodeData
                
                if (
                    episodeData.current_time > 0 ||
                    episodeData.duration > 0
                ) {
                    status.episodeStatus?.append(episodeStatus)
                }
            }
        }
        
        return status
    }
    
    func saveContentFeedStatus(
        for feedId: String
    ){
        if let contentFeed = ContentFeed.getFeedWith(feedId: feedId) {
            let contentFeedStatus = getContentFeedStatus(for: contentFeed)
            let contentFeedStatusParams = contentFeedStatus.toJSON()
         
            print(contentFeedStatusParams)
            
//            API.sharedInstance.saveContentFeedStatusesToRemote(
//                params: contentFeedStatusParams,
//                callback: {},
//                errorCallback: {}
//            )
        }
    }
    
    func saveContentFeedStatus(){
        let followedFeeds: [ContentFeed] = FeedsManager.fetchFeeds()
        
        let contentFeedStatuses: [ContentFeedStatus] = followedFeeds.map({
            return self.getContentFeedStatus(for: $0)
        })
        
        let contentFeedStatusParams = contentFeedStatuses.map({ $0.toJSON() })
        print(contentFeedStatuses)
        
        API.sharedInstance.saveContentFeedStatusesToRemote(
            params: contentFeedStatusParams,
            callback: {},
            errorCallback: {}
        )
    }
    
    func restoreContentFeedStatus(
        progressCallback: @escaping (Int) -> (),
        completionCallback: @escaping () -> ()
    ){
        API.sharedInstance.getAllContentFeedStatuses(
            callback: { results in
                self.restoreFeedStatuses(
                    from: results,
                    progressCallback: progressCallback,
                    completionCallback: {
                        self.refreshFeedUI()
                        completionCallback()
                    }
                )
            },
            errorCallback: {
                completionCallback()
                //TODO: retry? Alert user?
            }
        )
    }
    
    func getRestoreProgress(totalFeeds:Int,syncedFeeds:Int)->Int{
        return Int(100.0 * Float(syncedFeeds)/Float(totalFeeds))
    }
    
    func restoreFeedStatuses(
        from remoteData: [ContentFeedStatus],
        progressCallback: @escaping (Int) -> (),
        completionCallback: @escaping () -> ()
    ){
        let bgContext = CoreDataManager.sharedManager.getBackgroundContext()
        
        let localData = FeedsManager.fetchFeeds()
        
        let localIDs = localData.compactMap({ $0.feedID })
        let remoteIDs = remoteData.compactMap({ $0.feedID })
        
        ///Delete feeds not present on remote data
        for idToRemove in localIDs.filter({ remoteIDs.contains($0) }) {
            if let feedToRemove = localData.filter({ $0.feedID == idToRemove }).first {
                feedToRemove.isSubscribedToFromSearch = false
                feedToRemove.chat = nil
                
            }
        }
        
        DispatchQueue.global().async {
        
            let dispatchSemaphore = DispatchSemaphore(value: 1)
            
            ///Update feeds present in remote data
            for (index, contentFeedStatus) in remoteData.enumerated() {
                
                dispatchSemaphore.wait()
                
                let feedUrl = contentFeedStatus.feedURL
                
                var chat : Chat? = nil
                if let validChatId = contentFeedStatus.chatID {
                    chat = Chat.getChatWith(id: validChatId, managedContext: bgContext)
                }
                
                ///Get feed from local db or fetch it from tribes server endpoint
                self.getContentFeedFor(
                    feedId: contentFeedStatus.feedID,
                    feedUrl: feedUrl,
                    chat: chat
                ) { contentFeed in
                    
                    ///restore status from the remote content status
                    if let contentFeed = contentFeed {
                        self.restoreFeedStatus(
                            remoteContentStatus: contentFeedStatus,
                            localFeed: contentFeed
                        )
                    }
                    
                    progressCallback(
                        self.getRestoreProgress(totalFeeds: remoteData.count, syncedFeeds: index + 1)
                    )
                    
                    if (index + 1 == remoteData.count) {
                        completionCallback()
                    }
                    
                    dispatchSemaphore.signal()
                }
            }
        }
    }
    
    func refreshFeedUI() {
        NotificationCenter.default.post(name: .refreshPodcastUI, object: nil)
        NotificationCenter.default.post(name: .refreshVideoUI, object: nil)
        NotificationCenter.default.post(name: .refreshNewsletterUI, object: nil)
    }
    
    func getContentFeedFor(
        feedId: String,
        feedUrl: String,
        chat: Chat?,
        completion: @escaping (ContentFeed?) -> ()
    ) {
        if let existingContentFeed = ContentFeed.getFeedWith(feedId: feedId) {
            existingContentFeed.chat = chat
            completion(existingContentFeed)
        } else {
            let bgContext = CoreDataManager.sharedManager.getBackgroundContext()
            
            ContentFeed.fetchContentFeed(at: feedUrl, chat: chat, persistingIn: bgContext, then: { result in
                if case .success(let contentFeed) = result {
                    completion(contentFeed)
                    return
                }
                completion(nil)
            })
        }
    }
    
    func restoreFeedStatus(
        remoteContentStatus: ContentFeedStatus,
        localFeed: ContentFeed
    ) {
        localFeed.isSubscribedToFromSearch = remoteContentStatus.subscriptionStatus
        
        let podcastFeed = PodcastFeed.convertFrom(contentFeed: localFeed)
        podcastFeed.satsPerMinute = remoteContentStatus.satsPerMinute ?? 0
        
        if !podcastPlayerController.isPlaying(podcastId: remoteContentStatus.feedID) {
            podcastFeed.playerSpeed = remoteContentStatus.playerSpeed ?? 1.0
            podcastFeed.currentEpisodeId = remoteContentStatus.itemID ?? ""
        }
        
        if let episodeStatuses = remoteContentStatus.episodeStatus {
             for episodeStatus in episodeStatuses {
                 restoreEpisodeStatus(
                    on: podcastFeed,
                    with: episodeStatus
                 )
             }
        }
    }
    
    func restoreEpisodeStatus(
        on podcastFeed: PodcastFeed,
        with episodeStatus: EpisodeStatus
    ) {
        if !podcastPlayerController.isPlaying(episodeId: episodeStatus.episodeID) {
            if let episode = podcastFeed.getEpisodeWith(id: episodeStatus.episodeID) {
                episode.duration = episodeStatus.episodeData?.duration
                episode.currentTime = episodeStatus.episodeData?.current_time
            }
        }
    }
    
    func preCacheTopPods(){
        //1. Fetch results from memory
        let followedFeeds: [ContentFeed] = FeedsManager.fetchFeeds()
            
        //2. Walk through each feed
        for feed in followedFeeds {
            
            if let feedType = FeedType(rawValue: feed.feedKindValue) {
                switch(feedType) {
                case .Podcast:
                    if let valid_url = feed.feedURL {
                        ContentFeed.fetchFeedItemsInBackground(feedUrl: valid_url.absoluteString, contentFeedObjectID: feed.objectID, completion: {
                            self.refreshUI(feedType)
                            self.downloadLastEpisodeFor(feed: feed)
                            self.loadEpisodesDurationFor(feed: feed)
                        })
                    } else {
                        refreshUI(feedType)
                        downloadLastEpisodeFor(feed: feed)
                        loadEpisodesDurationFor(feed: feed)
                    }
                    break
                case .Video:
                    if let valid_url = feed.feedURL {
                        ContentFeed.fetchFeedItemsInBackground(feedUrl: valid_url.absoluteString, contentFeedObjectID: feed.objectID, completion: {
                            self.refreshUI(feedType)
                        })
                    }
                    break
                case .Newsletter:
                    if let valid_url = feed.feedURL {
                        ContentFeed.fetchFeedItemsInBackground(feedUrl: valid_url.absoluteString, contentFeedObjectID: feed.objectID, completion: {
                            self.refreshUI(feedType)
                        })
                    }
                    break
                }
            }
        }
    }
    
    func refreshUI(_ feedType : FeedType) {
        switch(feedType) {
        case .Podcast:
            NotificationCenter.default.post(name: .refreshPodcastUI, object: nil)
            break
        case .Video:
            NotificationCenter.default.post(name: .refreshVideoUI, object: nil)
            break
        case .Newsletter:
            NotificationCenter.default.post(name: .refreshNewsletterUI, object: nil)
            break
        }
    }
    
    func loadEpisodesDurationFor(feed: ContentFeed) {
        for item in feed.items ?? [] {
            let episode = PodcastEpisode.convertFrom(contentFeedItem: item)
            
            if let url = episode.getAudioUrl(), episode.duration == nil {
                let asset = AVAsset(url: url)
                asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                    let duration = Int(Double(asset.duration.value) / Double(asset.duration.timescale))
                    episode.duration = duration
                })
            }
        }
    }
    
    func loadCurrentEpisodeDurationFor(
        feedId: String,
        completion: @escaping () -> ()
    ) {
        if let feed = ContentFeed.getFeedWith(feedId: feedId) {
            
            let podcast = PodcastFeed.convertFrom(contentFeed: feed)
            
            if let episode = podcast.getCurrentEpisode() {
                
                if let url = episode.getAudioUrl(), episode.duration == nil {
                    let asset = AVAsset(url: url)
                    asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                        let duration = Int(Double(asset.duration.value) / Double(asset.duration.timescale))
                        episode.duration = duration
                        
                        DispatchQueue.main.async {
                            completion()
                        }
                    })
                    return
                }
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
        
    }
    
    func downloadLastEpisodeFor(feed: ContentFeed) {
        //0. Stop if setting not enabled
        if UserDefaults.Keys.shouldAutoDownloadSubscribedPods.get(defaultValue: false) == false {
            return
        }
        
        //2. Pluck the latest episode and download it for each feed
        let lastItem = Array(feed.items ?? []).sorted { (first, second) in
            let firstDate = first.dateUpdated ?? first.datePublished ?? Date.init(timeIntervalSince1970: 0)
            let secondDate = second.dateUpdated ?? second.datePublished ?? Date.init(timeIntervalSince1970: 0)

            return firstDate > secondDate
        }.first
        
        if let valid_item = lastItem {
            let lastEpisode = PodcastEpisode.convertFrom(contentFeedItem: valid_item)
            let downloadService = DownloadService.sharedInstance
            downloadService.startDownload(lastEpisode)
        }
    }
}
