//
//  FeedsManager.swift
//  sphinx
//
//  Created by James Carucci on 1/5/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
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
    
    // MARK: - Content Feed fetch requests
    
    func fetchFeeds(
        context: NSManagedObjectContext? = nil
    ) -> [ContentFeed]{
        var feeds: [ContentFeed] = []
        let fetchRequest = ContentFeed.FetchRequests.default()
        let managedContext = context ?? CoreDataManager.sharedManager.persistentContainer.viewContext
        
        do {
            feeds = try managedContext.fetch(fetchRequest)
            return feeds
        } catch {
            return []
        }
    }
    
    // MARK: - Saving content feed status to relay
    func saveContentFeedStatus(
        for feedId: String
    ){
        if let contentFeed = ContentFeed.getFeedWith(feedId: feedId) {
            let contentFeedStatus = getContentFeedStatus(for: contentFeed)
            let contentFeedStatusParams = contentFeedStatus.toJSON()
         
            API.sharedInstance.saveContentFeedStatusToRemote(
                params: contentFeedStatusParams,
                feedId: feedId,
                callback: {},
                errorCallback: {}
            )
        }
    }
    
    func saveContentFeedStatus(){
        let feeds = fetchFeeds()
        
        if feeds.isEmpty {
            return
        }
        
        let contentFeedStatuses: [ContentFeedStatus] = feeds.map({
            return self.getContentFeedStatus(for: $0)
        })
        
        let contentFeedStatusParams = contentFeedStatuses.map({ $0.toJSON() })

        API.sharedInstance.saveContentFeedStatusesToRemote(
            params: contentFeedStatusParams,
            callback: {},
            errorCallback: {}
        )
    }
    
    func getContentFeedStatus(
        for contentFeed: ContentFeed
    ) -> ContentFeedStatus {
        
        let status = ContentFeedStatus()
        status.feedID = contentFeed.feedID
        status.feedURL = contentFeed.feedURL?.absoluteString ?? ""
        status.subscriptionStatus = contentFeed.isSubscribedToFromSearch
        status.chatID = contentFeed.chat?.id
        
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
                    status.episodeStatus.append(episodeStatus)
                }
            }
        }
        
        return status
    }
    
    // MARK: - Getting content feed status from relay and restoring
    func restoreContentFeedStatusInBackgroundFor(
        feedId: String
    ) {
        let dispatchQueue = DispatchQueue.global(qos: .userInitiated)
        dispatchQueue.async {
            self.restoreContentFeedStatusFor(feedId: feedId)
        }
    }
    
    func restoreContentFeedStatusFor(
        feedId: String,
        completionCallback: ((() -> ()))? = nil
    ){
        API.sharedInstance.getContentFeedStatusFor(
            feedId: feedId,
            callback: { result in
                self.restore(
                    contentFeedStatus: result,
                    with: CoreDataManager.sharedManager.persistentContainer.viewContext
                ) {
                    self.refreshFeedUI()
                    completionCallback?()
                }
            },
            errorCallback: {
                completionCallback?()
            }
        )
    }
    
    func restoreContentFeedStatusInBackground() {
        let dispatchQueue = DispatchQueue.global(qos: .userInitiated)
        dispatchQueue.async {
            self.restoreContentFeedStatus()
        }
    }
    
    func restoreContentFeedStatus(
        progressCallback: ((Int) -> ())? = nil,
        completionCallback: (() -> ())? = nil
    ){
        API.sharedInstance.getAllContentFeedStatuses(
            callback: { results in
                self.restoreFeedStatuses(
                    from: results,
                    progressCallback: progressCallback,
                    completionCallback: {
                        self.refreshFeedUI()
                        completionCallback?()
                        
                        self.fetchNewItems()
                    }
                )
            },
            errorCallback: {
                completionCallback?()
            }
        )
    }
    
    func getRestoreProgress(totalFeeds:Int,syncedFeeds:Int)->Int{
        return Int(100.0 * Float(syncedFeeds)/Float(totalFeeds))
    }
    
    func restoreFeedStatuses(
        from contentFeedStatuses: [ContentFeedStatus],
        progressCallback: ((Int) -> ())? = nil,
        completionCallback: (() -> ())? = nil
    ){
        
        if contentFeedStatuses.isEmpty {
            completionCallback?()
            return
        }
        
        let context = CoreDataManager.sharedManager.getBackgroundContext()
        
        context.perform {
            let feeds = self.fetchFeeds(context: context)
            
            let localIDs = feeds.compactMap({ $0.feedID })
            let remoteIDs = contentFeedStatuses.compactMap({ $0.feedID })
            
            ///Delete feeds not present on remote data
            for idToRemove in localIDs.filter({ remoteIDs.contains($0) }) {
                if let feedToRemove = feeds.filter({ $0.feedID == idToRemove }).first {
                    feedToRemove.isSubscribedToFromSearch = false
                    feedToRemove.chat = nil
                }
            }
            
            let dispatchSemaphore = DispatchSemaphore(value: 1)
            
            ///Update feeds present in remote data
            for (index, contentFeedStatus) in contentFeedStatuses.enumerated() {
                
                dispatchSemaphore.wait()
                
                self.restore(
                    contentFeedStatus: contentFeedStatus,
                    with: context
                ) {
                    
                    progressCallback?(
                        self.getRestoreProgress(totalFeeds: contentFeedStatuses.count, syncedFeeds: index + 1)
                    )
                    
                    if (index + 1 == contentFeedStatuses.count) {
                        context.saveContext()
                        completionCallback?()
                    }
                    
                    dispatchSemaphore.signal()
                }
            }
        }
    }
    
    func restore(
        contentFeedStatus: ContentFeedStatus,
        with context: NSManagedObjectContext,
        completion: @escaping () -> ()
    ) {
        let feedUrl = contentFeedStatus.feedURL
        
        var chat : Chat? = nil
        if let validChatId = contentFeedStatus.chatID {
            chat = Chat.getChatWith(id: validChatId, managedContext: context)
        }
        
        ///Get feed from local db or fetch it from tribes server endpoint
        self.getContentFeedFor(
            feedId: contentFeedStatus.feedID,
            feedUrl: feedUrl,
            chat: chat,
            context: context
        ) { contentFeed in
            
            ///restore status from the remote content status
            if let contentFeed = contentFeed {
                self.restoreFeedStatus(
                    remoteContentStatus: contentFeedStatus,
                    localFeed: contentFeed,
                    chat: chat
                )
            }
            
            completion()
        }
    }
    
    func refreshFeedUI() {
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .active {
                NotificationCenter.default.post(name: .refreshFeedUI, object: nil)
            }
        }
    }
    
    func getContentFeedFor(
        feedId: String,
        feedUrl: String,
        chat: Chat?,
        context: NSManagedObjectContext,
        completion: @escaping (ContentFeed?) -> ()
    ) {
        if let existingContentFeed = ContentFeed.getFeedWith(feedId: feedId, managedContext: context) {
            completion(existingContentFeed)
        } else {
            ContentFeed.fetchContentFeed(at: feedUrl, chat: chat, persistingIn: context, then: { result in
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
        localFeed: ContentFeed,
        chat: Chat?
    ) {
        localFeed.isSubscribedToFromSearch = remoteContentStatus.subscriptionStatus
        localFeed.chat = chat
        
        if !localFeed.isPodcast {
            return
        }
        
        let podcastFeed = PodcastFeed.convertFrom(contentFeed: localFeed)
        podcastFeed.satsPerMinute = remoteContentStatus.satsPerMinute ?? 0
        
        if !podcastPlayerController.isPlaying(podcastId: remoteContentStatus.feedID) {
            podcastFeed.playerSpeed = remoteContentStatus.playerSpeed ?? 1.0
            podcastFeed.currentEpisodeId = remoteContentStatus.itemID ?? ""
        }
        
        for episodeStatus in remoteContentStatus.episodeStatus {
            restoreEpisodeStatus(
               on: podcastFeed,
               with: episodeStatus
            )
        }
        
        downloadLastEpisodeFor(feed: localFeed)
        loadEpisodesDurationFor(feed: localFeed)
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
    
    // MARK: - Pre load and cache content feeds
    func fetchNewItems() {
        let context = CoreDataManager.sharedManager.getBackgroundContext()
        
        context.perform {
            
            let dispatchSemaphore = DispatchSemaphore(value: 0)

            for feed in self.fetchFeeds(context: context) {
                
                if let url = feed.feedURL {
                    
                    ContentFeed.fetchFeedItems(
                        feedUrl: url.absoluteString,
                        contentFeedObjectID: feed.objectID,
                        context: context,
                        completion: { _ in
                            dispatchSemaphore.signal()
                        }
                    )
                    
                    dispatchSemaphore.wait()
                }
            }
            
            context.saveContext()
            self.refreshFeedUI()
        }
    }
    
    func fetchItemsFor(
        feedUrl: String,
        objectID: NSManagedObjectID
    ) {
        let bgContext = CoreDataManager.sharedManager.getBackgroundContext()
        
        bgContext.perform {
            ContentFeed.fetchFeedItems(
                feedUrl: feedUrl,
                contentFeedObjectID: objectID,
                context: bgContext,
                completion: { result in
                    if case .success(_) = result {
                        bgContext.saveContext()
                    }
                }
            )
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
        ///1. Stop if setting not enabled
        if UserDefaults.Keys.shouldAutoDownloadSubscribedPods.get(defaultValue: false) == false {
            return
        }
        
        ///2. Pluck the latest episode and download it for each feed
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
    
    func extractContentDeepLinkMetaData(forKey:String,components:[String])->String?{
        if let feedComponent = components.first(where: {$0.contains(forKey)}) {
            let elements = feedComponent.components(separatedBy: "=")
            if elements.count > 1 {
                return elements[1]
            }
        }
        return nil
    }
    
    //Navigate methods
    func goToContentFeed(vc: UIViewController, rootViewController: RootViewController) -> Bool {
        if let shareContentQuery = UserDefaults.Keys.shareContentQuery.get(defaultValue: ""), shareContentQuery != "" {
            UserDefaults.Keys.shareContentQuery.removeValue()
            
            //1. Validate the query
            //a. Does the feed exist?
            //b. Does the podcast exist?
            //c. is the timestamp possible?
            
            let components = shareContentQuery.components(separatedBy: "&")
            if let feedID = extractContentDeepLinkMetaData(forKey: "feedID",components: components),
               let itemID = extractContentDeepLinkMetaData(forKey: "itemID", components: components){
                print(feedID)
                print(itemID)
                //2. Feed it forward to instantiate the correct VC
                lookupContentFeedAndItem(feedID: feedID, itemID: itemID, completion: { feed,episode in
                    if let valid_episode = episode,
                        let valid_feed = feed,
                        let drvc = vc as? DashboardRootViewController{
                        let podcastFeedVC = NewPodcastPlayerViewController.instantiate(
                            podcast: valid_feed,
                            delegate: drvc,
                            boostDelegate: drvc,
                            fromDashboard: true
                        )
                        let timestamp = Int(self.extractContentDeepLinkMetaData(forKey: "atTime", components: components) ?? "-1")
                        podcastFeedVC.deeplinkedEpisode = episode
                        podcastFeedVC.deeplinkTimestamp = timestamp == -1 ? nil : timestamp
                        drvc.navigationController?.present(
                            podcastFeedVC,
                            animated: true,
                            completion: nil
                        )
                    }
                    else{
                        //error message
                    }
                })
                
            }
                return true
            }
            return false
        }
    
    func lookupContentFeedAndItem(feedID:String,itemID:String,completion:@escaping (PodcastFeed?,PodcastEpisode?)->()){
        let feeds = self.fetchFeeds()
        if let matchingFeed = feeds.first(where:{$0.feedID == feedID})
        {
            print(matchingFeed)
            let (pf,episode) = getPodcastAndEpisodeFromGenericFeed(contentFeed: matchingFeed, itemID: itemID)
            completion(pf,episode)
        }
        else if let feedInt : Int = Int(feedID){
            //need to go get it from tribe server
            API.sharedInstance.getPodcastInfo(podcastId: feedInt, callback: { result in
                let url = result["url"].stringValue as String
                print(url)
                self.getContentFeedFor(feedId: feedID, feedUrl: url, chat: nil, context: CoreDataManager.sharedManager.persistentContainer.viewContext, completion: { contentFeed in
                    if let feed = contentFeed{
                        let (pf,episode) = self.getPodcastAndEpisodeFromGenericFeed(contentFeed: feed, itemID: itemID)
                        completion(pf,episode)
                    }
                    else{
                        completion(nil,nil)
                    }
                    
                })
            }, errorCallback: {
                //TODO: error handle
                completion(nil,nil)
            })
        }
        else{
            //TODO: error handle
        }
        
        completion(nil,nil)
    }
    
    func getPodcastAndEpisodeFromGenericFeed(contentFeed:ContentFeed,itemID:String)->(PodcastFeed?,PodcastEpisode?){
        let pf = PodcastFeed.convertFrom(contentFeed: contentFeed)
        if let episode = pf.episodes?.first(where: {$0.itemID == itemID}){
            return(pf,episode)
        }
        return(pf,nil)
    }
}
