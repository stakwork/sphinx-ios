//
//  GeneralVideoFeedXMLParser.swift
//  sphinx
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import SwiftyXMLParser
import CoreData


struct GeneralVideoFeedXMLParser {
    
    static func parseFeed(
        from xmlData: Data,
        using managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext
    ) -> Result<VideoFeed, Error> {
        
        let xml = XML.parse(xmlData)
        let feedPayload = xml.rss.channel
        
        guard
            let feedURLAccessor = feedPayload["atom:link"]
                .first(where: { $0.attributes["rel"] == "self" }),
            let feedURLPath = feedURLAccessor.attributes["href"]
        else {
            return .failure(.xmlDecodingFailed(reason: "Feed ID not found"))
        }
        
        let feed = VideoFeed(context: managedObjectContext)
        
        feed.feedURL = URL(string: feedURLPath)
        feed.feedID = feedURLPath
        feed.title = feedPayload.title.text
        feed.feedDescription = feedPayload["description"].text
        
        
        if let feedOwnerURLPath = feedPayload["link"].text {
            feed.feedOwnerURL = URL(string: feedOwnerURLPath)
        }
        
        feed.generator = feedPayload["generator"].text
        
        if let imageURL = feedPayload.image["url"].text {
            feed.imageURL = URL(string: imageURL)
        }
        
        if let lastBuildDateString = feedPayload.lastBuildDate.text {
            feed.dateUpdated = Date.getDateFromString(
                dateString: lastBuildDateString,
                format: "E, d MMM yyyy HH:mm:ss 'GMT'"
            )
        }
        
        let videoEpisodesResult = Self.parseFeedItems(
            from: feedPayload,
            using: managedObjectContext
        )
        
        switch videoEpisodesResult {
        case .success(let videos):
            feed.addToVideos(Set(videos))
            
            return .success(feed)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    
    
    static func parseFeedItems(
        from xmlData: Data,
        using managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext
    ) -> Result<[Video], Error> {
        let xml = XML.parse(xmlData)
        
        if case .failure(let error) = xml {
            return .failure(.xmlParsingFailed(error))
        }
        
        let feedPayload = xml.rss.channel
        
        return Self.parseFeedItems(
            from: feedPayload,
            using: managedObjectContext
        )
    }
    
    
    /// Parse from the XML structure described by the  [Harvard Law RSS 2.0 Spec](https://cyber.harvard.edu/rss/rss.html#hrelementsOfLtitemgt)
    static func parseFeedItems(
        from xmlAccessor: XML.Accessor,
        using managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext
    ) -> Result<[Video], Error> {
        do {
            return .success(
                try xmlAccessor.item.compactMap { videoPayload in
                    guard let guid = videoPayload["guid"].text else {
                        throw Error.xmlDecodingFailed(reason: "Video ID not found")
                    }
                    
                    let video = Video(context: managedObjectContext)

                    video.videoID = guid
                    
                    if let videoLink = videoPayload["link"].text {
                        video.itemURL = URL(string: videoLink)
                    }
                    
                    if let titleData = videoPayload["title"].element?.CDATA {
                        video.title = String(data: titleData, encoding: .utf8)
                    }
                    
                    if
                        let descriptionData = videoPayload["description"].element?.CDATA,
                        let descriptionString = String(data: descriptionData, encoding: .utf8)
                    {
                        video.videoDescription = descriptionString
                            .replacingOccurrences(
                                of: "<[^>]+>",
                                with: "",
                                options: .regularExpression,
                                range: nil
                            )
                    }

                    video.author = videoPayload["dc:creator"].text
                    video.videoShortDescription = videoPayload["media:description"].text

                    if let pubDateString = videoPayload.pubDate.text {
                        video.datePublished = Date.getDateFromString(
                            dateString: pubDateString,
                            format: "E, d MMM yyyy HH:mm:ss 'GMT'"
                        )
                    }
                    
                    if let updatedDateString = videoPayload["atom:updated"].text {
                        video.dateUpdated = Date.getDateFromString(dateString: updatedDateString)
                    }
                    
                    if
                        let thumbnailURLPath = videoPayload["media:thumbnail"]
                            .attributes["url"]
                    {
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


extension GeneralVideoFeedXMLParser {
    
    enum Error: Swift.Error {
        case xmlParsingFailed(Swift.Error)
        case xmlDecodingFailed(reason: String)
    }
}
