// PodcastFeedService.swift
//
// Created by CypherPoet.
// ✌️
//
    

import Foundation
import SwiftyJSON


public struct PodcastFeedService {
  
    public typealias FeedDataFetchCompletionHandler = (Result<[PodcastFeed], Error>) -> Void
    
    
    func fetchFeedSearchResults(
        fromQuery query: String,
        using decoder: JSONDecoder = .init(),
        then completionHandler: @escaping FeedDataFetchCompletionHandler
    ) {
//        API.sharedInstance
//            .getPodcastFeedSearchResults(
//                fromQuery: searchQuery
//            )
    }
    
    static func parsePodcastFeed(
        using json: JSON,
        with feedUrl: String?,
        existingPodcast: PodcastFeed?
    ) -> PodcastFeed? {
        guard json["episodes"].arrayValue.isEmpty == false else { return nil }
        
        let managedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        let podcastFeed = existingPodcast ?? PodcastFeed(context: managedObjectContext)
        
        podcastFeed.id = Int64(json["id"].intValue)
        podcastFeed.title = json["title"].stringValue
        podcastFeed.podcastDescription = json["description"].stringValue
        podcastFeed.author = json["author"].stringValue
        podcastFeed.imageURLPath = json["image"].stringValue
        
        podcastFeed.feedURLPath = feedUrl
        
        let episodes = json["episodes"].arrayValue.map {
            PodcastEpisode.parseEpisode(
                using: $0,
                managedObjectContext: managedObjectContext
            )
        }
        
        podcastFeed.addToEpisodes(Set(episodes))
        
        let value = JSON(json["value"])
        let model = JSON(value["model"])
        let podcastModel = PodcastModel(context: managedObjectContext)
        
        podcastModel.type = model["type"].stringValue

        let suggestedAmount = model["suggested"].doubleValue

        podcastModel.suggestedBTC = suggestedAmount
        podcastFeed.model = podcastModel

        
        let destinations: [PodcastDestination] = value["destinations"].arrayValue.map {
            let destination = PodcastDestination(context: managedObjectContext)
            
            destination.address = $0["address"].stringValue
            destination.type = $0["type"].stringValue
            destination.split = $0["split"].doubleValue
            
            return destination
        }
        
        podcastFeed.addDestinations(Set(destinations))
        
        return podcastFeed
    }
}
