// PodcastFeed+FetchUtils.swift
//
// Created by CypherPoet.
// ✌️
//
    

import Foundation
import CoreData


// MARK: - Predicates
extension PodcastFeed {

    public enum Predicates {
        
        public static func matching(searchQuery: String) -> NSPredicate {
            let keyword = "CONTAINS[cd]"
            let formatSpecifier = "%@"
            let typeFormatSpecifier = "%d"

            return NSPredicate(
                format: "%K \(keyword) \(formatSpecifier) AND feedKindValue == \(typeFormatSpecifier) AND (isSubscribedToFromSearch == true OR chat != nil)",
                "title",
                searchQuery,
                FeedType.Podcast.rawValue
            )
        }
        
        
        public static func matching(feedID: String) -> NSPredicate {
            let keyword = "=="
            let formatSpecifier = "%@"

            return NSPredicate(
                format: "%K \(keyword) \(formatSpecifier)",
                "feedID",
                feedID
            )
        }
        
        
        public static let followedFeeds: NSPredicate = {
            NSPredicate(
                format: "(isSubscribedToFromSearch == true OR chat != nil) AND feedKindValue == %d",
                FeedType.Podcast.rawValue
            )
        }()
    }
}


// MARK: - SortDescriptors
extension PodcastFeed {

    // 💡 An instance of `NSFetchedResultsController`, or an `NSFetchRequestResult` created by
    // SwiftUI's `@FetchRequest` property wrapper, requires a fetch request with sort descriptors.

    public enum SortDescriptors {

        public static let nameAscending: NSSortDescriptor = NSSortDescriptor(
            key: "title",
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
extension PodcastFeed {

    public enum FetchRequests {

        public static func baseFetchRequest<ContentFeed>() -> NSFetchRequest<ContentFeed> {
            NSFetchRequest<ContentFeed>(entityName: "ContentFeed")
        }
        
        
        public static func matching(searchQuery: String) -> NSFetchRequest<ContentFeed> {
            let request: NSFetchRequest<ContentFeed> = baseFetchRequest()

            request.predicate = PodcastFeed
                .Predicates
                .matching(searchQuery: searchQuery)

            request.sortDescriptors = [PodcastFeed.SortDescriptors.nameAscending]

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
    }
}
