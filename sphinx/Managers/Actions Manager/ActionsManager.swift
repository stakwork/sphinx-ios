//
//  ActionsManager.swift
//  sphinx
//
//  Created by Tomas Timinskas on 23/09/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import CoreData

class ActionsManager {
    
    enum ActionType : Int {
        case Message = 0
        case FeedSearch = 1
        case ContentBoost = 2
        case PodcastClipComment = 3
        case ContentConsumed = 4
    }
    
    var contentConsumedAction: ContentConsumedAction? = nil
    var contentConsumedHistoryItem: ContentConsumedHistoryItem? = nil
    
    let rake = Rake()
    let globalThread = DispatchQueue.global()

    class var sharedInstance : ActionsManager {
        struct Static {
            static let instance = ActionsManager()
        }
        return Static.instance
    }
    
    func isTrackingEnabled() -> Bool {
        return UserDefaults.Keys.shouldTrackActions.get(defaultValue: false)
    }
    
    var searchActions: [FeedSearchAction] = []
    
    func trackFeedSearch(searchTerm: String) {
        if(!isTrackingEnabled()) { return }
        
        globalThread.sync {
            if let sa = searchActions.last {
                if (searchTerm.contains(sa.searchTerm)) {
                    searchActions.removeLast()
                } else if (sa.searchTerm.contains(searchTerm)) {
                    return
                }
            }
            let count = ActionTrack.getSearchCountFor(searchTerm: searchTerm)
            
            searchActions.append(
                FeedSearchAction(frequency: count + 1, searchTerm: searchTerm.lowerClean, currentTimestamp: Date())
            )
        }
    }
    
    func saveFeedSearches() {
        if(!isTrackingEnabled()) { return }
        
        globalThread.sync {
            for searchAction in self.searchActions {
                if let jsonString = searchAction.jsonString() {
                    let _ = ActionTrack.createObject(type: ActionType.FeedSearch.rawValue, uploaded: false, metaData: jsonString)
                }
            }
            self.searchActions.removeAll()
        }
    }
    
    func trackMessageSent(message: TransactionMessage) {
        if(!isTrackingEnabled()) { return }
        
//        globalThread.sync {
//            guard let messagesContent = message.messageContent, !messagesContent.isEmpty else {
//                return
//            }
//            
//            let scoreDict =  self.rake.run(text: messagesContent)
//            let scoreDictSorted = scoreDict.sorted {
//                $0.value > $1.value
//            }
//            let keywords = Array(scoreDictSorted.map {
//                $0.key.removingPunctuation()
//            }.prefix(5))
//            
//            if (keywords.count < 1) {
//                return
//            }
//            
//            let messageAction = MessageAction(keywords: keywords, currentTimestamp: Date())
//            if let jsonString = messageAction.jsonString() {
//                
//                print("SAVING MESSAGE SENT")
//                print(jsonString)
//                print("SAVING MESSAGE SENT")
//                
//                let _ = ActionTrack.createObject(type: ActionType.Message.rawValue, uploaded: false, metaData: jsonString)
//            }
//        }
    }
    
    func trackContentBoost(
        amount: Int,
        feedItem: ContentFeedItem
    ) {
        if(!isTrackingEnabled()) { return }
        
        globalThread.sync {
            let contentBoostAction = ContentBoostAction(
                boost: amount,
                feedId: feedItem.contentFeed?.feedID ?? "FeedId",
                feedType: Int(feedItem.contentFeed?.feedKind.rawValue ?? -1),
                feedUrl: feedItem.contentFeed?.feedURL?.absoluteString ?? "",
                feedItemId: feedItem.itemID,
                feedItemUrl: feedItem.enclosureURL?.absoluteString ?? "",
                showTitle: feedItem.contentFeed?.title ?? "",
                episodeTitle: feedItem.title,
                description: feedItem.itemDescription ?? "",
                topics: [], //Get topics from description with KeyBERT
                people: feedItem.people,
                publishDate: feedItem.datePublished ?? Date(),
                currentTimestamp: Date()
            )
            
            if let jsonString = contentBoostAction.jsonString() {
                let _ = ActionTrack.createObject(type: ActionType.ContentBoost.rawValue, uploaded: false, metaData: jsonString)
            }
        }
    }
    
