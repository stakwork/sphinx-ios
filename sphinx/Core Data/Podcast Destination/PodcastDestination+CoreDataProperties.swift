// PodcastDestination+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//
    
//

import Foundation
import CoreData


extension PodcastDestination {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PodcastDestination> {
        return NSFetchRequest<PodcastDestination>(entityName: "PodcastDestination")
    }

    @NSManaged public var address: String?
    @NSManaged public var split: Double
    @NSManaged public var type: String?
    @NSManaged public var feed: PodcastFeed?

}

extension PodcastDestination: Identifiable {}
