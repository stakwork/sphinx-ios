// Video+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//
    

import Foundation
import CoreData

public class Video: NSObject {
    
    public var objectID: NSManagedObjectID
    public var videoID: String
    public var datePublished: Date?
    public var dateUpdated: Date?
    public var title: String?
    public var author: String?
    public var videoDescription: String?
    public var itemURL: URL?
    public var mediaURL: URL?
    public var thumbnailURL: URL?
    public var videoFeed: VideoFeed?
    
    init(_ objectID: NSManagedObjectID, _ videoID: String) {
        self.objectID = objectID
        self.videoID = videoID
    }
}


extension Video: Identifiable {
    public var id: String { videoID }
}


extension Video {

    public class func fetchRequest() -> NSFetchRequest<ContentFeedItem> {
        return NSFetchRequest<ContentFeedItem>(entityName: "ContentFeedItem")
    }
    
    var youtubeVideoID: String {
        get {
            return videoID.replacingOccurrences(of: "yt:video:", with: "")
        }
    }
}



// MARK: -  Public Methods
extension Video {
    
    public static func convertFrom(
        contentFeedItem: ContentFeedItem,
        videoFeed: VideoFeed? = nil
    ) -> Video {

        let video = Video(
            contentFeedItem.objectID,
            contentFeedItem.itemID
        )
        
        video.author = contentFeedItem.authorName
        video.datePublished = contentFeedItem.datePublished
        video.dateUpdated = contentFeedItem.dateUpdated
        video.videoDescription = contentFeedItem.itemDescription
        video.itemURL = contentFeedItem.enclosureURL
        video.mediaURL = contentFeedItem.enclosureURL
        video.thumbnailURL = contentFeedItem.imageURL
        video.title = contentFeedItem.title
        video.videoFeed = videoFeed
        
        return video
    }
}
