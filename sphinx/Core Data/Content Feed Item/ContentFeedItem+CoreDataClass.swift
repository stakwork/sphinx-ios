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
    
    public static func convertFrom(
        podcastEpisode: PodcastEpisode,
        feed: PodcastFeed? = nil
    ) -> ContentFeedItem? {
        
        var json = JSON()
        let feedItem = ContentFeedItem.createObjectFrom(json: json)
        
        feedItem?.itemID = podcastEpisode.itemID
        feedItem?.title = podcastEpisode.title ?? ""
        feedItem?.authorName = podcastEpisode.author
        feedItem?.linkURL = URL(string: podcastEpisode.linkURLPath ?? "")
        feedItem?.imageURL = URL(string: podcastEpisode.imageURLPath ?? "")
        feedItem?.datePublished = podcastEpisode.datePublished
        feedItem?.dateUpdated = podcastEpisode.dateUpdated
        feedItem?.itemDescription = podcastEpisode.description
        if let pf = podcastEpisode.feed,
           let cf = ContentFeed.convertFrom(podcastFeed: pf){
            feedItem?.contentFeed = cf
        }
        
        return feedItem
    }
    
    public static func convertFrom(
        video: Video,
        videoFeed: VideoFeed? = nil
    ) -> ContentFeedItem? {
        
        let json = JSON()
        let feedItem = ContentFeedItem.createObjectFrom(json: json)
        
        feedItem?.authorName = video.author
        feedItem?.dateUpdated = video.dateUpdated
        feedItem?.datePublished = video.datePublished
        feedItem?.itemID = video.id
        feedItem?.itemDescription = video.description
        feedItem?.imageURL = video.thumbnailURL
        feedItem?.enclosureURL = video.itemURL
        feedItem?.title = video.title ?? ""
        if let vf = videoFeed,
           let cf = ContentFeed.convertFrom(videoFeed: vf){
            feedItem?.contentFeed = cf
        }
        
        return feedItem
    }
}

