//
//  NewsletterFeed+CoreDataProperties.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import CoreData

public class NewsletterFeed: NSObject {
    
    public var objectID: NSManagedObjectID
    public var feedID: String
    public var title: String?
    public var feedDescription: String?
    public var newsletterURL: URL?
    public var feedURL: URL?
    public var imageURL: URL?
    public var generator: String?
    public var dateUpdated: Date?
    public var datePublished: Date?
    public var chat: Chat?
    internal var newsletterItems: Array<NewsletterItem>?
    
    init(_ objectID: NSManagedObjectID, _ feedID: String) {
        self.objectID = objectID
        self.feedID = feedID
    }

}

extension NewsletterFeed: Identifiable {
    public var id: String { feedID }
}

extension NewsletterFeed {

    public class func fetchRequest() -> NSFetchRequest<ContentFeed> {
        return NSFetchRequest<ContentFeed>(entityName: "ContentFeed")
    }
}


// MARK: -  Public Methods
extension NewsletterFeed {
    
    public static func convertFrom(
        contentFeed: ContentFeed
    ) -> NewsletterFeed {
        
        let newsletterFeed = NewsletterFeed(
            contentFeed.objectID,
            contentFeed.feedID
        )
        
        newsletterFeed.title = contentFeed.title
        newsletterFeed.feedDescription = contentFeed.feedDescription
        newsletterFeed.datePublished = contentFeed.datePublished
        newsletterFeed.dateUpdated = contentFeed.dateUpdated
        newsletterFeed.feedURL = contentFeed.feedURL
        newsletterFeed.imageURL = contentFeed.imageURL
        newsletterFeed.generator = contentFeed.generator
        newsletterFeed.chat = contentFeed.chat
        
        newsletterFeed.newsletterItems = contentFeed
                .items?
                .map {
                    NewsletterItem.convertFrom(
                        contentFeedItem: $0,
                        newsletterFeed: newsletterFeed
                    )
                }
            ?? []
        
        
        return newsletterFeed
    }
}
