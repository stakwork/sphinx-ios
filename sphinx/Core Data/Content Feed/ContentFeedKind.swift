// ContentFeedKind.swift
//
// Created by CypherPoet.
// ✌️
//
    
import Foundation

public enum FeedType: Int16 {
    case Podcast
    case Video
    case Newsletter
}

public struct FeedContentType {
    
    let id: Int16
    var description: String
    
    static var podcast: Self = .init(
        id: FeedType.Podcast.rawValue,
        description: "Podcast"
    )
    static var video: Self = .init(
        id: FeedType.Video.rawValue,
        description: "Video"
    )
    static var newsletter: Self = .init(
        id: FeedType.Newsletter.rawValue,
        description: "Newsletter"
    )
    
    static var allCases: [Self] {
        [
            .podcast,
            .video,
            .newsletter,
        ]
    }
    
    static var defaultValue: Self {
        .podcast
    }
    
    var isPodcast: Bool {
        return self.id == FeedType.Podcast.rawValue
    }
    
    var isVideo: Bool {
        return self.id == FeedType.Video.rawValue
    }
    
    var isNewsletter: Bool {
        return self.id == FeedType.Newsletter.rawValue
    }
}
