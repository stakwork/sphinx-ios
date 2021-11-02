// VideoFeed+FetchUtils.swift
//
// Created by CypherPoet.
// ✌️
//
    

import Foundation
import CoreData


// MARK: - Predicates
extension VideoFeed {
    
    static func getVideoFeedWith(feedID: String) -> VideoFeed? {
        let predicate = NSPredicate(format: "feedID == %@", feedID)
        let feed:VideoFeed? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "VideoFeed")
        return feed
    }

    public enum Predicates {
        
        public static func matching(searchQuery: String) -> NSPredicate {
            let keyword = "CONTAINS[cd]"
            let formatSpecifier = "%@"

            return NSPredicate(
                format: "%K \(keyword) \(formatSpecifier)",
                #keyPath(VideoFeed.title),
                searchQuery
            )
        }
        
        
        public static func matching(id: VideoFeed.ID) -> NSPredicate {
            let keyword = "=="
            let formatSpecifier = "%i"

            return NSPredicate(
                format: "%K \(keyword) \(formatSpecifier)",
                "id",
                id
            )
        }
        
        
        public static let followedFeeds: NSPredicate = {
            NSPredicate(
                format: "chat != nil"
            )
        }()
    }
}


// MARK: - SortDescriptors
extension VideoFeed {

    // 💡 An instance of `NSFetchedResultsController`, or an `NSFetchRequestResult` created by
    // SwiftUI's `@FetchRequest` property wrapper, requires a fetch request with sort descriptors.

    public enum SortDescriptors {

        public static let nameAscending: NSSortDescriptor = NSSortDescriptor(
            key: #keyPath(VideoFeed.title),
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
extension VideoFeed {

    public enum FetchRequests {

        public static func baseFetchRequest<VideoFeed>() -> NSFetchRequest<VideoFeed> {
            NSFetchRequest<VideoFeed>(entityName: "VideoFeed")
        }


        public static func `default`() -> NSFetchRequest<VideoFeed> {
            let request: NSFetchRequest<VideoFeed> = baseFetchRequest()

            request.sortDescriptors = [VideoFeed.SortDescriptors.nameAscending]
            request.predicate = nil

            return request
        }
        
        
        public static func matching(searchQuery: String) -> NSFetchRequest<VideoFeed> {
            let request: NSFetchRequest<VideoFeed> = baseFetchRequest()

            request.predicate = VideoFeed
                .Predicates
                .matching(searchQuery: searchQuery)

            request.sortDescriptors = [VideoFeed.SortDescriptors.nameAscending]

            return request
        }
     
        
        public static func matching(id: VideoFeed.ID) -> NSFetchRequest<VideoFeed> {
            let request: NSFetchRequest<VideoFeed> = baseFetchRequest()
            
            request.predicate = Predicates.matching(id: id)
            request.sortDescriptors = []

            return request
        }
        
        
        public static func followedFeeds() -> NSFetchRequest<VideoFeed> {
            let request: NSFetchRequest<VideoFeed> = baseFetchRequest()
            
            request.predicate = Predicates.followedFeeds
            request.sortDescriptors = []

            return request
        }
    }
}
