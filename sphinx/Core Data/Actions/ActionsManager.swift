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

    class var sharedInstance : ActionsManager {
        struct Static {
            static let instance = ActionsManager()
        }
        return Static.instance
    }
    
    func test() {
        for a in ActionTrack.getAll() {
            CoreDataManager.sharedManager.deleteObject(object: a)
        }
        
        let messageAction = MessageAction(keywords: ["bitcoin","lightning","sphinx"], currentTimestamp: Date())
        if let jsonString = messageAction.jsonString() {
            let _ = ActionTrack.createObject(type: ActionType.Message.rawValue, uploaded: false, metaData: jsonString)
        }

        let searchAction = FeedSearchAction(frequency: 1, searchTerm: "testing", currentTimestamp: Date())
        if let jsonString = searchAction.jsonString() {
            let _ = ActionTrack.createObject(type: ActionType.FeedSearch.rawValue, uploaded: false, metaData: jsonString)
        }

        let contentBoostAction = ContentBoostAction(boost: 100, feedId: "FeedId1", feedType: Int(FeedType.Newsletter.rawValue), feedUrl: "http://google.com", feedItemId: "FeedItemId1", feedItemUrl: "http://google.com.ar", topics: ["bitcoin","lightning","sphinx"], currentTimestamp: Date())
        if let jsonString = contentBoostAction.jsonString() {
            let _ = ActionTrack.createObject(type: ActionType.ContentBoost.rawValue, uploaded: false, metaData: jsonString)
        }

        let podcastClipAction = PodcastClipAction(feedId: "FeedId2", feedType: Int(FeedType.Podcast.rawValue), feedUrl: "http://google.com", feedItemId: "FeedItemId2", feedItemUrl: "http://google.com.ar", topics: ["bitcoin","lightning","sphinx"], startTimestamp: Date().advanced(by: TimeInterval(-86400)), endTimestamp: Date().advanced(by: TimeInterval(-72000)), currentTimestamp: Date())
        if let jsonString = podcastClipAction.jsonString() {
            let _ = ActionTrack.createObject(type: ActionType.PodcastClipComment.rawValue, uploaded: false, metaData: jsonString)
        }

        let history1 = ContentConsumedHistoryItem(startTimestamp: Date().advanced(by: TimeInterval(-86400)), endTimestamp: Date().advanced(by: TimeInterval(-72000)), currentTimestamp: Date(), topics: ["bitcoin","lightning","sphinx"])
        let history2 = ContentConsumedHistoryItem(startTimestamp: Date().advanced(by: TimeInterval(-86400*2)), endTimestamp: Date().advanced(by: TimeInterval(-72000*2)), currentTimestamp: Date(), topics: ["bariloche","patagonia","sur"])
        let contenConsumedAction = ContentConsumedAction(feedId: "FeedId3", feedType: Int(FeedType.Video.rawValue), feedUrl: "http://google.com", feedItemId: "FeedItemId3", feedItemUrl: "http://google.com.ar", history: [history1, history2])
        if let jsonString = contenConsumedAction.jsonString() {
            let _ = ActionTrack.createObject(type: ActionType.ContentConsumed.rawValue, uploaded: false, metaData: jsonString)
        }
        
        
        let actions = ActionTrack.getAll()

        for a in actions {
            
            print("{\"type\":\(a.type),\"meta_data\": \(a.metaData)}")
//            print(a.jsonString())
//
//            switch(a.type) {
//            case ActionType.Message.rawValue:
//                let messageAction = MessageAction.messageAction(jsonString: a.metaData)
//                break
//            case ActionType.FeedSearch.rawValue:
//                let feedSearchAction = FeedSearchAction.messageAction(jsonString: a.metaData)
//                break
//            case ActionType.ContentBoost.rawValue:
//                let contentBoostAction = ContentBoostAction.messageAction(jsonString: a.metaData)
//                break
//            case ActionType.PodcastClipComment.rawValue:
//                let podcastClipAction = PodcastClipAction.messageAction(jsonString: a.metaData)
//                break
//            case ActionType.ContentConsumed.rawValue:
//                let contentConsumedAction = ContentConsumedAction.messageAction(jsonString: a.metaData)
//                break
//            default:
//                break
//            }
        }
    }
}
