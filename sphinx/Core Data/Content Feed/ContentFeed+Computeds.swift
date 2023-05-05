// ContentFeed+Computeds.swift
//
// Created by CypherPoet.
// ✌️
//
    
import Foundation
import CoreData


extension ContentFeed {
    
    public var feedKind: FeedType {
        get {
            .init(rawValue: feedKindValue)!
        }
        set {
            feedKindValue = newValue.rawValue
        }
    }
    
    
    public var contentMediaKind: ContentFeedMediaKind {
        get {
            .init(rawValue: mediaKindValue)!
        }
        set {
            mediaKindValue = newValue.rawValue
        }
    }
    
    var isPodcast: Bool {
        return self.feedKind.rawValue == FeedType.Podcast.rawValue
    }
    
    var isVideo: Bool {
        return self.feedKind.rawValue == FeedType.Video.rawValue
    }
    
    var isNewsletter: Bool {
        return self.feedKind.rawValue == FeedType.Newsletter.rawValue
    }
    
    var destinationsArray: [ContentFeedPaymentDestination] {
        guard let destinations = paymentDestinations else { return [] }
        
        return Array(destinations)
    }
    
    var itemsArray: [ContentFeedItem] {
        guard let items = items else {
            return []
        }
        
        if !sortedItemsArray.isEmpty {
               return sortedItemsArray
        }
        
        sortedItemsArray = items.sorted { (first, second) in
            if first.datePublished == nil {
                return false
            } else if second.datePublished == nil {
                return true
            }
            
            return first.datePublished! > second.datePublished!
        }
        
        return sortedItemsArray
    }
}
