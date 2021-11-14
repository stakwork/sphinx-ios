// ContentFeed+Computeds.swift
//
// Created by CypherPoet.
// ✌️
//
    
import Foundation
import CoreData


extension ContentFeed {
    
    public var feedKind: ContentFeedKind {
        get {
            .init(rawValue: feedKindValue)!
        }
        set {
            feedKindValue = newValue.rawValue
        }
    }
    
    
    public var legacyPodcastFeedModel: PodcastFeed? {
        guard feedKind == .podcast else { return nil }
        
        guard let managedObjectContext = managedObjectContext else {
            preconditionFailure()
        }
        
        let podcastFeed = PodcastFeed(context: managedObjectContext)
        
        podcastFeed.author = authorName
        podcastFeed.feedURLPath = feedURL?.absoluteString
        
        if let id = Int64(feedID) {
            podcastFeed.id = id
        }
        
        podcastFeed.imageURLPath = imageURL?.absoluteString
        podcastFeed.isSubscribedFromPodcastIndex = false
        podcastFeed.podcastDescription = feedDescription
        podcastFeed.title = title
        
        podcastFeed.chat = chat

        podcastFeed.episodes = Set(
            items?.map {
                $0.legacyPodcastEpisodeModel(
                    fromLegacyPodcastFeed: podcastFeed
                )
            }
            ?? []
        )
        
        podcastFeed.model = paymentModel?.legacyPodcastPaymentModel(
            fromLegacyPodcastFeed: podcastFeed
        )
        
        podcastFeed.destinations = Set(
            paymentDestinations?.map {
                $0.legacyPodcastPaymentDestinationModel(
                    fromLegacyPodcastFeed: podcastFeed
                )
            }
            ?? []
        )
        
        return podcastFeed
    }
}
