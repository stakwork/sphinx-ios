//
//  AllTribesManager.swift
//  sphinx
//
//  Created by James Carucci on 1/5/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import CoreData

class AllTribesManager : NSObject{
    private var fetchedResultsController: NSFetchedResultsController<ContentFeed>!
    
    override init() {
        self.fetchedResultsController = AllTribesManager.makeFetchedResultsController(using: CoreDataManager.sharedManager.persistentContainer.viewContext)
    }
    
    func preCacheTopPods(){
        //0. Stop if setting not enabled
        if UserDefaults.Keys.shouldAutoDownloadSubscribedPods.get(defaultValue: false) == false{
            return
        }
        
        //1. Fetch results from memory
        guard
            let resultController = fetchedResultsController as? NSFetchedResultsController<NSManagedObject>,
            let firstSection = resultController.sections?.first,
            let foundFeeds = firstSection.objects as? [ContentFeed]
        else {
            return
        }
        //Pull only the followed podcasts
        let followedFeeds = foundFeeds.sorted { (first, second) in
            let firstDate = first.dateUpdated ?? first.datePublished ?? Date.init(timeIntervalSince1970: 0)
            let secondDate = second.dateUpdated ?? second.datePublished ?? Date.init(timeIntervalSince1970: 0)

            return firstDate > secondDate
        }//.filter({$0.isPodcast == true})
        print(followedFeeds)
        //2. Walk through each podcast feed
        var didRetrieveMediaTypeLookup : [ContentFeedMediaKind : Bool] = [
            .video : false,
            .newsletter : false,
            .podcast : false
        ]
        
        for feed in followedFeeds{
            switch(feed.contentMediaKind){
            case .podcast:
                if let valid_url = feed.feedURL{
                    ContentFeed.fetchFeedItemsInBackground(feedUrl: valid_url.absoluteString, contentFeedObjectID: feed.objectID, completion: {
                        self.downloadLastPod(feed: feed)
                    })
                }
                else{
                    downloadLastPod(feed: feed)
                }
                didRetrieveMediaTypeLookup[.podcast] = true
                break
            case .video:
                didRetrieveMediaTypeLookup[.video] = true
                break
            case .newsletter:
                didRetrieveMediaTypeLookup[.newsletter] = true
                break
            }
        }
        
        if let shouldRefreshVideo = (didRetrieveMediaTypeLookup[.video]),
           shouldRefreshVideo == true{
            NotificationCenter.default.post(name: .refreshVideoUI, object: nil)
        }
        
        if let shouldRefreshNL = (didRetrieveMediaTypeLookup[.newsletter]),
        shouldRefreshNL == true{
            NotificationCenter.default.post(name: .refreshNewsletterUI, object: nil)
        }
        
        if let shouldRefreshPodcast = (didRetrieveMediaTypeLookup[.podcast]),
        shouldRefreshPodcast == true{
            NotificationCenter.default.post(name: .refreshPodcastUI, object: nil)
        }
    }
    
    func downloadLastPod(feed:ContentFeed){
        let _ = Array(feed.items ?? []).map({
            print("ItemID:\($0.itemID) ObjectID:\($0.objectID) Title:\($0.title) Date:\($0.dateUpdated)")
            print("-----")
        })
        //2. Pluck the latest episode and download it for each feed
        let lastItem = Array(feed.items ?? []).sorted { (first, second) in
            let firstDate = first.dateUpdated ?? first.datePublished ?? Date.init(timeIntervalSince1970: 0)
            let secondDate = second.dateUpdated ?? second.datePublished ?? Date.init(timeIntervalSince1970: 0)

            return firstDate > secondDate
        }.first
        if let valid_item = lastItem{
            var lastEpisode = PodcastEpisode.convertFrom(contentFeedItem: valid_item)
            //print(lastEpisode.title)
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
    
    func fetchItems() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            AlertHelper.showAlert(
                title: "Data Loading Error",
                message: "\(error)"
            )
        }
    }
}
