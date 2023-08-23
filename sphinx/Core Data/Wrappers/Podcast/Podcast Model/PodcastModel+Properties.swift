// PodcastModel+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//
    
//

import Foundation
import CoreData

public class PodcastModel: NSObject {
    
    public var type: String?
    public var suggestedBTC: Double
    public var feed: PodcastFeed?
    
    override init() {
        self.suggestedBTC = 0.0
        
        super.init()
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
        
        let podcastModel = PodcastModel()
        
        podcastModel.suggestedBTC = contentFeedPaymentModel.suggestedBTC
        podcastModel.type = contentFeedPaymentModel.type
        podcastModel.feed = feed
        
        return podcastModel
    }
}
