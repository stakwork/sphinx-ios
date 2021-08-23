// PodcastFeed+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//

import Foundation
import CoreData


extension PodcastFeed {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PodcastFeed> {
        return NSFetchRequest<PodcastFeed>(entityName: "PodcastFeed")
    }

    @NSManaged public var id: Int64
    @NSManaged public var title: String?
    @NSManaged public var podcastDescription: String?
    @NSManaged public var author: String?
    @NSManaged public var imageURLPath: String?
    @NSManaged public var chat: Chat?
    @NSManaged public var model: PodcastModel?
    @NSManaged public var episodes: NSSet?
    @NSManaged public var destinations: NSSet?

}

// MARK: Generated accessors for episodes
extension PodcastFeed {

    @objc(addEpisodesObject:)
    @NSManaged public func addToEpisodes(_ value: PodcastEpisode)

    @objc(removeEpisodesObject:)
    @NSManaged public func removeFromEpisodes(_ value: PodcastEpisode)

    @objc(addEpisodes:)
    @NSManaged public func addToEpisodes(_ values: NSSet)

    @objc(removeEpisodes:)
    @NSManaged public func removeFromEpisodes(_ values: NSSet)

}

// MARK: Generated accessors for destinations
extension PodcastFeed {

    @objc(addDestinationsObject:)
    @NSManaged public func addToDestinations(_ value: PodcastDestination)

    @objc(removeDestinationsObject:)
    @NSManaged public func removeFromDestinations(_ value: PodcastDestination)

    @objc(addDestinations:)
    @NSManaged public func addToDestinations(_ values: NSSet)

    @objc(removeDestinations:)
    @NSManaged public func removeFromDestinations(_ values: NSSet)

}

extension PodcastFeed: Identifiable {}
