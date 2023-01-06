// PodcastEpisode+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//

import Foundation
import CoreData

public class PodcastEpisode: NSObject {
    
    public var objectID: NSManagedObjectID?
    public var itemID: String
    public var title: String?
    public var author: String?
    public var episodeDescription: String?
    public var datePublished: Date?
    public var dateUpdated: Date?
    public var urlPath: String?
    public var imageURLPath: String?
    public var linkURLPath: String?
    public var clipStartTime: Int?
    public var clipEndTime: Int?
    public var showTitle: String?
    public var feed: PodcastFeed?
    public var people: [String] = []
    public var topics: [String] = []

    //For recommendations podcast
    public var type: String?
    
    init(_ objectID: NSManagedObjectID?, _ itemID: String) {
        self.objectID = objectID
        self.itemID = itemID
    }
    
    var downloaded: Bool? = nil
    
    public var isDownloaded: Bool {
        get {
            if let downloaded = downloaded {
                return downloaded
            }
            if let fileName = URL(string: urlPath ?? "")?.lastPathComponent {
                let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
                return FileManager.default.fileExists(atPath: path.path)
            }
            return false
        }
    }
    
    var duration: Int? = nil
    
    var youtubeVideoId: String? {
        get {
            var videoId: String? = nil
        
            if let urlPath = self.linkURLPath {
                if let range = urlPath.range(of: "v=") {
                    videoId = String(urlPath[range.upperBound...])
                } else if let range = urlPath.range(of: "v/") {
                    videoId = String(urlPath[range.upperBound...])
                }
            }
            
            return videoId
        }
    }
}


extension PodcastEpisode {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ContentFeedItem> {
        return NSFetchRequest<ContentFeedItem>(entityName: "ContentFeedItem")
    }
}

extension PodcastEpisode: Identifiable {}



// MARK: -  Public Methods
extension PodcastEpisode {
    
    public static func convertFrom(
        contentFeedItem: ContentFeedItem,
        feed: PodcastFeed? = nil
    ) -> PodcastEpisode {
        
        let podcastEpisode = PodcastEpisode(
            contentFeedItem.objectID,
            contentFeedItem.itemID
        )
        
        podcastEpisode.author = contentFeedItem.authorName
        podcastEpisode.datePublished = contentFeedItem.datePublished
        podcastEpisode.dateUpdated = contentFeedItem.dateUpdated
        podcastEpisode.episodeDescription = contentFeedItem.itemDescription
        podcastEpisode.urlPath = contentFeedItem.enclosureURL?.absoluteString
        podcastEpisode.linkURLPath = contentFeedItem.linkURL?.absoluteString
        podcastEpisode.imageURLPath = contentFeedItem.imageURL?.absoluteString
        podcastEpisode.title = contentFeedItem.title
        podcastEpisode.feed = feed
        
        return podcastEpisode
    }
    
    var isMusicClip: Bool {
        return type == RecommendationsHelper.PODCAST_TYPE || type == RecommendationsHelper.TWITTER_TYPE
    }
    
    var isPodcast: Bool {
        return type == RecommendationsHelper.PODCAST_TYPE
    }
    
    var isTwitterSpace: Bool {
        return type == RecommendationsHelper.TWITTER_TYPE
    }
    
    var isYoutubeVideo: Bool {
        return type == RecommendationsHelper.YOUTUBE_VIDEO_TYPE
    }

    var intType: Int {
        get {
            if isMusicClip {
                return Int(FeedType.Podcast.rawValue)
            }
            if isYoutubeVideo {
                return Int(FeedType.Video.rawValue)
            }
            return Int(FeedType.Podcast.rawValue)
        }
    }
    
}
