// VideoFeed+FetchUtils.swift
//
// Created by CypherPoet.
// ✌️
//
    

import Foundation
import CoreData


// MARK: - Predicates
extension VideoFeed {

    public enum Predicates {
        
        public static func matching(searchQuery: String) -> NSPredicate {
            let keyword = "CONTAINS[cd]"
            let formatSpecifier = "%@"
            let typeFormatSpecifier = "%d"

            return NSPredicate(
                format: "%K \(keyword) \(formatSpecifier) AND feedKindValue == \(typeFormatSpecifier) AND (isSubscribedToFromSearch == true OR chat != nil)",
                "title",
                searchQuery,
                FeedType.Video.rawValue
            )
        }
        
        public static let videoFeeds: NSPredicate = {
            NSPredicate(
                format: "feedKindValue == %d",
                FeedType.Video.rawValue
            )
        }()
        
        public static let followedVideoFeeds: NSPredicate = {
            NSPredicate(
                format: "(isSubscribedToFromSearch == true OR chat != nil) AND feedKindValue == %d",
                FeedType.Video.rawValue
            )
        }()
    }
}


// MARK: - FetchRequests
extension VideoFeed {

    public enum FetchRequests {

        public static func baseFetchRequest<ContentFeed>() -> NSFetchRequest<ContentFeed> {
            let request = NSFetchRequest<ContentFeed>(entityName: "ContentFeed")
            request.predicate = VideoFeed.Predicates.videoFeeds
            return request
        }
        
        public static func matching(searchQuery: String) -> NSFetchRequest<ContentFeed> {
            let request: NSFetchRequest<ContentFeed> = baseFetchRequest()

            request.predicate = VideoFeed
                .Predicates
                .matching(searchQuery: searchQuery)

            request.sortDescriptors = [PodcastFeed.SortDescriptors.nameAscending]

            return request
        }
        
        
        public static func followedFeeds() -> NSFetchRequest<ContentFeed> {
            let request: NSFetchRequest<ContentFeed> = baseFetchRequest()
            
            request.predicate = Predicates.followedVideoFeeds
            request.sortDescriptors = []

            return request
        }
    }
}
