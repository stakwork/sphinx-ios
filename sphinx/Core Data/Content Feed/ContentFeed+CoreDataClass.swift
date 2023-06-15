// ContentFeed+CoreDataClass.swift
//
// Created by CypherPoet.
// ✌️
//

import Foundation
import CoreData
import SwiftyJSON

@objc(ContentFeed)
public class ContentFeed: NSManagedObject {
    
    public static func createObjectFrom(
        json: JSON,
        searchResultDescription: String? = nil,
        searchResultImageUrl: String? = nil,
        context: NSManagedObjectContext? = nil
    ) -> ContentFeed? {
        
        guard let fId = json[CodingKeys.feedID.rawValue].string else {
            return nil
        }
        
        var contentFeed: ContentFeed
        
        if let managedObjectContext = context {
            contentFeed = ContentFeed(context: managedObjectContext)
        } else {
            contentFeed = ContentFeed(entity: ContentFeed.entity(), insertInto: nil)
        }
        
        let feedUrl = json[CodingKeys.feedURL.rawValue].stringValue
        let feedId = fId.fixedFeedId(feedUrl: feedUrl)
        
        contentFeed.feedURL = URL(string: feedUrl)
        contentFeed.feedID = feedId
        
        guard let items = json[CodingKeys.items.rawValue].array, items.count > 0 else {
            ContentFeed.deleteFeedWith(feedId: feedId)
            return nil
        }
        
        contentFeed.title = json[CodingKeys.title.rawValue].stringValue
        contentFeed.feedKindValue = FeedType(rawValue: json[CodingKeys.feedKindValue.rawValue].int16Value)?.rawValue ?? 0
        contentFeed.ownerURL = URL(string: json[CodingKeys.ownerURL.rawValue].stringValue)
        contentFeed.generator = json[CodingKeys.generator.rawValue].stringValue
        contentFeed.authorName = json[CodingKeys.authorName.rawValue].stringValue
        contentFeed.linkURL = URL(string: json[CodingKeys.linkURL.rawValue].stringValue)
        contentFeed.datePublished = Date(timeIntervalSince1970: json[CodingKeys.datePublished.rawValue].doubleValue)
        contentFeed.dateUpdated = Date(timeIntervalSince1970: json[CodingKeys.dateUpdated.rawValue].doubleValue)
        contentFeed.language = json[CodingKeys.language.rawValue].string
        
        //Using search result image and description
        if let imageUrlPath = json[CodingKeys.imageURL.rawValue].string, !imageUrlPath.isEmpty {
            contentFeed.imageURL = URL(string: imageUrlPath)
        } else if let searchResultImageUrl = searchResultImageUrl, !searchResultImageUrl.isEmpty {
            contentFeed.imageURL = URL(string: searchResultImageUrl)
        }
        
        if let feedDescription = json[CodingKeys.feedDescription.rawValue].string, !feedDescription.isEmpty {
            contentFeed.feedDescription = feedDescription
        } else if let searchResultDescription = searchResultDescription {
            contentFeed.feedDescription = searchResultDescription
        }
        
        if let items = json[CodingKeys.items.rawValue].array {
            for item in items {
                let i = ContentFeedItem.createObjectFrom(json: item, context: context)
                i?.contentFeed = contentFeed
            }
        }
        
        if let value = json[CodingKeys.value.rawValue].dictionary {
               
            if let model = value[CodingKeys.Value.paymentModel.rawValue]?.dictionary {
                contentFeed.paymentModel = ContentFeedPaymentModel.createObjectFrom(json: JSON(model), context: context)
            }
            
            if let destinations = value[CodingKeys.Value.paymentDestinations.rawValue]?.array {
                ContentFeedPaymentDestination.deleteDestinationForFeedWith(id: feedId)
                
                for destination in destinations {
                    let d = ContentFeedPaymentDestination.createObjectFrom(json: destination, context: context)
                    d?.feed = contentFeed
                }
            }
        }
        
        return contentFeed
    }
    
    func updateLastConsumed(){
        dateLastConsumed = Date()
        managedObjectContext?.saveContext()
    }
    
    public static func fetchChatFeedContentInBackground(
        feedUrl: String,
        chatObjectID: NSManagedObjectID,
        completion: @escaping (String?) -> ()
    ) {
        let backgroundContext = CoreDataManager.sharedManager.getBackgroundContext()
        
        backgroundContext.perform {
            let backgroundChat: Chat? = backgroundContext.object(with: chatObjectID) as? Chat
            
            fetchContentFeed(
                at: feedUrl,
                chat: backgroundChat,
                persistingIn: backgroundContext
            ) { result in
                
                if case .success(let contentFeed) = result {
                    let feedId = contentFeed.feedID
                    
                    backgroundContext.saveContext()
                    
                    DispatchQueue.main.async {
                        completion(feedId)
                    }
                    return
                }
                
                completion(nil)
            }
        }
    }
    
