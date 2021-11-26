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


// MARK: -  Public Methods
extension PodcastModel {
    
    public static func convertFrom(
        contentFeedPaymentModel: ContentFeedPaymentModel,
        persistingIn managedObjectContext: NSManagedObjectContext? = nil
    ) -> PodcastModel {
        let podcastModel: PodcastModel
        
        if let managedObjectContext = managedObjectContext {
            podcastModel = PodcastModel(context: managedObjectContext)
        } else {
            podcastModel = PodcastModel(entity: PodcastModel.entity(), insertInto: nil)
        }
        
        podcastModel.suggestedBTC = contentFeedPaymentModel.suggestedBTC
        podcastModel.type = contentFeedPaymentModel.type
        
        return podcastModel
    }
}
