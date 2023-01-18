//
//  RecommendationResult.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/12/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON

public class RecommendationResult: NSObject {
    
    public var pubKey: String
    public var type: String
    public var id: String
    public var topics: [String]
    public var guests: [String]
    public var weight: Double
    public var itemDescription: String
    public var date: Int?
    public var showTitle: String
    public var boost: Int
    public var smallImageUrl: String?
    public var mediumImageUrl: String?
    public var largeImageUrl: String?
    public var nodeType: String
    public var text: String
    public var timestamp: String
    public var episodeTitle: String
    public var link: String
    
    init(
        _ pubKey: String,
        _ type: String,
        _ id: String,
        _ topics: [String],
        _ guests: [String],
        _ weight: Double,
        _ description: String,
        _ date: Int,
        _ showTitle: String,
        _ boost: Int,
        _ smallImageUrl: String,
        _ mediumImageUrl: String,
        _ largeImageUrl: String,
        _ nodeType: String,
        _ text: String,
        _ timestamp: String,
        _ episodeTitle: String,
        _ link: String
    ) { 
        self.pubKey = pubKey
        self.type = type
        self.id = id
        self.topics = topics
        self.guests = guests
        self.weight = weight
        self.itemDescription = description
        self.date = date
        self.showTitle = showTitle
        self.boost = boost
        self.smallImageUrl = smallImageUrl
        self.mediumImageUrl = mediumImageUrl
        self.largeImageUrl = largeImageUrl
        self.nodeType = nodeType
        self.text = text
        self.timestamp = timestamp
        self.episodeTitle = episodeTitle
        self.link = link
    }
    
    public static func convertFrom(
        recommendationResult: JSON
    ) -> RecommendationResult {
        
        let pubkey = recommendationResult[RecommendationResult.CodingKeys.pubKey.rawValue].stringValue
        let type = recommendationResult[RecommendationResult.CodingKeys.type.rawValue].stringValue
        let id = recommendationResult[RecommendationResult.CodingKeys.refId.rawValue].stringValue
        let weight = recommendationResult[RecommendationResult.CodingKeys.weight.rawValue].doubleValue
        let description = recommendationResult[RecommendationResult.CodingKeys.description.rawValue].stringValue
        let date = recommendationResult[RecommendationResult.CodingKeys.date.rawValue].intValue
        let showTitle = recommendationResult[RecommendationResult.CodingKeys.showTitle.rawValue].stringValue
        let boost = recommendationResult[RecommendationResult.CodingKeys.boost.rawValue].intValue
        let smallImageUrl = recommendationResult[RecommendationResult.CodingKeys.smallImageUrl.rawValue].stringValue
        let mediumImageUrl = recommendationResult[RecommendationResult.CodingKeys.mediumImageUrl.rawValue].stringValue
        let largeImageUrl = recommendationResult[RecommendationResult.CodingKeys.largeImageUrl.rawValue].stringValue
        let nodeType = recommendationResult[RecommendationResult.CodingKeys.nodeType.rawValue].stringValue
        let text = recommendationResult[RecommendationResult.CodingKeys.text.rawValue].stringValue
        let timestamp = recommendationResult[RecommendationResult.CodingKeys.timestamp.rawValue].stringValue
        let episodeTitle = recommendationResult[RecommendationResult.CodingKeys.episodeTitle.rawValue].stringValue
        let link = recommendationResult[RecommendationResult.CodingKeys.link.rawValue].stringValue
        
        var topicsArray: [String] = []
        
        if let topics = recommendationResult[RecommendationResult.CodingKeys.topics.rawValue].array {
            topicsArray = topics.map {
                $0.stringValue
            }
        }
        
        var guestsArray: [String] = []
        
        if let guests = recommendationResult[RecommendationResult.CodingKeys.guests.rawValue].array {
            guestsArray = guests.map {
                $0.stringValue
            }
        }
        
        return RecommendationResult(
            pubkey,
            type,
            id,
            topicsArray,
            guestsArray,
            weight,
            description,
            date,
            showTitle,
            boost,
            smallImageUrl,
            mediumImageUrl,
            largeImageUrl,
            nodeType,
            text,
            timestamp,
            episodeTitle,
            link
        )
    }
}

extension RecommendationResult {
    
    enum CodingKeys: String, CodingKey {
        case pubKey = "pub_key"
        case type = "type"
        case refId = "ref_id"
        case topics = "topics"
        case weight = "weight"
        case description = "description"
        case date = "date"
        case showTitle = "show_title"
        case boost = "boost"
        case keyword = "keyword"
        case smallImageUrl = "s_image_url"
        case mediumImageUrl = "m_image_url"
        case largeImageUrl = "l_image_url"
        case nodeType = "node_type"
        case guests = "guests"
        case text = "text"
        case timestamp = "timestamp"
        case episodeTitle = "episode_title"
        case guestProfiles = "guest_profiles"
        case link = "link"
        
        
        enum Hosts: String, CodingKey {
            case name = "name"
            case twitter = "twitter_handle"
            case profilePicture = "profile_picture"
        }
    }
}

extension RecommendationResult : DashboardFeedSquaredThumbnailCollectionViewItem {
    var imageURLPath: String? {
        mediumImageUrl ?? largeImageUrl ?? smallImageUrl
    }
    
    var titleLines: Int {
        3
    }
    
    
    var subtitle: String? {
        episodeTitle
    }
    
    var title: String? {
        itemDescription
    }
    
    var publishDate: Date? {
        if let date = self.date, date > 0 {
            return Date(timeIntervalSince1970: TimeInterval(date))
        }
        return nil
    }
    
    var placeholderImageName: String? {
        switch type {
        case RecommendationsHelper.PODCAST_TYPE:
            return "podcastPlaceholder"
        case RecommendationsHelper.YOUTUBE_VIDEO_TYPE:
            return "videoPlaceholder"
        case RecommendationsHelper.NEWSLETTER_TYPE:
            return "newsletterPlaceholder"
        default:
            return "podcastPlaceholder"
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
    
    var startSeconds: Int {
        get {
            if let substring = timestamp.split(separator: "-").first {
                return String(substring).toSeconds()
            }
            return 0
        }
    }
            

    var endSeconds: Int {
        get {
            if let substring = timestamp.split(separator: "-").last {
                return String(substring).toSeconds()
            }
            return 0
        }
    }
}

extension String {
    func toSeconds() -> Int {
        let elements = self.split(separator: ":")
        if (elements.count == 3) {
            let hours = Int(elements[0]) ?? 0
            let minutes = Int(elements[1]) ?? 0
            let seconds = Int(elements[2]) ?? 0
            return (seconds) + (minutes * 60) + (hours * 60 * 60)
        }
        return 0
    }
}
