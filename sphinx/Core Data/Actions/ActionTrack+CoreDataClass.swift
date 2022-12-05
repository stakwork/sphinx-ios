//
//  Action+CoreDataClass.swift
//  sphinx
//
//  Created by Tomas Timinskas on 23/09/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

@objc(ActionTrack)
public class ActionTrack: NSManagedObject, Encodable {
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.type, forKey: .type)
        try container.encode(self.metaData, forKey: .metaData)
    }
    
    static func createObject(
        type: Int,
        uploaded: Bool,
        metaData: String
    ) -> ActionTrack? {
        
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        let action = ActionTrack(context: managedContext) as ActionTrack
        
        action.type = type
        action.uploaded = uploaded
        action.metaData = metaData
        
        CoreDataManager.sharedManager.saveContext()
        
        return action
    }
    
    static func getAll() -> [ActionTrack] {
        let actions : [ActionTrack] = CoreDataManager.sharedManager.getAllOfType(entityName: "ActionTrack", sortDescriptors: [])
        return actions
    }
    
    static func getUnsynced() -> [ActionTrack] {
        let predicate = NSPredicate(format: "uploaded == false")
        let actions: [ActionTrack] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "ActionTrack")
        return actions
    }
    
    public static func getSearchCountFor(searchTerm: String) -> Int {
        let predicate = Predicates.contains(searchTerm: "\"search_term\":\"\(searchTerm.lowerClean)\"")
        return CoreDataManager.sharedManager.getObjectsCountOfTypeWith(predicate: predicate, entityName: "ActionTrack")
    }
    
    func getParamsDictionary() -> [String: Any] {
        switch (self.type) {
        case ActionsManager.ActionType.Message.rawValue:
            if let message = MessageAction.messageAction(jsonString: self.metaData) {
                return message.getParamsDictionary()
            }
        case ActionsManager.ActionType.FeedSearch.rawValue:
            if let feedSearch = FeedSearchAction.feedSearchAction(jsonString: self.metaData) {
                return feedSearch.getParamsDictionary()
            }
            break
        case ActionsManager.ActionType.ContentBoost.rawValue:
            if let contentBoost = ContentBoostAction.contentBoostAction(jsonString: self.metaData) {
                return contentBoost.getParamsDictionary()
            }
            break
        case ActionsManager.ActionType.PodcastClipComment.rawValue:
            if let podcastClip = PodcastClipAction.podcastClipAction(jsonString: self.metaData) {
                return podcastClip.getParamsDictionary()
            }
            break
        case ActionsManager.ActionType.ContentConsumed.rawValue:
            if let contentConsumed = ContentConsumedAction.contentConsumedAction(jsonString: self.metaData) {
                return contentConsumed.getParamsDictionary()
            }
        default:
            return [:]
        }
        return [:]
    }
}

extension ActionTrack {
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case metaData = "meta_data"
    }
}
    
