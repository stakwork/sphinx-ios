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
    
    func trackFeedSearch(searchTerm: String) {
        globalThread.sync {
            let count = ActionTrack.getSearchCountFor(searchTerm: searchTerm)
            
            let searchAction = FeedSearchAction(frequency: count + 1, searchTerm: searchTerm.lowerClean, currentTimestamp: Date())
            if let jsonString = searchAction.jsonString() {
                
                print("SAVING FEED SEARCH")
                print(jsonString)
                print("SAVING FEED SEARCH")
                
                let _ = ActionTrack.createObject(type: ActionType.FeedSearch.rawValue, uploaded: false, metaData: jsonString)
            }
        }
    }
    
    func trackMessageSent(message: TransactionMessage) {
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
        globalThread.sync {
            let contentBoostAction = ContentBoostAction(
                boost: amount,
                feedId: feedItem.contentFeed?.feedID ?? "FeedId",
                feedType: Int(feedItem.contentFeed?.feedKind.rawValue ?? -1),
                feedUrl: feedItem.contentFeed?.feedURL?.absoluteString ?? "",
                feedItemId: feedItem.itemID,
                feedItemUrl: feedItem.enclosureURL?.absoluteString ?? "",
                topics: [], //Get topics from description with KeyBERT
                currentTimestamp: Date()
            )
            
            if let jsonString = contentBoostAction.jsonString() {
                
                print("SAVING CONTENT BOOST")
                print(jsonString)
                print("SAVING CONTENT BOOST")
                
                let _ = ActionTrack.createObject(type: ActionType.ContentBoost.rawValue, uploaded: false, metaData: jsonString)
            }
        }
    }
    
    func trackClipComment(
        podcastComment: PodcastComment
    ) {
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
                topics: [], //Get topics from description with KeyBERT
                startTimestamp: timestamp,
                endTimestamp: timestamp,
                currentTimestamp: Date()
            )
            
            if let jsonString = podcastClipAction.jsonString() {
                
                print("SAVING CLIP COMMENT")
                print(jsonString)
                print("SAVING CLIP COMMENT")
                
                let _ = ActionTrack.createObject(type: ActionType.PodcastClipComment.rawValue, uploaded: false, metaData: jsonString)
            }
        }
    }
    
    func trackItemConsumed(
        item: ContentFeedItem,
        startTimestamp: Int,
        endTimestamp: Int? = nil
    ) {
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
                    feedItemUrl: item.enclosureURL?.absoluteString ?? ""
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
        globalThread.sync {
            if let contentConsumedAction = self.contentConsumedAction {
                if contentConsumedAction.feedId == item.contentFeed?.feedID {
                    
                    if let historyItem = self.contentConsumedHistoryItem {
                        if contentConsumedAction.feedItemId == item.itemID {
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
        globalThread.sync {
            if let contentConsumedAction = self.contentConsumedAction {
                self.finishAndSaveHistoryItem()
                
                if contentConsumedAction.isValid() {
                    if let jsonString = contentConsumedAction.jsonString() {
                        
                        print("SAVING CONTENT CONSUMED")
                        print(jsonString)
                        print("SAVING CONTENT CONSUMED")
                        
                        let _ = ActionTrack.createObject(type: ActionType.ContentConsumed.rawValue, uploaded: false, metaData: jsonString)
                    }
                }
                self.contentConsumedAction = nil
            }
        }
    }
    
    func finishAndSaveHistoryItem() {
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
        globalThread.sync {
            let contentConsumedHistoryItem = ContentConsumedHistoryItem(startTimestamp: 0, currentTimestamp: Date())
            contentConsumedHistoryItem.endTimestamp = 0
            contentConsumedHistoryItem.topics = []
            
            let contentConsumedAction = ContentConsumedAction(
                feedId: newsletterItem.newsletterFeed?.feedID ?? "FeedId",
                feedType: Int(FeedType.Newsletter.rawValue),
                feedUrl: newsletterItem.newsletterFeed?.feedURL?.absoluteString ?? "",
                feedItemId: newsletterItem.itemID,
                feedItemUrl: newsletterItem.itemUrl?.absoluteString ?? ""
            )
            
            contentConsumedAction.addItem(historyItem: contentConsumedHistoryItem)
            
            if let jsonString = contentConsumedAction.jsonString() {
                
                print("SAVING CONTENT CONSUMED")
                print(jsonString)
                print("SAVING CONTENT CONSUMED")
                
                let _ = ActionTrack.createObject(type: ActionType.ContentConsumed.rawValue, uploaded: false, metaData: jsonString)
            }
        }
    }
    
    func syncActions() {
        let dispatchQueue = DispatchQueue(label: "sync-actions")
        dispatchQueue.async {
            let actions = ActionTrack.getUnsynced()
            
            guard actions.count > 0 else {
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
