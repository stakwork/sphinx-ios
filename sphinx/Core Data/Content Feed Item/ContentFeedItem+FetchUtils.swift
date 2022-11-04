//
//  ContentFeedItem+FetchUtils.swift
//  sphinx
//
//  Created by Tomas Timinskas on 17/10/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import CoreData


// MARK: - Predicates
extension ContentFeedItem {
    
    public static func getAll() -> [ContentFeedItem] {
        let sortDescriptors = [NSSortDescriptor(key: "itemID", ascending: true)]
        let feedsItem: [ContentFeedItem] = CoreDataManager.sharedManager.getAllOfType(entityName: "ContentFeedItem", sortDescriptors: sortDescriptors)
        return feedsItem
    }
    
    public static func getItemWith(itemID: String) -> ContentFeedItem? {
        let predicate = Predicates.matching(itemID: itemID)
        let feedItem: ContentFeedItem? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "ContentFeedItem")
        return feedItem
    }

    public enum Predicates {
        
        public static func matching(itemID: String) -> NSPredicate {
            let keyword = "=="
            let formatSpecifier = "%@"

            return NSPredicate(
                format: "%K \(keyword) \(formatSpecifier)",
                "itemID",
                itemID
            )
        }
    }
}
