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
    
    public static func convertFrom(
        contentFeed: ContentFeed,
        persistingIn managedObjectContext: NSManagedObjectContext? = nil
    ) -> PodcastFeed {
        let podcastFeed: PodcastFeed
        
        if let managedObjectContext = managedObjectContext {
            podcastFeed = PodcastFeed(context: managedObjectContext)
            podcastFeed.chat = contentFeed.chat
        } else {
            podcastFeed = PodcastFeed(entity: PodcastFeed.entity(), insertInto: nil)
        }
        
        podcastFeed.feedID = contentFeed.feedID
        podcastFeed.title = contentFeed.title
        podcastFeed.podcastDescription = contentFeed.feedDescription
        podcastFeed.feedURLPath = contentFeed.feedURL?.absoluteString
        podcastFeed.datePublished = contentFeed.datePublished
        podcastFeed.dateUpdated = contentFeed.dateUpdated
        podcastFeed.author = contentFeed.authorName
        podcastFeed.imageURLPath = contentFeed.imageURL?.absoluteString
        podcastFeed.generator = contentFeed.generator
        
        podcastFeed.episodes = Set(
            contentFeed
                .items?
                .map {
                    PodcastEpisode.convertFrom(
                        contentFeedItem: $0,
                        persistingIn: managedObjectContext
                    )
                }
            ?? []
        )
        
        podcastFeed.destinations = Set(
            contentFeed
                .paymentDestinations?
                .map {
                    PodcastDestination.convertFrom(
                        contentFeedPaymentDestination: $0,
                        persistingIn: managedObjectContext
                    )
                }
            ?? []
        )
        
        if let paymentModel = contentFeed.paymentModel {
            podcastFeed.model = PodcastModel.convertFrom(
                contentFeedPaymentModel: paymentModel,
                persistingIn: managedObjectContext
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
