// YouTubeXMLParser.swift
//
// Created by CypherPoet.
// ✌️
//
    
import Foundation
import SwiftyXMLParser
import CoreData


struct YouTubeXMLParser {
    
    static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        return formatter
    }()
    
    
    static func parseVideoFeed(
        from xmlData: Data,
        using managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext
    ) -> Result<VideoFeed, Error> {
        let xml = XML.parse(xmlData)
        let feedPayload = xml.feed
        
        if case .failure(let error) = xml {
            return .failure(.xmlParsingFailed(error))
        }
        
        guard let feedID = feedPayload["yt:channelId"].text else {
            return .failure(.xmlDecodingFailed(reason: "Channel ID not found"))
        }
        
        let feed = VideoFeed(context: managedObjectContext)

        feed.feedID = feedID
        
        if
            let linkElements = feedPayload.link.all,
            linkElements.count > 1,
            let feedURLPath = feedPayload.link[1].attributes["href"]
        {
            feed.feedURL = URL(string: feedURLPath)
        }
        
        feed.author = feedPayload.author.name
        feed.title = feedPayload.title.text
        
        if let datePublished = feedPayload.published.text {
            feed.datePublished = Self.dateFormatter.date(from: datePublished)
        }
        
        return .success(feed)
    }
}


extension YouTubeXMLParser {
    
    enum Error: Swift.Error {
        case xmlParsingFailed(Swift.Error)
        case xmlDecodingFailed(reason: String)
    }
}
