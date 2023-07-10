// PodcastFeed+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//

import Foundation
import CoreData
import SwiftyJSON

public class PodcastFeed: NSObject {
    
    public var feedID: String
    public var title: String?
    public var podcastDescription: String?
    public var author: String?
    public var datePublished: Date?
    public var dateUpdated: Date?
    public var generator: String?
    public var imageURLPath: String?
    public var feedURLPath: String?
    public var isSubscribedToFromSearch: Bool
    public var chat: Chat?
    public var dateLastConsumed:Date?
    public var model: PodcastModel?
    public var episodes: Array<PodcastEpisode>?
    public var destinations: Array<PodcastDestination>?
    
    
    init(
        _ feedID: String,
        _ isSubscribedToFromSearch: Bool
    ) {
        self.feedID = feedID
        self.isSubscribedToFromSearch = isSubscribedToFromSearch
    }
    
    var sortedEpisodesArray: [PodcastEpisode] = []
}

// MARK: -  Public Methods
extension PodcastFeed {
    
    public static func convertFrom(
        contentFeed: ContentFeed
    ) -> PodcastFeed {
        
        let podcastFeed = PodcastFeed(
            contentFeed.feedID,
            contentFeed.isSubscribedToFromSearch
        )
        
        podcastFeed.title = contentFeed.title
        podcastFeed.podcastDescription = contentFeed.feedDescription
        podcastFeed.feedURLPath = contentFeed.feedURL?.absoluteString
        podcastFeed.datePublished = contentFeed.datePublished
        podcastFeed.dateUpdated = contentFeed.dateUpdated
        podcastFeed.author = contentFeed.authorName
        podcastFeed.imageURLPath = contentFeed.imageURL?.absoluteString
        podcastFeed.generator = contentFeed.generator
        podcastFeed.chat = contentFeed.chat
        podcastFeed.dateLastConsumed = contentFeed.dateLastConsumed
        
        podcastFeed.episodes = contentFeed
                .items?
                .map {
                    PodcastEpisode.convertFrom(
                        contentFeedItem: $0,
                        feed: podcastFeed
                    )
                }
            ?? []
        
        podcastFeed.destinations = contentFeed
                .paymentDestinations?
                .map {
                    PodcastDestination.convertFrom(
                        contentFeedPaymentDestination: $0,
                        feed: podcastFeed
                    )
                }
            ?? []
        
        if let paymentModel = contentFeed.paymentModel {
            podcastFeed.model = PodcastModel.convertFrom(
                contentFeedPaymentModel: paymentModel,
                feed: podcastFeed
            )
        }
        
        return podcastFeed
    }
    
    public static func convertFrom(
        searchResult: JSON
    ) -> PodcastFeed {
        
        let podcastFeed = PodcastFeed(
            searchResult[ContentFeed.CodingKeys.feedID.rawValue].stringValue,
            false
        )
        
        podcastFeed.title = searchResult[ContentFeed.CodingKeys.title.rawValue].stringValue
        podcastFeed.podcastDescription = searchResult[ContentFeed.CodingKeys.feedDescription.rawValue].stringValue
        podcastFeed.feedURLPath = searchResult[ContentFeed.CodingKeys.feedURL.rawValue].stringValue
        podcastFeed.author = searchResult[ContentFeed.CodingKeys.authorName.rawValue].stringValue
        podcastFeed.imageURLPath = searchResult[ContentFeed.CodingKeys.imageURL.rawValue].stringValue
        podcastFeed.generator = searchResult[ContentFeed.CodingKeys.generator.rawValue].stringValue
        
        return podcastFeed
    }
    
    public func updateLastDownloadedEpisodeWith(id: String?) {
        if let feed = ContentFeed.getFeedById(feedId: feedID) {
            feed.lastDownloadedEpisodeId = id
        }
    }
}

extension PodcastFeed: Identifiable {}
