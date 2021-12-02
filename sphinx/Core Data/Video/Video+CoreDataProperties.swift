// Video+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//
    

import Foundation
import CoreData


extension Video {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Video> {
        return NSFetchRequest<Video>(entityName: "Video")
    }

    @NSManaged public var videoID: String
    @NSManaged public var datePublished: Date?
    @NSManaged public var dateUpdated: Date?
    @NSManaged public var title: String?
    @NSManaged public var author: String?
    @NSManaged public var videoDescription: String?
    @NSManaged public var itemURL: URL?
    @NSManaged public var mediaURL: URL?
    @NSManaged public var thumbnailURL: URL?
    @NSManaged public var videoFeed: VideoFeed?
    
    var youtubeVideoID: String {
        get {
            return videoID.replacingOccurrences(of: "yt:video:", with: "")
        }
    }
}



// MARK: -  Public Methods
extension Video {
    
    public static func convertedFrom(
        contentFeedItem: ContentFeedItem
    ) -> Self {
        guard let managedObjectContext = contentFeedItem.managedObjectContext else {
            preconditionFailure()
        }

        let video = Self(context: managedObjectContext)
        
        video.videoID = contentFeedItem.itemID
        video.author = contentFeedItem.authorName
        video.datePublished = contentFeedItem.datePublished
        video.dateUpdated = contentFeedItem.dateUpdated
        video.videoDescription = contentFeedItem.itemDescription
        video.itemURL = contentFeedItem.enclosureURL
        video.mediaURL = contentFeedItem.enclosureURL
        video.thumbnailURL = contentFeedItem.imageURL
        video.title = contentFeedItem.title
        
        return video
    }
}
