// PodcastModel+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//
    
//

import Foundation
import CoreData


extension PodcastModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PodcastModel> {
        return NSFetchRequest<PodcastModel>(entityName: "PodcastModel")
    }

    @NSManaged public var type: String?
    @NSManaged public var suggestedBTC: Double
    @NSManaged public var feed: PodcastFeed?
}

extension PodcastModel : Identifiable {}
