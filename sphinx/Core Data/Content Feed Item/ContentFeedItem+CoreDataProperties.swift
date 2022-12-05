// ContentFeedItem+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//
    
import Foundation
import CoreData


extension ContentFeedItem {
    
    @NSManaged
    public var itemID: String
    
    @NSManaged
    public var title: String
    
    @NSManaged
    public var authorName: String?

    @NSManaged
    internal var feedKindValue: FeedType.RawValue
    
    @NSManaged
    internal var mediaKindValue: ContentFeedMediaKind.RawValue
    
    @NSManaged
    public var itemDescription: String?
    
    @NSManaged
    public var datePublished: Date?
    
    @NSManaged
    public var dateUpdated: Date?
    
    @NSManaged
    public var enclosureURL: URL?
    
    @NSManaged
    public var enclosureKind: String?
    
    @NSManaged
    public var imageURL: URL?
    
    @NSManaged
    public var linkURL: URL?
    
    @NSManaged
    public var contentFeed: ContentFeed?
    
    @NSManaged
    public var isSubscribedToFromSearch: Bool
}


extension ContentFeedItem: Identifiable {
    public var id: String { itemID }
}


// MARK: -  Public Methods
extension ContentFeedItem {
    
}


// MARK: - Coding Keys
extension ContentFeedItem {
    
    enum CodingKeys: String, CodingKey {
        case itemID = "id"
        case title = "title"
        case authorName = "author"
        case feedKindValue = "feedType"
        case mediaKindValue = "contentType"
        case itemDescription = "description"
        case datePublished = "datePublished"
        case dateUpdated = "dateUpdated"
        case enclosureURL = "enclosureUrl"
        case enclosureKind = "enclosureType"
        case imageURL = "imageUrl"
        case linkURL = "link"
    }
}

