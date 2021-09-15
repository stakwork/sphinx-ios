// PodcastEpisode+Computeds.swift
//
// Created by CypherPoet.
// ✌️
//
    

import Foundation
import SwiftyJSON
import CoreData


extension PodcastEpisode {
    
    /// Converts the HTML-formatted ``episodeDescription`` string to a standard Swift String
    var formattedDescription: String {
        episodeDescription?.attributedStringFromHTML?.string ?? ""
    }
}


extension PodcastEpisode {

    convenience init(
        jsonPayload json: JSON,
        managedObjectContext: NSManagedObjectContext
    ) {
        self.init(context: managedObjectContext)

        id = Int64(json["id"].intValue)
        title = json["title"].stringValue
        datePublished = Date(timeIntervalSince1970: json["datePublished"].doubleValue)
        episodeDescription = json["description"].stringValue
        urlPath = json["enclosureUrl"].stringValue
        imageURLPath = json["image"].stringValue
        linkURLPath = json["link"].stringValue
    }
}


// MARK: - Coding Keys
extension PodcastEpisode {
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case datePublished = "datePublished"
        case episodeDescription = "description"
        case urlPath = "enclosureUrl"
        case imageURLPath = "image"
        case linkURLPath = "link"
    }
}




