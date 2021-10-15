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
    @NSManaged public var feedURL: URL?
    @NSManaged public var title: String?
    @NSManaged public var feedID: String
    @NSManaged public var datePublished: Date?
    @NSManaged public var chat: Chat?
    @NSManaged public var videos: Set<Video>?

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