    func trackClipComment(
        podcastComment: PodcastComment
    ) {
        if(!isTrackingEnabled()) { return }
        
        globalThread.sync {
            guard let feedItemObjectId = podcastComment.feedItemObjectId,
                  let feedItem: ContentFeedItem = CoreDataManager.sharedManager.getObjectWith(objectId: feedItemObjectId),
                  let timestamp = podcastComment.timestamp else {
                
                return
            }
            
            let podcastClipAction = PodcastClipAction(
                feedId: feedItem.contentFeed?.feedID ?? "FeedId",
                feedType: Int(FeedType.Podcast.rawValue),
                feedUrl: feedItem.contentFeed?.feedURL?.absoluteString ?? "",
                feedItemId: feedItem.itemID,
                feedItemUrl: feedItem.enclosureURL?.absoluteString ?? "",
                showTitle: feedItem.contentFeed?.title ?? "",
                episodeTitle: feedItem.title,
                description: feedItem.itemDescription ?? "",
                topics: [], //Get topics from description with KeyBERT
                people: feedItem.people,
                publishDate: feedItem.datePublished ?? Date(),
                startTimestamp: timestamp,
                endTimestamp: timestamp,
                currentTimestamp: Date()
            )
            
            if let jsonString = podcastClipAction.jsonString() {
                let _ = ActionTrack.createObject(type: ActionType.PodcastClipComment.rawValue, uploaded: false, metaData: jsonString)
            }
        }
    }
    
    func trackItemConsumed(
        item: ContentFeedItem,
        startTimestamp: Int,
        endTimestamp: Int? = nil
    ) {
        if(!isTrackingEnabled()) { return }
        
        globalThread.sync {
            if let contentConsumedAction = self.contentConsumedAction {
                
                if let endTimestamp = endTimestamp {
                    self.trackItemFinished(
                        item: item,
                        timestamp: endTimestamp
                    )
                }
                
                if contentConsumedAction.feedId != item.contentFeed?.feedID {
                    self.finishAndSaveContentConsumed()
                }
                
                self.contentConsumedHistoryItem = ContentConsumedHistoryItem(startTimestamp: 0, currentTimestamp: Date())
                self.contentConsumedHistoryItem?.startTimestamp = startTimestamp * 1000
                self.contentConsumedHistoryItem?.currentTimestamp = Date()
                self.contentConsumedHistoryItem?.topics = []
                
            } else {
                
                self.contentConsumedAction = ContentConsumedAction(
                    feedId: item.contentFeed?.feedID ?? "FeedId",
                    feedType: Int(item.contentFeed?.feedKind.rawValue ?? -1),
                    feedUrl: item.contentFeed?.feedURL?.absoluteString ?? "",
                    feedItemId: item.itemID,
                    feedItemUrl: item.enclosureURL?.absoluteString ?? "",
                    clipRank: 0,
                    showTitle: item.contentFeed?.title ?? "",
                    episodeTitle: item.title,
                    description: item.itemDescription ?? "",
                    people: item.people,
                    publishDate: item.datePublished ?? Date()
                )
                
                self.contentConsumedHistoryItem = ContentConsumedHistoryItem(startTimestamp: 0, currentTimestamp: Date())
                self.contentConsumedHistoryItem?.startTimestamp = startTimestamp * 1000
                self.contentConsumedHistoryItem?.currentTimestamp = Date()
                self.contentConsumedHistoryItem?.topics = []
            }
        }
    }
    
