// ContentFeed+FetchUtils.swift
//
// Created by CypherPoet.
// ✌️
//
    

import Foundation
import CoreData


// MARK: - Predicates
extension ContentFeed {
    
    public static func getAll() -> [ContentFeed] {
        let sortDescriptors = [NSSortDescriptor(key: "feedID", ascending: true)]
        let feeds: [ContentFeed] = CoreDataManager.sharedManager.getAllOfType(entityName: "ContentFeed", sortDescriptors: sortDescriptors)
        return feeds
    }
    
    public static func getFeedWith(feedId: String) -> ContentFeed? {
        let predicate = Predicates.matching(feedID: feedId)
        let feed: ContentFeed? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "ContentFeed")
        return feed
    }

    public enum Predicates {
        
        public static func matching(searchQuery: String) -> NSPredicate {
            let keyword = "CONTAINS[cd]"
            let formatSpecifier = "%@"

            return NSPredicate(
                format: "%K \(keyword) \(formatSpecifier)",
                #keyPath(ContentFeed.title),
                searchQuery
            )
        }
        
        
        public static func matching(feedID: String) -> NSPredicate {
            let keyword = "IN"
            let formatSpecifier = "%@"
            let rawFeedId = feedID
                .replacingOccurrences(of: "yt:channel:", with: "")
                .replacingOccurrences(of: "yt:playlist:", with: "")

            return NSPredicate(
                format: "%K \(keyword) \(formatSpecifier)",
                "feedID",
                [feedID, "yt:channel:\(rawFeedId)", "yt:playlist:\(rawFeedId)"]
            )
        }
        

        public static let followedFeeds: NSPredicate = {
            NSPredicate(
                format: "isSubscribedToFromSearch == true OR chat != nil"
            )
        }()
        
        
        public static let podcastFeeds: NSPredicate = {
            let keyword = "=="
            let formatSpecifier = "%i"

            return NSPredicate(
                format: "%K \(keyword) \(formatSpecifier)",
                "feedKindValue",
                FeedType.Podcast.rawValue
            )
        }()
        
        public static let videoFeeds: NSPredicate = {
            let keyword = "=="
            let formatSpecifier = "%i"

            return NSPredicate(
                format: "%K \(keyword) \(formatSpecifier)",
                "feedKindValue",
                FeedType.Video.rawValue
            )
        }()
    }
}


// MARK: - SortDescriptors
extension ContentFeed {

    // 💡 An instance of `NSFetchedResultsController`, or an `NSFetchRequestResult` created by
    // SwiftUI's `@FetchRequest` property wrapper, requires a fetch request with sort descriptors.

    public enum SortDescriptors {

        public static let nameAscending: NSSortDescriptor = NSSortDescriptor(
            key: #keyPath(ContentFeed.title),
            ascending: true,

            // 🔑 Any time you’re sorting user-facing strings,
            // Apple recommends that you pass in `NSString.localizedStandardCompare(_:)`
            // to sort according to the language rules of the current locale.
            // This means sort will “just work” and do the right thing for
            // languages with special character.
            selector: #selector(NSString.localizedStandardCompare(_:))
        )


        public static let nameDescending: NSSortDescriptor = {
            guard let descriptor = nameAscending.reversedSortDescriptor as? NSSortDescriptor else {
                preconditionFailure("Unable to make reversed sort descriptor")
            }

            return descriptor
        }()
    }
}


// MARK: - FetchRequests
extension ContentFeed {

    public enum FetchRequests {

        public static func baseFetchRequest<ContentFeed>() -> NSFetchRequest<ContentFeed> {
            NSFetchRequest<ContentFeed>(entityName: "ContentFeed")
        }


        public static func `default`() -> NSFetchRequest<ContentFeed> {
            let request: NSFetchRequest<ContentFeed> = baseFetchRequest()

            request.sortDescriptors = [ContentFeed.SortDescriptors.nameAscending]
            request.predicate = nil

            return request
        }
        
        
        public static func matching(searchQuery: String) -> NSFetchRequest<ContentFeed> {
            let request: NSFetchRequest<ContentFeed> = baseFetchRequest()

            request.predicate = ContentFeed
                .Predicates
                .matching(searchQuery: searchQuery)

            request.sortDescriptors = [ContentFeed.SortDescriptors.nameAscending]

            return request
        }
     
        
        public static func matching(feedID: String) -> NSFetchRequest<ContentFeed> {
            let request: NSFetchRequest<ContentFeed> = baseFetchRequest()
            
            request.predicate = Predicates.matching(feedID: feedID)
            request.sortDescriptors = []

            return request
        }
        
        public static func followedFeeds() -> NSFetchRequest<ContentFeed> {
            let request: NSFetchRequest<ContentFeed> = baseFetchRequest()
            
            request.predicate = Predicates.followedFeeds
            request.sortDescriptors = []

            return request
        }
        
        
        public static func podcastFeeds() -> NSFetchRequest<ContentFeed> {
            let request: NSFetchRequest<ContentFeed> = baseFetchRequest()
            
            request.predicate = Predicates.podcastFeeds
            request.sortDescriptors = []

            return request
        }
        
        public static func videoFeeds() -> NSFetchRequest<ContentFeed> {
            let request: NSFetchRequest<ContentFeed> = baseFetchRequest()
            
            request.predicate = Predicates.videoFeeds
            request.sortDescriptors = []

            return request
        }
    }
}
