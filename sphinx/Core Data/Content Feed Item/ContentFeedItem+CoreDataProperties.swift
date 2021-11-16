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
    internal var feedKindValue: ContentFeedKind.RawValue
    
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
    public var enclosureLength: Int64
    
    @NSManaged
    public var imageURL: URL?
    
    @NSManaged
    public var linkURL: URL?
    
    @NSManaged
    public var isDownloaded: Bool
}


extension ContentFeedItem: Identifiable {
    public var id: String { itemID }
}


// MARK: -  Public Methods
extension ContentFeedItem {
    
    public func legacyPodcastEpisodeModel(
        fromLegacyPodcastFeed legacyPodcastFeed: PodcastFeed
    ) -> PodcastEpisode {
        guard let managedObjectContext = managedObjectContext else {
            preconditionFailure()
        }
        
        let podcastFeedEpisodeModel = PodcastEpisode(context: managedObjectContext)
        
        podcastFeedEpisodeModel.id = Int64(itemID) ?? Int64.random(in: 1...Int64.max)
        podcastFeedEpisodeModel.title = title
        podcastFeedEpisodeModel.episodeDescription = itemDescription
        podcastFeedEpisodeModel.datePublished = datePublished
        podcastFeedEpisodeModel.dateUpdated = dateUpdated
        podcastFeedEpisodeModel.urlPath = enclosureURL?.absoluteString
        podcastFeedEpisodeModel.imageURLPath = imageURL?.absoluteString
        podcastFeedEpisodeModel.isDownloaded = isDownloaded
        podcastFeedEpisodeModel.feed = legacyPodcastFeed
        
        return podcastFeedEpisodeModel
    }
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
        case enclosureLength = "enclosureLength"
        case imageURL = "imageUrl"
        case linkURL = "link"
    }
}

