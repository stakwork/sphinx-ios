// ContentFeedPaymentModel+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//

import Foundation
import CoreData


extension ContentFeedPaymentModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ContentFeedPaymentModel> {
        return NSFetchRequest<ContentFeedPaymentModel>(entityName: "ContentFeedPaymentModel")
    }

    /// The amount in BTC being sent to the content feed's payment destinations.
    @NSManaged
    public var suggestedBTC: Double
    
    
    @NSManaged
    public var type: String?
    
    
    @NSManaged
    public var feed: ContentFeed?
}

extension ContentFeedPaymentModel : Identifiable {}


// MARK: -  Public Methods
extension ContentFeedPaymentModel {
    
    public func legacyPodcastPaymentModel(
        fromLegacyPodcastFeed legacyPodcastFeed: PodcastFeed
    ) -> PodcastModel {
        guard let managedObjectContext = managedObjectContext else {
            preconditionFailure()
        }
        
        let podcastFeedPaymentModel = PodcastModel(context: managedObjectContext)
        
        podcastFeedPaymentModel.type = type
        podcastFeedPaymentModel.suggestedBTC = suggestedBTC
        podcastFeedPaymentModel.feed = legacyPodcastFeed
        
        return podcastFeedPaymentModel
    }
}


// MARK: - Coding Keys
extension ContentFeedPaymentModel {
    
    enum CodingKeys: String, CodingKey {
        case suggestedBTC = "suggested"
        case type = "type"
    }
}

