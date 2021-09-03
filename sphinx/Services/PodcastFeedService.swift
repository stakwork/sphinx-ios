// PodcastFeedService.swift
//
// Created by CypherPoet.
// ✌️
//
    

import Foundation


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
}
