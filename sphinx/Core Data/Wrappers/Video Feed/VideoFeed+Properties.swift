// VideoFeed+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//
    
//

import Foundation
import CoreData

public class VideoFeed: NSObject {
    
    public var objectID: NSManagedObjectID
    public var author: String?
    public var feedDescription: String?
    public var feedURL: URL?
    public var feedOwnerURL: URL?
    public var imageURL: URL?
    public var title: String?
    public var feedID: String
    public var datePublished: Date?
    public var dateUpdated: Date?
    public var generator: String?
    
    public var chat: Chat?
    public var videos: Set<Video>?
    
    init(_ objectID: NSManagedObjectID, _ feedID: String) {
        self.objectID = objectID
        self.feedID = feedID
    }
}


extension VideoFeed: Identifiable {
    public var id: String { feedID }
}


extension VideoFeed {

    public class func fetchRequest() -> NSFetchRequest<ContentFeed> {
        return NSFetchRequest<ContentFeed>(entityName: "ContentFeed")
    }
}


// MARK: -  Public Methods
extension VideoFeed {
    
    public static func convertFrom(
        contentFeed: ContentFeed
    ) -> VideoFeed {
        
        let videoFeed = VideoFeed(
            contentFeed.objectID,
            contentFeed.feedID
        )
        
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
                .map {
                    Video.convertFrom(
                        contentFeedItem: $0,
                        videoFeed: videoFeed
                    )
                }
            ?? []
        )
        
        return videoFeed
    }
}
