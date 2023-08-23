// PodcastDestination+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//
    
//

import Foundation
import CoreData

public class PodcastDestination: NSObject {
    
    public var address: String?
    public var split: Double
    public var type: String?
    public var feed: PodcastFeed?
    
    override init() {
        self.split = 0
        
        super.init()
    }
}


extension PodcastDestination {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ContentFeedPaymentDestination> {
        return NSFetchRequest<ContentFeedPaymentDestination>(entityName: "ContentFeedPaymentDestination")
    }
}

extension PodcastDestination: Identifiable {}


// MARK: -  Public Methods
extension PodcastDestination {
    
    public static func convertFrom(
        contentFeedPaymentDestination: ContentFeedPaymentDestination,
        feed: PodcastFeed? = nil
    ) -> PodcastDestination {
        let destination = PodcastDestination()
        
        destination.address = contentFeedPaymentDestination.address
        destination.split = contentFeedPaymentDestination.split
        destination.type = contentFeedPaymentDestination.type
        destination.feed = feed
        
        
        return destination
    }
}
