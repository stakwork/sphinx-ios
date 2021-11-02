//
//  NewsletterFeed+FetchUtils.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import CoreData


// MARK: - Predicates
extension NewsletterFeed {
    
    static func getNewsletterFeedWith(feedID: String) -> NewsletterFeed? {
        let predicate = NSPredicate(format: "feedID == %@", feedID)
        let feed:NewsletterFeed? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "NewsletterFeed")
        return feed
    }

    public enum Predicates {
        
        public static func matching(searchQuery: String) -> NSPredicate {
            let keyword = "CONTAINS[cd]"
            let formatSpecifier = "%@"

            return NSPredicate(
                format: "%K \(keyword) \(formatSpecifier)",
                #keyPath(NewsletterFeed.title),
                searchQuery
            )
        }
        
        
        public static func matching(id: NewsletterFeed.ID) -> NSPredicate {
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
extension NewsletterFeed {

    // 💡 An instance of `NSFetchedResultsController`, or an `NSFetchRequestResult` created by
    // SwiftUI's `@FetchRequest` property wrapper, requires a fetch request with sort descriptors.

    public enum SortDescriptors {

        public static let nameAscending: NSSortDescriptor = NSSortDescriptor(
            key: #keyPath(NewsletterFeed.title),
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
extension NewsletterFeed {

    public enum FetchRequests {

        public static func baseFetchRequest<NewsletterFeed>() -> NSFetchRequest<NewsletterFeed> {
            NSFetchRequest<NewsletterFeed>(entityName: "NewsletterFeed")
        }


        public static func `default`() -> NSFetchRequest<NewsletterFeed> {
            let request: NSFetchRequest<NewsletterFeed> = baseFetchRequest()

            request.sortDescriptors = [NewsletterFeed.SortDescriptors.nameAscending]
            request.predicate = nil

            return request
        }
        
        
        public static func matching(searchQuery: String) -> NSFetchRequest<NewsletterFeed> {
            let request: NSFetchRequest<NewsletterFeed> = baseFetchRequest()

            request.predicate = NewsletterFeed
                .Predicates
                .matching(searchQuery: searchQuery)

            request.sortDescriptors = [NewsletterFeed.SortDescriptors.nameAscending]

            return request
        }
     
        
        public static func matching(id: NewsletterFeed.ID) -> NSFetchRequest<NewsletterFeed> {
            let request: NSFetchRequest<NewsletterFeed> = baseFetchRequest()
            
            request.predicate = Predicates.matching(id: id)
            request.sortDescriptors = []

            return request
        }
        
        
        public static func followedFeeds() -> NSFetchRequest<NewsletterFeed> {
            let request: NSFetchRequest<NewsletterFeed> = baseFetchRequest()
            
            request.predicate = Predicates.followedFeeds
            request.sortDescriptors = []

            return request
        }
    }
}
