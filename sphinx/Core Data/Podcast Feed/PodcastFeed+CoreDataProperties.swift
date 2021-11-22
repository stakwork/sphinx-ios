// PodcastFeed+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//

import Foundation
import CoreData


extension PodcastFeed {
    @NSManaged public var feedID: String
    @NSManaged public var title: String?
    @NSManaged public var podcastDescription: String?
    @NSManaged public var author: String?
    @NSManaged public var datePublished: Date?
    @NSManaged public var dateUpdated: Date?
    @NSManaged public var generator: String?
    @NSManaged public var imageURLPath: String?
    @NSManaged public var feedURLPath: String?
    @NSManaged public var isSubscribedToFromSearch: Bool
    @NSManaged public var chat: Chat?
    @NSManaged public var model: PodcastModel?
    @NSManaged public var episodes: Set<PodcastEpisode>?
    @NSManaged public var destinations: Set<PodcastDestination>?
}


// MARK: -  Public Methods
extension PodcastFeed {
    
    public static func convertedFrom(
        contentFeed: ContentFeed
    ) -> Self {
        guard let managedObjectContext = contentFeed.managedObjectContext else {
            preconditionFailure()
        }
        
        let podcastFeed = Self(context: managedObjectContext)
        
        podcastFeed.feedID = contentFeed.feedID
        podcastFeed.title = contentFeed.title
        podcastFeed.podcastDescription = contentFeed.feedDescription
        podcastFeed.feedURLPath = contentFeed.feedURL?.absoluteString
        podcastFeed.datePublished = contentFeed.datePublished
        podcastFeed.dateUpdated = contentFeed.dateUpdated
        podcastFeed.author = contentFeed.authorName
        podcastFeed.imageURLPath = contentFeed.imageURL?.absoluteString
        podcastFeed.generator = contentFeed.generator
        
        podcastFeed.chat = contentFeed.chat
        
        podcastFeed.episodes = Set(
            contentFeed
                .items?
                .map(PodcastEpisode.convertedFrom(contentFeedItem:))
            ?? []
        )
        
        podcastFeed.destinations = Set(
            contentFeed
                .paymentDestinations?
                .map(
                    PodcastDestination
                        .convertedFrom(contentFeedPaymentDestination:)
                )
            ?? []
        )
        
        if let paymentModel = contentFeed.paymentModel {
            podcastFeed.model = PodcastModel.convertedFrom(
                contentFeedPaymentModel: paymentModel
            )
        }
        
        return podcastFeed
    }
}


// MARK: Generated accessors for episodes
extension PodcastFeed {
    
    @objc(addEpisodesObject:)
    @NSManaged public func addToEpisodes(_ value: PodcastEpisode)
    
    @objc(removeEpisodesObject:)
    @NSManaged public func removeFromEpisodes(_ value: PodcastEpisode)
    
    @objc(addEpisodes:)
    @NSManaged public func addToEpisodes(_ values: Set<PodcastEpisode>)
    
    @objc(removeEpisodes:)
    @NSManaged public func removeFromEpisodes(_ values: Set<PodcastEpisode>)
    
}

// MARK: Generated accessors for destinations
extension PodcastFeed {
    
    @objc(addDestinationsObject:)
    @NSManaged public func addToDestinations(_ value: PodcastDestination)
    
    @objc(removeDestinationsObject:)
    @NSManaged public func removeFromDestinations(_ value: PodcastDestination)
    
    @objc(addDestinations:)
    @NSManaged public func addToDestinations(_ values: Set<PodcastDestination>)
    
    @objc(removeDestinations:)
    @NSManaged public func removeFromDestinations(_ values: Set<PodcastDestination>)
    
}

extension PodcastFeed: Identifiable {}
