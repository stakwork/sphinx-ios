// ContentFeedItemVariant.swift
//
// Created by CypherPoet.
// ✌️
//
    
import Foundation
import CoreData
import SwiftyJSON


@objc(ContentFeedItem)
public final class ContentFeedItem: NSManagedObject {
    
    public static func createObjectFrom(
        json: JSON,
        context: NSManagedObjectContext? = nil
    ) -> ContentFeedItem? {
        
        guard let itemId = json[CodingKeys.itemID.rawValue].string else {
            return nil
        }
        
        var contentFeedItem: ContentFeedItem
        
        if let managedObjectContext = context {
            contentFeedItem = ContentFeedItem(context: managedObjectContext)
        } else {
            contentFeedItem = ContentFeedItem(entity: ContentFeedItem.entity(), insertInto: nil)
        }
        
        contentFeedItem.itemID = itemId
        
        contentFeedItem.title = json[CodingKeys.title.rawValue].stringValue
        contentFeedItem.authorName = json[CodingKeys.authorName.rawValue].stringValue
        contentFeedItem.itemDescription = json[CodingKeys.itemDescription.rawValue].stringValue
        contentFeedItem.datePublished = Date(timeIntervalSince1970: json[CodingKeys.datePublished.rawValue].doubleValue)
        contentFeedItem.enclosureURL = URL(string: json[CodingKeys.enclosureURL.rawValue].stringValue)
        contentFeedItem.enclosureKind = json[CodingKeys.enclosureKind.rawValue].stringValue
        contentFeedItem.imageURL = URL(string: json[CodingKeys.imageURL.rawValue].stringValue)
        contentFeedItem.linkURL = URL(string: json[CodingKeys.linkURL.rawValue].stringValue)
        
        return contentFeedItem
    }
}

