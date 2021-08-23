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
    @NSManaged public var suggested: Double?
    @NSManaged public var suggestedSats: Int64
    @NSManaged public var feed: PodcastFeed?

}

extension PodcastModel : Identifiable {}
