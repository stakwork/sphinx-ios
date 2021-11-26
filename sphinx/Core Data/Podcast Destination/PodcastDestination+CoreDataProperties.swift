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
    
    public static func convertFrom(
        contentFeedPaymentDestination: ContentFeedPaymentDestination,
        persistingIn managedObjectContext: NSManagedObjectContext? = nil
    ) -> PodcastDestination {
        let destination: PodcastDestination
        
        if let managedObjectContext = managedObjectContext {
            destination = PodcastDestination(context: managedObjectContext)
        } else {
            destination = PodcastDestination(entity: PodcastDestination.entity(), insertInto: nil)
        }
        
        destination.address = contentFeedPaymentDestination.address
        destination.split = contentFeedPaymentDestination.split
        destination.type = contentFeedPaymentDestination.type
        
        return destination
    }
}
