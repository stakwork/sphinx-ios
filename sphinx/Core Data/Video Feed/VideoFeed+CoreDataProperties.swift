// VideoFeed+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//
    
//

import Foundation
import CoreData


extension VideoFeed {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VideoFeed> {
        return NSFetchRequest<VideoFeed>(entityName: "VideoFeed")
    }

    @NSManaged public var author: String?
    @NSManaged public var feedDescription: String?
    @NSManaged public var feedURL: URL?
    @NSManaged public var feedOwnerURL: URL?
    @NSManaged public var imageURL: URL?
    @NSManaged public var title: String?
    @NSManaged public var feedID: String
    @NSManaged public var datePublished: Date?
    @NSManaged public var dateUpdated: Date?
    @NSManaged public var generator: String?
    
    @NSManaged public var chat: Chat?
    @NSManaged public var videos: Set<Video>?
}


// MARK: -  Public Methods
extension VideoFeed {
    
    public static func convertedFrom(
        contentFeed: ContentFeed
    ) -> Self {
        guard let managedObjectContext = contentFeed.managedObjectContext else {
            preconditionFailure()
        }
        
        let videoFeed = Self(context: managedObjectContext)
        
        videoFeed.feedID = contentFeed.feedID
        videoFeed.title = contentFeed.title
        videoFeed.author = contentFeed.authorName
        videoFeed.feedDescription = contentFeed.feedDescription
        videoFeed.datePublished = contentFeed.datePublished
        videoFeed.dateUpdated = contentFeed.dateUpdated
        videoFeed.feedURL = contentFeed.feedURL
        videoFeed.feedOwnerURL = contentFeed.ownerURL
        videoFeed.imageURL = contentFeed.imageURL
        videoFeed.generator = contentFeed.generator
        videoFeed.chat = contentFeed.chat
        
        videoFeed.videos = Set(
            contentFeed
                .items?
                .map(Video.convertedFrom(contentFeedItem:))
            ?? []
        )
        
        return videoFeed
    }
}


// MARK: Generated accessors for videos
extension VideoFeed {

    @objc(addVideosObject:)
    @NSManaged public func addToVideos(_ value: Video)

    @objc(removeVideosObject:)
    @NSManaged public func removeFromVideos(_ value: Video)

    @objc(addVideos:)
    @NSManaged public func addToVideos(_ values: Set<Video>)

    @objc(removeVideos:)
    @NSManaged public func removeFromVideos(_ values: Set<Video>)

}