    func trackItemFinished(
        item: ContentFeedItem,
        timestamp: Int,
        shouldSaveAction: Bool = false
    ) {
        trackItemFinished(
            feedId: item.contentFeed?.feedID,
            feedItemId: item.itemID,
            timestamp: timestamp,
            shouldSaveAction: shouldSaveAction
        )
    }
    
    func trackItemConsumed(
        item: PodcastEpisode,
        podcast: PodcastFeed,
        startTimestamp: Int,
        endTimestamp: Int? = nil
    ) {
        if(!isTrackingEnabled()) { return }
        
        globalThread.sync {
            if let contentConsumedAction = self.contentConsumedAction {
                
                if let endTimestamp = endTimestamp {
                    self.trackItemFinished(
                        item: item,
                        podcast: podcast,
                        timestamp: endTimestamp
                    )
                }
                
                if contentConsumedAction.feedId != podcast.feedID {
                    self.finishAndSaveContentConsumed()
                }
                
                self.contentConsumedHistoryItem = ContentConsumedHistoryItem(startTimestamp: 0, currentTimestamp: Date())
                self.contentConsumedHistoryItem?.startTimestamp = startTimestamp * 1000
                self.contentConsumedHistoryItem?.currentTimestamp = Date()
                self.contentConsumedHistoryItem?.topics = item.topics
                
            } else {
                
                self.contentConsumedAction = ContentConsumedAction(
                    feedId: podcast.feedID,
                    feedType: item.intType,
                    feedUrl: podcast.feedURLPath ?? "",
                    feedItemId: item.itemID,
                    feedItemUrl: item.linkURLPath ?? "",
                    clipRank: podcast.getItemRankForEpisodeWithId(id: item.itemID),
                    showTitle: item.showTitle ?? podcast.title ?? "",
                    episodeTitle: item.title ?? "",
                    description: item.episodeDescription ?? "",
                    people: item.people,
                    publishDate: item.datePublished ?? Date()
                )
                
                self.contentConsumedHistoryItem = ContentConsumedHistoryItem(startTimestamp: 0, currentTimestamp: Date())
                self.contentConsumedHistoryItem?.startTimestamp = startTimestamp * 1000
                self.contentConsumedHistoryItem?.currentTimestamp = Date()
                self.contentConsumedHistoryItem?.topics = item.topics
            }
        }
    }
    
    func trackItemFinished(
        item: PodcastEpisode,
        podcast: PodcastFeed,
        timestamp: Int,
        shouldSaveAction: Bool = false
    ) {
        trackItemFinished(
            feedId: podcast.feedID,
            feedItemId: item.itemID,
            timestamp: timestamp,
            shouldSaveAction: shouldSaveAction
        )
    }
    
    func trackItemFinished(
        feedId: String?,
        feedItemId: String,
        timestamp: Int,
        shouldSaveAction: Bool = false
    ) {
        if(!isTrackingEnabled()) { return }
        
        globalThread.sync {
            if let contentConsumedAction = self.contentConsumedAction {
                if contentConsumedAction.feedId == feedId {
                    
                    if let historyItem = self.contentConsumedHistoryItem {
                        if contentConsumedAction.feedItemId == feedItemId {
                            if historyItem.endTimestamp == nil {
                                historyItem.endTimestamp = timestamp * 1000
                            }

                            self.finishAndSaveHistoryItem()
                        }
                    }
                }
            }
            
            if shouldSaveAction {
                self.finishAndSaveContentConsumed()
            }
        }
    }
    
    func finishAndSaveContentConsumed() {
        if(!isTrackingEnabled()) { return }
        
        globalThread.sync {
            if let contentConsumedAction = self.contentConsumedAction {
                self.finishAndSaveHistoryItem()
                
                if contentConsumedAction.isValid() {
                    if let jsonString = contentConsumedAction.jsonString() {
                        let _ = ActionTrack.createObject(type: ActionType.ContentConsumed.rawValue, uploaded: false, metaData: jsonString)
                    }
                }
                self.contentConsumedAction = nil
            }
        }
    }
    