    public static func fetchContentFeed(
        at feedURLPath: String,
        chat: Chat?,
        searchResultDescription: String? = nil,
        searchResultImageUrl: String? = nil,
        persistingIn managedObjectContext: NSManagedObjectContext,
        then completionHandler: ((Result<ContentFeed, Error>) -> Void)? = nil
    ) {
        let tribesServerURL = "\(API.kTribesServerBaseURL)/feed?url=\(feedURLPath)&fulltext=true"
        
        API.sharedInstance.getContentFeed(
            url: tribesServerURL,
            callback: { feedJSON in
                
                if let contentFeed = ContentFeed.createObjectFrom(
                    json: feedJSON,
                    searchResultDescription: searchResultDescription,
                    searchResultImageUrl: searchResultImageUrl,
                    context: managedObjectContext
                ) {
                    chat?.contentFeed = contentFeed
                    
                    completionHandler?(.success(contentFeed))
                } else {
                    completionHandler?(.failure((API.RequestError.failedToFetchContentFeed)))
                }
            },
            errorCallback: {
                completionHandler?(.failure((API.RequestError.failedToFetchContentFeed)))
            }
        )
    }
    
    public static func fetchFeedItems(
        feedUrl: String,
        contentFeedObjectID: NSManagedObjectID,
        context: NSManagedObjectContext,
        completion: @escaping (Result<ContentFeed, Error>) -> ()
    ) {
        let backgroundContentFeed: ContentFeed? = context.object(with: contentFeedObjectID) as? ContentFeed
        
        fetchContentFeedItems(
            at: feedUrl,
            contentFeed: backgroundContentFeed,
            persistingIn: context
        ) { result in
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    public static func fetchContentFeedItems(
        at feedURLPath: String,
        contentFeed: ContentFeed?,
        persistingIn managedObjectContext: NSManagedObjectContext,
        then completionHandler: ((Result<ContentFeed, Error>) -> Void)? = nil
    ) {
        let tribesServerURL = "\(API.kTribesServerBaseURL)/feed?url=\(feedURLPath)&fulltext=true"
        
        API.sharedInstance.getContentFeed(
            url: tribesServerURL,
            callback: { feedJSON in
                if let contentFeed = contentFeed {
                    if let items = feedJSON[ContentFeed.CodingKeys.items.rawValue].array {
                        for item in items {
                            let i = ContentFeedItem.createObjectFrom(json: item, context: managedObjectContext)
                            i?.contentFeed = contentFeed
                        }
                    }
                    completionHandler?(.success(contentFeed))
                } else {
                    completionHandler?(.failure((API.RequestError.failedToFetchContentFeed)))
                }
            },
            errorCallback: {
                completionHandler?(.failure((API.RequestError.failedToFetchContentFeed)))
            }
        )
    }
    
    var sortedItemsArray: [ContentFeedItem] = []
    
    public static func convertFrom(
        podcastFeed: PodcastFeed
    ) -> ContentFeed? {
        
        let contentFeed = ContentFeed(entity: ContentFeed.entity(), insertInto: podcastFeed.chat?.managedObjectContext)
        
        if let feedURL = URL(string: podcastFeed.feedURLPath ?? ""){
            contentFeed.feedURL = feedURL
        }
        contentFeed.feedID = podcastFeed.feedID
        contentFeed.title = podcastFeed.title
        contentFeed.feedDescription = podcastFeed.podcastDescription
        contentFeed.datePublished = podcastFeed.datePublished
        contentFeed.dateUpdated = podcastFeed.dateUpdated
        contentFeed.authorName = podcastFeed.author
        contentFeed.imageURL = URL(string: podcastFeed.imageURLPath ?? "")
        contentFeed.generator = podcastFeed.generator
        contentFeed.chat = podcastFeed.chat
        contentFeed.dateLastConsumed = podcastFeed.dateLastConsumed
        
//        contentFeed.items = Set(arrayLiteral: podcastFeed.episodes?.compactMap { episode in
//            ContentFeedItem.convertFrom(podcastEpisode: episode)
//        })
        
//        contentFeed.paymentDestinations = Set(podcastFeed.destinations.compactMap { destination in
//            ContentFeedPaymentDestination.convertFrom(podcastDestination: destination, contentFeed: contentFeed)
//        })
//        
//        if let model = podcastFeed.model {
//            contentFeed.paymentModel = ContentFeedPaymentModel.convertFrom(podcastModel: model, contentFeed: contentFeed)
//        }
        
        return contentFeed
    }

    
    public static func convertFrom(
        videoFeed: VideoFeed
    ) -> ContentFeed? {
        
        let contentFeed = ContentFeed(entity: ContentFeed.entity(), insertInto: nil)
        
        contentFeed.title = videoFeed.title
        contentFeed.feedID = videoFeed.feedID
        contentFeed.generator = videoFeed.generator
        contentFeed.chat = videoFeed.chat
        contentFeed.datePublished = videoFeed.datePublished
        contentFeed.dateUpdated = videoFeed.dateUpdated
        contentFeed.ownerURL = videoFeed.feedOwnerURL
        contentFeed.feedDescription = videoFeed.feedDescription
        contentFeed.authorName = videoFeed.author
        contentFeed.imageURL = videoFeed.imageURL
        contentFeed.dateLastConsumed = videoFeed.dateLastConsumed
        contentFeed.items = Set(videoFeed.videos?.compactMap({
            ContentFeedItem.convertFrom(video: $0, videoFeed: videoFeed)
        }) ?? [])
        
        return contentFeed
    }
}

extension String {
    func fixedFeedId(feedUrl: String) -> String {
        if feedUrl.isYouTubeRSSFeed {
            if let range = feedUrl.range(of: "?playlist_id=") {
                return "yt:playlist:\(feedUrl[range.upperBound...])"
            }
            if let range = feedUrl.range(of: "?channel_id=") {
                return "yt:channel:\(feedUrl[range.upperBound...])"
            }
        }
        return self
    }
}
