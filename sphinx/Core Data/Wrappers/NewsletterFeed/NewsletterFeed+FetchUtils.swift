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

    public enum Predicates {
        
        public static let newsletterFeeds: NSPredicate = {
            NSPredicate(
                format: "feedKindValue == %d",
                FeedType.Newsletter.rawValue
            )
        }()
        
        
        public static let followedFeeds: NSPredicate = {
            NSPredicate(
                format: "chat != nil AND feedKindValue == %d",
                FeedType.Newsletter.rawValue
            )
        }()
    }
}


// MARK: - SortDescriptors
extension NewsletterFeed {

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
extension NewsletterFeed {

    public enum FetchRequests {

        public static func baseFetchRequest<ContentFeed>() -> NSFetchRequest<ContentFeed> {
            let request = NSFetchRequest<ContentFeed>(entityName: "ContentFeed")
            request.predicate = NewsletterFeed.Predicates.newsletterFeeds
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
