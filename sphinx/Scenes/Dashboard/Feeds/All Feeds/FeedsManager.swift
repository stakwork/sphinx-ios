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
    
    func syncRemoteAndLocalFeeds(remoteData:[ContentFeedStatus]){
        //1. Arrange all data and IDs
        let localData = FeedsManager.fetchFeeds()
        
        let localIDs = localData.compactMap({$0.feedID})
        let remoteIDs = remoteData.compactMap({$0.feedID})
        
        //2. Iterate through IDs not present locally and add them
        let idsToAdd = remoteIDs.filter({localIDs.contains($0) == false})
        
        for _id in idsToAdd{
            if let relevant_data = remoteData.filter({$0.feedID == _id}).first{
                let relevant_feed_url = relevant_data.feedURL
                var chat : Chat? = nil
                let bgContext = CoreDataManager.sharedManager.getBackgroundContext()
                if let valid_chat_id = relevant_data.chatID{
                    chat = Chat.getChatWith(id: valid_chat_id,managedContext: bgContext)
                }
                ContentFeed.fetchContentFeed(at: relevant_feed_url, chat: chat, persistingIn: bgContext,then: {
                    result in
                    if case .success(_) = result {
                        do{
                            let contentFeed = try result.get()
                            contentFeed.isSubscribedToFromSearch = true
                            bgContext.saveContext()
                        }
                        catch{
                            print(error)
                        }
                    }
                })
            }
        }
        
        //3. Iterate through each local copy that is not present in relay and unsubscribe
        let idsToRemove = localIDs.filter({remoteIDs.contains($0) == false})
        
        for _id in idsToRemove{
            if let relevant_data = localData.filter({$0.feedID == _id}).first{
                relevant_data.isSubscribedToFromSearch = false
                relevant_data.managedObjectContext?.saveContext()
                
            }
        }
        
        //4. Sync all episodes
        for contentFeed in localData{
            if contentFeed.feedKind == .Podcast,
               let remoteContentStatus = remoteData.filter({$0.feedID == contentFeed.id}).first,
               let episodeStatuses = remoteContentStatus.episodeStatus{
                let podcastFeed = PodcastFeed.convertFrom(contentFeed: contentFeed)
                for episodeStatus in episodeStatuses{
                    if var podFeedEpisode = podcastFeed.episodes?.filter({$0.itemID == episodeStatus.episodeID}).first{
                        podFeedEpisode.duration = episodeStatus.episodeData?.duration
                        podFeedEpisode.currentTime = episodeStatus.episodeData?.current_time
                    }
                }
            }
        }
        
        print(idsToAdd)
        print(idsToRemove)
    }
    
    func preCacheTopPods(){
        //1. Fetch results from memory
        var followedFeeds: [ContentFeed] = FeedsManager.fetchFeeds()
            
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
    
    static func makeFetchedResultsController(
        using managedObjectContext: NSManagedObjectContext
    ) -> NSFetchedResultsController<ContentFeed> {
        let fetchRequest = ContentFeed.FetchRequests.followedFeeds()
        
        return NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }
}
