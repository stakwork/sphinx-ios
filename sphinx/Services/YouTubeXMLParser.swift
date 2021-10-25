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
            let feedURLAccessor = feedPayload
                .link
                .first(where: { $0.attributes["rel"] == "self" }),
            let feedURLPath = feedURLAccessor.attributes["href"]
        {
            feed.feedURL = URL(string: feedURLPath)
        }
        
        feed.author = feedPayload.author["name"].text
        feed.title = feedPayload.title.text
        
        if let datePublished = feedPayload.published.text {
            feed.datePublished = Self.dateFormatter.date(from: datePublished)
        }
        
        let videoEntriesResult = Self.parseVideoFeedEntries(
            from: feedPayload,
            using: managedObjectContext
        )
        
        switch videoEntriesResult {
        case .success(let videos):
            feed.addToVideos(Set(videos))
            
            return .success(feed)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    
    
    static func parseVideoFeedEntries(
        from xmlData: Data,
        using managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext
    ) -> Result<[Video], Error> {
        let xml = XML.parse(xmlData)
        
        if case .failure(let error) = xml {
            return .failure(.xmlParsingFailed(error))
        }
        
        let feedPayload = xml.feed
        
        return Self.parseVideoFeedEntries(
            from: feedPayload,
            using: managedObjectContext
        )
    }
    
    
    static func parseVideoFeedEntries(
        from xmlAccessor: XML.Accessor,
        using managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext
    ) -> Result<[Video], Error> {
        do {
            return .success(
                try xmlAccessor.entry.compactMap { videoPayload in
                    let video = Video(context: managedObjectContext)
                    
                    guard let videoID = videoPayload["yt:videoId"].text else {
                        throw Error.xmlDecodingFailed(reason: "Video ID not found")
                    }
                    
                    video.videoID = videoID
                    
                    video.title = videoPayload.title.text
                    video.author = videoPayload.author["name"].text
                    video.videoDescription = videoPayload["media:group", "media:description"].text
                    
                    if let datePublished = videoPayload.published.text {
                        video.datePublished = Self.dateFormatter.date(from: datePublished)
                    }
                    
                    if let thumbnailURLPath = videoPayload["media:group", "media:thumbnail"].attributes["url"] {
                        video.thumbnailURL = URL(string: thumbnailURLPath)
                    }
                    
                    return video
                }
            )
        } catch let parserError as Error {
            return .failure(parserError)
        } catch {
            return .failure(.xmlParsingFailed(error))
        }
    }
}


extension YouTubeXMLParser {
    
    enum Error: Swift.Error {
        case xmlParsingFailed(Swift.Error)
        case xmlDecodingFailed(reason: String)
    }
}
