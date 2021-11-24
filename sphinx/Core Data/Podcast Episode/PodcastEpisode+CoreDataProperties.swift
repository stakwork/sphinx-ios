// PodcastEpisode+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//

import Foundation
import CoreData


extension PodcastEpisode {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PodcastEpisode> {
        return NSFetchRequest<PodcastEpisode>(entityName: "PodcastEpisode")
    }

    @NSManaged public var itemID: String
    @NSManaged public var title: String?
    @NSManaged public var author: String?
    @NSManaged public var episodeDescription: String?
    @NSManaged public var datePublished: Date?
    @NSManaged public var dateUpdated: Date?
    @NSManaged public var urlPath: String?
    @NSManaged public var imageURLPath: String?
    @NSManaged public var linkURLPath: String?
    @NSManaged public var isDownloaded: Bool
    @NSManaged public var feed: PodcastFeed?
}

extension PodcastEpisode: Identifiable {}


// MARK: -  Public Methods
extension PodcastEpisode {
    
    public static func convertFrom(
        contentFeedItem: ContentFeedItem,
        persistingIn managedObjectContext: NSManagedObjectContext? = nil
    ) -> PodcastEpisode {
        let podcastEpisode: PodcastEpisode
        
        if let managedObjectContext = managedObjectContext {
            podcastEpisode = PodcastEpisode(context: managedObjectContext)
        } else {
            podcastEpisode = PodcastEpisode(entity: PodcastEpisode.entity(), insertInto: nil)
        }
        
        podcastEpisode.itemID = contentFeedItem.itemID
        podcastEpisode.author = contentFeedItem.authorName
        podcastEpisode.datePublished = contentFeedItem.datePublished
        podcastEpisode.dateUpdated = contentFeedItem.dateUpdated
        podcastEpisode.episodeDescription = contentFeedItem.itemDescription
        podcastEpisode.urlPath = contentFeedItem.enclosureURL?.absoluteString
        podcastEpisode.linkURLPath = contentFeedItem.linkURL?.absoluteString
        podcastEpisode.imageURLPath = contentFeedItem.imageURL?.absoluteString
        podcastEpisode.title = contentFeedItem.title
        
        return podcastEpisode
    }
}
