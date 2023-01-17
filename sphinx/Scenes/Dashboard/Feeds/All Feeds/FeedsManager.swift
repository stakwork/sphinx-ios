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

class FeedsManager : NSObject{
    
    func preCacheTopPods(){
        //1. Fetch results from memory
        var followedFeeds: [ContentFeed] = []
        let fetchRequest = ContentFeed.FetchRequests.followedFeeds()
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        do {
            followedFeeds = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Error: " + error.localizedDescription)
            return
        }
            
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