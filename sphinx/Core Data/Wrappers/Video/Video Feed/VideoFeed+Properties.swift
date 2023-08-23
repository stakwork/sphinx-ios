// VideoFeed+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//
    
//

import Foundation
import CoreData
import SwiftyJSON

public class VideoFeed: NSObject {
    
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
    public var isSubscribedToFromSearch: Bool
    public var dateLastConsumed: Date?
    
    public var chat: Chat?
    public var videos: Array<Video>?
    
    init(
        _ feedID: String,
        _ isSubscribedToFromSearch: Bool
    ) {
        self.feedID = feedID
        self.isSubscribedToFromSearch = isSubscribedToFromSearch
    }
    
    var sortedVideosArray: [Video] = []
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
            contentFeed.feedID,
            contentFeed.isSubscribedToFromSearch
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
        videoFeed.dateLastConsumed = contentFeed.dateLastConsumed
        
        videoFeed.videos = contentFeed
            .items?
            .map {
                Video.convertFrom(
                    contentFeedItem: $0,
                    videoFeed: videoFeed
                )
            }
        ?? []
        
        return videoFeed
    }
    
    public static func convertFrom(
        searchResult: JSON
    ) -> VideoFeed {
        
        let videoFeed = VideoFeed(
            searchResult[ContentFeed.CodingKeys.feedID.rawValue].stringValue,
            false
        )
        
        videoFeed.title = searchResult[ContentFeed.CodingKeys.title.rawValue].stringValue
        videoFeed.feedDescription = searchResult[ContentFeed.CodingKeys.feedDescription.rawValue].stringValue
        videoFeed.feedURL = URL(string: searchResult[ContentFeed.CodingKeys.feedURL.rawValue].stringValue)
        videoFeed.author = searchResult[ContentFeed.CodingKeys.authorName.rawValue].stringValue
        videoFeed.imageURL = URL(string: searchResult[ContentFeed.CodingKeys.imageURL.rawValue].stringValue)
        videoFeed.generator = searchResult[ContentFeed.CodingKeys.generator.rawValue].stringValue
        
        return videoFeed
    }
}
