// ContentFeed+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//

import Foundation
import CoreData


extension ContentFeed {
    @NSManaged
    public var feedID: String
    
    @NSManaged
    internal var feedKindValue: FeedType.RawValue
   
    @NSManaged
    internal var mediaKindValue: ContentFeedMediaKind.RawValue
    
    @NSManaged
    public var title: String?
    
    @NSManaged
    public var ownerURL: URL?
    
    @NSManaged
    public var generator: String?
    
    @NSManaged
    public var authorName: String?
    
    @NSManaged
    public var imageURL: URL?
    
    @NSManaged
    public var feedDescription: String?
    
    @NSManaged
    public var feedURL: URL?
    
    @NSManaged
    public var linkURL: URL?
    
    @NSManaged
    public var datePublished: Date?
    
    @NSManaged
    public var dateUpdated: Date?
    
    @NSManaged
    public var dateLastConsumed: Date?
    
    @NSManaged
    public var language: String?
    
    @NSManaged
    public var isSubscribedToFromSearch: Bool
    
    @NSManaged
    public var items: Set<ContentFeedItem>?
    
    @NSManaged
    public var chat: Chat?
    
    @NSManaged
    public var paymentDestinations: Set<ContentFeedPaymentDestination>?
    
    @NSManaged
    public var paymentModel: ContentFeedPaymentModel?
    
    @NSManaged
    public var lastDownloadedEpisodeId: String?
}


// MARK: Generated accessors for items
extension ContentFeed {

    @objc(insertObject:inItemsAtIndex:)
    @NSManaged public func insertIntoItems(_ value: ContentFeedItem, at idx: Int)

    @objc(removeObjectFromItemsAtIndex:)
    @NSManaged public func removeFromItems(at idx: Int)

    @objc(insertItems:atIndexes:)
    @NSManaged public func insertIntoItems(_ values: [ContentFeedItem], at indexes: NSIndexSet)

    @objc(removeItemsAtIndexes:)
    @NSManaged public func removeFromItems(at indexes: NSIndexSet)

    @objc(replaceObjectInItemsAtIndex:withObject:)
    @NSManaged public func replaceItems(at idx: Int, with value: ContentFeedItem)

    @objc(replaceItemsAtIndexes:withItems:)
    @NSManaged public func replaceItems(at indexes: NSIndexSet, with values: [ContentFeedItem])

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: ContentFeedItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: ContentFeedItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: Set<ContentFeedItem>)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: Set<ContentFeedItem>)
}


// MARK: Generated accessors for paymentDestinations
extension ContentFeed {

    @objc(addPaymentDestinationsObject:)
    @NSManaged public func addToPaymentDestinations(_ value: ContentFeedPaymentDestination)

    @objc(removePaymentDestinationsObject:)
    @NSManaged public func removeFromPaymentDestinations(_ value: ContentFeedPaymentDestination)

    @objc(addPaymentDestinations:)
    @NSManaged public func addToPaymentDestinations(_ values: Set<ContentFeedPaymentDestination>)

    @objc(removePaymentDestinations:)
    @NSManaged public func removeFromPaymentDestinations(_ values: Set<ContentFeedPaymentDestination>)

}


extension ContentFeed : Identifiable {
    public var id: String { feedID }
}


// MARK: - Coding Keys
extension ContentFeed {
    
    enum CodingKeys: String, CodingKey {
        case feedID = "id"
        case title = "title"
        case feedKindValue = "feedType"
        case mediaKindValue = "contentType"
        case ownerURL = "ownerUrl"
        case generator = "generator"
        case authorName = "author"
        case imageURL = "imageUrl"
        case feedDescription = "description"
        case feedURL = "url"
        case linkURL = "link"
        case datePublished = "datePublished"
        case dateUpdated = "dateUpdated"
        case language = "language"
        case items = "items"
        case value = "value"
        
        
        enum Value: String, CodingKey {
            case paymentModel = "model"
            case paymentDestinations = "destinations"
        }
    }
}

