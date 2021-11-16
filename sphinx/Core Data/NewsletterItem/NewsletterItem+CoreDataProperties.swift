//
//  NewsletterItem+CoreDataProperties.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import CoreData


extension NewsletterItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NewsletterItem> {
        return NSFetchRequest<NewsletterItem>(entityName: "NewsletterItem")
    }

    @NSManaged public var itemID: String
    @NSManaged public var title: String?
    @NSManaged public var itemDescription: String?
    @NSManaged public var itemUrl: URL?
    @NSManaged public var creator: String?
    @NSManaged public var datePublished: Date?
    @NSManaged public var dateUpdated: Date?
    @NSManaged public var newsletterFeed: NewsletterFeed?
}


// MARK: -  Public Methods
extension NewsletterItem {
    
    public static func convertedFrom(
        contentFeedItem: ContentFeedItem
    ) -> Self {
        guard let managedObjectContext = contentFeedItem.managedObjectContext else {
            preconditionFailure()
        }

        let newsletterItem = Self(context: managedObjectContext)
        
        newsletterItem.itemID = contentFeedItem.itemID
        newsletterItem.creator = contentFeedItem.authorName
        newsletterItem.datePublished = contentFeedItem.datePublished
        newsletterItem.dateUpdated = contentFeedItem.dateUpdated
        newsletterItem.itemDescription = contentFeedItem.itemDescription
        newsletterItem.itemUrl = contentFeedItem.enclosureURL
        newsletterItem.title = contentFeedItem.title
        
        return newsletterItem
    }
}
