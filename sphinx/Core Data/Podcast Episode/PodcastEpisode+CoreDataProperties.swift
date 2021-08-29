// PodcastEpisode+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//

import Foundation
import CoreData


extension PodcastEpisode {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PodcastEpisode> {
        return NSFetchRequest<PodcastEpisode>(entityName: "PodcastEpisode")
    }

    @NSManaged public var id: Int64
    @NSManaged public var title: String?
    @NSManaged public var episodeDescription: String?
    @NSManaged public var datePublished: Date?
    @NSManaged public var urlPath: String?
    @NSManaged public var imageURLPath: String?
    @NSManaged public var linkURLPath: String?
    @NSManaged public var isDownloaded: Bool
    @NSManaged public var feed: PodcastFeed?

}

extension PodcastEpisode: Identifiable {}