    func finishAndSaveHistoryItem() {
        if(!isTrackingEnabled()) { return }
        
        globalThread.sync {
            if let contentConsumedHistoryItem = self.contentConsumedHistoryItem {
                if contentConsumedHistoryItem.isValid() {
                    self.contentConsumedAction?.addItem(historyItem: contentConsumedHistoryItem)
                }
            }
            self.contentConsumedHistoryItem = nil
        }
    }
    
    func trackNewsletterConsumed(newsletterItem: NewsletterItem) {
        if(!isTrackingEnabled()) { return }
        
        globalThread.sync {
            guard let feedItem: ContentFeedItem = CoreDataManager.sharedManager.getObjectWith(objectId: newsletterItem.objectID) else {
                return
            }
            
            let contentConsumedHistoryItem = ContentConsumedHistoryItem(startTimestamp: 0, currentTimestamp: Date())
            contentConsumedHistoryItem.endTimestamp = 0
            contentConsumedHistoryItem.topics = []
            
            let contentConsumedAction = ContentConsumedAction(
                feedId: newsletterItem.newsletterFeed?.feedID ?? "FeedId",
                feedType: Int(FeedType.Newsletter.rawValue),
                feedUrl: newsletterItem.newsletterFeed?.feedURL?.absoluteString ?? "",
                feedItemId: newsletterItem.itemID,
                feedItemUrl: newsletterItem.itemUrl?.absoluteString ?? "",
                clipRank: 0,
                showTitle: feedItem.contentFeed?.title ?? "",
                episodeTitle: newsletterItem.title ?? "",
                description: newsletterItem.itemDescription ?? "",
                people: feedItem.people,
                publishDate: newsletterItem.datePublished ?? Date()
            )
            
            contentConsumedAction.addItem(historyItem: contentConsumedHistoryItem)
            
            if let jsonString = contentConsumedAction.jsonString() {
                let _ = ActionTrack.createObject(type: ActionType.ContentConsumed.rawValue, uploaded: false, metaData: jsonString)
            }
        }
    }
    
    func syncActions(
        completion: (() -> ())? = nil
    ) {
        if(!isTrackingEnabled()) {
            completion?()
            return
        }
        
        let dispatchQueue = DispatchQueue(label: "sync-actions")
        dispatchQueue.async {
            let actions = ActionTrack.getUnsynced()
            
            guard actions.count > 0 else {
                completion?()
                return
            }
            
            let chunkedActions = actions.chunked(into: 50)
            
            let dispatchGroup = DispatchGroup()
            let dispatchSemaphore = DispatchSemaphore(value: 0)
            
            for chunk in chunkedActions {
                
                dispatchGroup.enter()
                
                API.sharedInstance.syncActions(actions: chunk, callback: { success in
                    if (success) {
                        self.updateSyncedActions(objectIds: chunk.map { $0.objectID })
                    }
                    
                    dispatchSemaphore.signal()
                    dispatchGroup.leave()
                })
                
                dispatchSemaphore.wait()
            }
            
            completion?()
        }
    }
    
    func updateSyncedActions(objectIds: [NSManagedObjectID]) {
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        if let entityDescription = NSEntityDescription.entity(forEntityName: "ActionTrack", in: managedContext) {
            
            let batchUpdateRequest = NSBatchUpdateRequest(entity: entityDescription)
            
            batchUpdateRequest.predicate = NSPredicate(format: "self IN %@", objectIds)
            batchUpdateRequest.resultType = .updatedObjectIDsResultType
            batchUpdateRequest.propertiesToUpdate = ["uploaded": true]
             
            do {
                try managedContext.execute(batchUpdateRequest)
            } catch {
                let updateError = error as NSError
                print("\(updateError), \(updateError.userInfo)")
            }
        }
    }
}
