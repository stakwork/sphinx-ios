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


// MARK: -  Public Methods
extension PodcastDestination {
    
    public static func convertedFrom(
        contentFeedPaymentDestination: ContentFeedPaymentDestination
    ) -> Self {
        guard let managedObjectContext = contentFeedPaymentDestination.managedObjectContext else {
            preconditionFailure()
        }

        let destination = Self(context: managedObjectContext)
        
        destination.address = contentFeedPaymentDestination.address
        destination.split = contentFeedPaymentDestination.split
        destination.type = contentFeedPaymentDestination.type
        
        return destination
    }
}
