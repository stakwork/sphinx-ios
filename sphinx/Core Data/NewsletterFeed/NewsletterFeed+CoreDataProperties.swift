//
//  NewsletterFeed+CoreDataProperties.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import CoreData


extension NewsletterFeed {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NewsletterFeed> {
        return NSFetchRequest<NewsletterFeed>(entityName: "NewsletterFeed")
    }

    @NSManaged public var feedID: String
    @NSManaged public var title: String?
    @NSManaged public var feedDescription: String?
    @NSManaged public var newsletterURL: URL?
    @NSManaged public var feedURL: URL?
    @NSManaged public var imageURL: URL?
    @NSManaged public var generator: String?
    @NSManaged public var dateUpdated: Date?
    @NSManaged public var chat: Chat?
    @NSManaged public var newsletterItems: Set<NewsletterItem>?

}

// MARK: Generated accessors for NewsletterItems
extension NewsletterFeed {

    @objc(addNewsletterItemsObject:)
    @NSManaged public func addToNewsletterItems(_ value: NewsletterItem)

    @objc(removeNewsletterItemsObject:)
    @NSManaged public func removeFromNewsletterItems(_ value: NewsletterItem)

    @objc(addNewsletterItems:)
    @NSManaged public func addToNewsletterItems(_ values: Set<NewsletterItem>)

    @objc(removeNewsletterItems:)
    @NSManaged public func removeFromNewsletterItems(_ values: Set<NewsletterItem>)

}
