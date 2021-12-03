// PodcastModel+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//
    
//

import Foundation
import CoreData

public class PodcastModel: NSObject {
    
    public var objectID: NSManagedObjectID
    public var type: String?
    public var suggestedBTC: Double
    public var feed: PodcastFeed?
    
    init(_ objectID: NSManagedObjectID) {
        self.objectID = objectID
        self.suggestedBTC = 0.0
    }
}

extension PodcastModel {

    public class func fetchRequest() -> NSFetchRequest<ContentFeedPaymentModel> {
        return NSFetchRequest<ContentFeedPaymentModel>(entityName: "ContentFeedPaymentModel")
    }
}

extension PodcastModel : Identifiable {}


// MARK: -  Public Methods
extension PodcastModel {
    
    public static func convertFrom(
        contentFeedPaymentModel: ContentFeedPaymentModel,
        feed: PodcastFeed? = nil
    ) -> PodcastModel {
        
        let podcastModel = PodcastModel(contentFeedPaymentModel.objectID)
        
        podcastModel.suggestedBTC = contentFeedPaymentModel.suggestedBTC
        podcastModel.type = contentFeedPaymentModel.type
        podcastModel.feed = feed
        
        return podcastModel
    }
}
