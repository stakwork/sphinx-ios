//
//  NewsletterFeedXMLParser.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import SwiftyXMLParser
import CoreData


struct NewsletterFeedXMLParser {
    
    static func parseNewsletterFeed(
        from xmlData: Data,
        using managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext
    ) -> Result<NewsletterFeed, Error> {
        
        let xml = XML.parse(xmlData)
        let feedPayload = xml.rss.channel
        
        guard
            let feedURLAccessor = feedPayload["atom:link"]
                .first(where: { $0.attributes["rel"] == "self" }),
            let feedURLPath = feedURLAccessor.attributes["href"] else
        {
            return .failure(.xmlDecodingFailed(reason: "Feed ID not found"))
        }
        
        let existingFeed = NewsletterFeed.getNewsletterFeedWith(feedID: feedURLPath)
        let feed = existingFeed ?? NewsletterFeed(context: managedObjectContext)
        
        feed.feedURL = URL(string: feedURLPath)
        feed.feedID = feedURLPath
        
        if let cdata = feedPayload["title"].element?.CDATA {
           feed.title = String(data: cdata, encoding: .utf8)
        }
        
        if let cdata = feedPayload["description"].element?.CDATA {
           feed.feedDescription = String(data: cdata, encoding: .utf8)
        }
        
        if let feedLink = feedPayload["link"].text {
            feed.newsletterURL = URL(string: feedLink)
        }
        
        feed.generator = feedPayload["generator"].text
        
        if let imageURL = feedPayload.image["url"].text {
            feed.imageURL = URL(string: imageURL)
        }
        
        if let lastBuildDateString = feedPayload.lastBuildDate.text,
           let date = Date.getDateFromString(dateString: lastBuildDateString, format: "E, d MMM yyyy HH:mm:ss 'GMT'") {
            feed.dateUpdated = date
        }

        let newsletterItemsResult = Self.parseNewsletterFeedItems(
            from: feedPayload,
            using: managedObjectContext
        )

        switch newsletterItemsResult {
        case .success(let items):
            feed.addToNewsletterItems(Set(items))
            return .success(feed)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    
    
    static func parseNewsletterFeedItems(
        from xmlData: Data,
        using managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext
    ) -> Result<[NewsletterItem], Error> {
        let xml = XML.parse(xmlData)
        
        if case .failure(let error) = xml {
            return .failure(.xmlParsingFailed(error))
        }
        
        let feedPayload = xml.rss.channel
        
        return Self.parseNewsletterFeedItems(
            from: feedPayload,
            using: managedObjectContext
        )
    }
    
    
    static func parseNewsletterFeedItems(
        from xmlAccessor: XML.Accessor,
        using managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext
    ) -> Result<[NewsletterItem], Error> {
        do {
            return .success(
                try xmlAccessor.item.compactMap { itemPayload in
                    guard let link = itemPayload["link"].text else {
                        throw Error.xmlDecodingFailed(reason: "Item ID not found")
                    }
                    
                    let existingItem = NewsletterItem.getNewsletterItemWith(itemID: link)
                    
                    let item = existingItem ?? NewsletterItem(context: managedObjectContext)
                    
                    item.itemID = link
                    item.itemUrl = URL(string: link)
                    
                    if let cdata = itemPayload["title"].element?.CDATA,
                       let string = String(data: cdata, encoding: .utf8) {
                       item.title = string
                    }
                    
                    if let cdata = itemPayload["description"].element?.CDATA,
                       let string = String(data: cdata, encoding: .utf8) {
                       item.itemDescription = string.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                    }
                    
                    if let cdata = itemPayload["dc:creator"].element?.CDATA,
                       let string = String(data: cdata, encoding: .utf8) {
                       item.creator = string
                    }
                    
                    if let pubDateString = itemPayload.pubDate.text,
                       let pubDate = Date.getDateFromString(dateString: pubDateString, format: "E, d MMM yyyy HH:mm:ss 'GMT'") {
                        item.datePublished = pubDate
                    }
                    
                    if let updatedDateString = itemPayload["atom:updated"].text,
                       let updatedDate = Date.getDateFromString(dateString: updatedDateString) {
                        item.dateUpdated = updatedDate
                    }
                                        
                    return item
                }
            )
        } catch let parserError as Error {
            return .failure(parserError)
        } catch {
            return .failure(.xmlParsingFailed(error))
        }
    }
}


extension NewsletterFeedXMLParser {
    
    enum Error: Swift.Error {
        case xmlParsingFailed(Swift.Error)
        case xmlDecodingFailed(reason: String)
    }
}
