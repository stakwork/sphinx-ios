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

    static func parseEpisode(
        using json: JSON,
        managedObjectContext: NSManagedObjectContext
    ) -> PodcastEpisode {
        let id = Int64(json["id"].intValue)
        let existingEpisode = getPodcastEpisodeWith(id: id)
        
        let episode = existingEpisode ?? PodcastEpisode(context: managedObjectContext)
        
        episode.itemID = "\(id)"
        episode.title = json["title"].stringValue
        episode.datePublished = Date(timeIntervalSince1970: json["datePublished"].doubleValue)
        episode.episodeDescription = json["description"].stringValue
        episode.urlPath = json["enclosureUrl"].stringValue
        episode.imageURLPath = json["image"].stringValue
        episode.linkURLPath = json["link"].stringValue
        
        return episode
    }
}




