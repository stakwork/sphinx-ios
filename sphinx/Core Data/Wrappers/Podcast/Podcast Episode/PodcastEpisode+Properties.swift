// PodcastEpisode+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//

import Foundation
import CoreData

public class PodcastEpisode: NSObject {
    
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
    public var destination: PodcastDestination? = nil

    //For recommendations podcast
    public var type: String?
    
    init(_ itemID: String) {
        self.itemID = itemID
    }
    
    var wasPlayed: Bool? {
        get {
            return UserDefaults.standard.value(forKey: "wasPlayed-\(itemID)") as? Bool
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "wasPlayed-\(itemID)")
        }
    }
    
    var duration: Int? {
        get {
            return UserDefaults.standard.value(forKey: "duration-\(itemID)") as? Int
        }
        set {
            if (newValue ?? 0 > 0) {
                UserDefaults.standard.set(newValue, forKey: "duration-\(itemID)")
            }
        }
    }
    
    var currentTime: Int? {
        get {
            return UserDefaults.standard.value(forKey: "current-time-\(itemID)") as? Int
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "current-time-\(itemID)")
        }
    }
    
    var dateString : String?{
        let date = self.datePublished
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        if let valid_date = date{
            let dateString = formatter.string(from: valid_date)
            return dateString
        }
        return nil
    }
    
    public enum TimeStringType{
        case elapsed
        case total
        case remaining
    }
    
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
        podcastEpisode.type = RecommendationsHelper.PODCAST_TYPE
        
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
    
    var typeIconImage: String? {
        get {
            switch type {
            case RecommendationsHelper.PODCAST_TYPE:
                return "podcastTypeIcon"
            case RecommendationsHelper.YOUTUBE_VIDEO_TYPE:
                return "youtubeVideoTypeIcon"
            case RecommendationsHelper.TWITTER_TYPE:
                return "twitterTypeIcon"
            default:
                return "podcastTypeIcon"
            }
        }
    }
    
    var typeLabel: String {
        get {
            switch type {
            case RecommendationsHelper.PODCAST_TYPE:
                return "Podcast"
            case RecommendationsHelper.YOUTUBE_VIDEO_TYPE:
                return "Youtube"
            case RecommendationsHelper.TWITTER_TYPE:
                return "Twitter"
            default:
                return "Podcast"
            }
        }
    }
    
    func constructShareLink(useTimestamp:Bool=false)->String?{
        var link : String? = nil
        if let feedID = self.feed?.feedID,
           let feedURL = self.feed?.feedURLPath{
            link = "sphinx.chat://?action=share_content&feedURL=\(feedURL)&feedID=\(feedID)&itemID=\(itemID)"
        }
        
        if useTimestamp == true,
        let timestamp = currentTime,
        let _ = link{
            link! += "&atTime=\(timestamp)"
        }
        return link
    }
    
}
