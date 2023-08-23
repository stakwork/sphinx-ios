//
//  NewsletterItem+CoreDataProperties.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import CoreData

class NewsletterItem: NSObject {
    
    public var itemID: String
    public var title: String?
    public var itemDescription: String?
    public var itemUrl: URL?
    public var imageUrl: URL?
    public var creator: String?
    public var datePublished: Date?
    public var dateUpdated: Date?
    public var newsletterFeed: NewsletterFeed?
    
    init(
        _ itemID: String
    ) {
        self.itemID = itemID
    }
    
    func constructShareLink()->String?{
        var link : String? = nil
        if let feedID = self.newsletterFeed?.feedID,
           let feedURL = self.newsletterFeed?.feedURL{
            link = "sphinx.chat://?action=share_content&feedURL=\(feedURL)&feedID=\(feedID)&itemID=\(itemID)"
        }
        
        return link
    }
}

extension NewsletterItem: Identifiable {
    public var id: String { itemID }
}


extension NewsletterItem {

    public class func fetchRequest() -> NSFetchRequest<ContentFeedItem> {
        return NSFetchRequest<ContentFeedItem>(entityName: "ContentFeedItem")
    }
}


// MARK: -  Public Methods
extension NewsletterItem {
    
    public static func convertFrom(
        contentFeedItem: ContentFeedItem,
        newsletterFeed: NewsletterFeed? = nil
    ) -> NewsletterItem {
        
        let newsletterItem = NewsletterItem(
            contentFeedItem.itemID
        )
        
        newsletterItem.itemID = contentFeedItem.itemID
        newsletterItem.creator = contentFeedItem.authorName
        newsletterItem.datePublished = contentFeedItem.datePublished
        newsletterItem.dateUpdated = contentFeedItem.dateUpdated
        newsletterItem.itemDescription = contentFeedItem.itemDescription
        newsletterItem.itemUrl = contentFeedItem.enclosureURL
        newsletterItem.imageUrl = contentFeedItem.imageURL
        newsletterItem.title = contentFeedItem.title
        newsletterItem.newsletterFeed = newsletterFeed
        
        return newsletterItem
    }
}
