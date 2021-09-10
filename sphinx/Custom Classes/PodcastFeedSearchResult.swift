// PodcastFeedSearchResult.swift
//
// Created by CypherPoet.
// ✌️
//
    
import Foundation


/// Type to represent that data returned when users search for podcasts.
struct PodcastFeedSearchResult {
    var id: Int
    var title: String
    var podcastDescription: String
    var author: String
    var imageURLPath: String?
}

extension PodcastFeedSearchResult: Identifiable {}
extension PodcastFeedSearchResult: Hashable {}
extension PodcastFeedSearchResult: Decodable {}
 

// MARK: - Coding Keys
extension PodcastFeedSearchResult {
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case podcastDescription = "description"
        case author = "author"
        case imageURLPath = "artwork"
    }
}

