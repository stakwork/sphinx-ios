//
//  ContentFeedStatus.swift
//  sphinx
//
//  Created by James Carucci on 1/10/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import ObjectMapper

class EpisodeStatus: Mappable {
    var episodeID : String = ""
    var episodeData: EpisodeData?
    
    required convenience init(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        episodeData                  <- map[episodeID]
    }
}

class EpisodeData: Mappable {
    var duration:Int = 0
    var current_time:Int = 0
    
    required convenience init(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        duration                      <- map["duration"]
        current_time                  <- map["current_time"]
    }
}


class ContentFeedStatus: Mappable {
    var feedID: String = ""
    var feedURL: String = ""
    var subscriptionStatus:Bool = false
    var chatID:Int?
    var itemID: String?
    var satsPerMinute: Int?
    var playerSpeed: Float?
    var episodeStatus: [EpisodeStatus] = []
    
    
    required convenience init(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        feedID                      <- map["feed_id"]
        feedURL                     <- map["feed_url"]
        subscriptionStatus          <- map["subscription_status"]
        chatID                      <- map["chat_id"]
        itemID                      <- map["item_id"]
        satsPerMinute               <- map["sats_per_minute"]
        playerSpeed                 <- map["player_speed"]
        
        if map.mappingType == .fromJSON,//typical path for deserializing
           let episode_statuses = map.JSON["episodes_status"] as? [[String:Any]] {
            
            var local_statuses = [EpisodeStatus]()
            
            for episode_status in episode_statuses {
                
                let localCopy = EpisodeStatus()
                let key = episode_status.keys.first ?? ""
                localCopy.episodeID = key
                
                let episodeData = EpisodeData()
                
                if let jsonEStatus = episode_status["\(key)"] as? [String:Any],
                   let current_time = jsonEStatus["current_time"] as? Int,
                   let duration = jsonEStatus["duration"] as? Int {
                    
                    episodeData.current_time = current_time
                    episodeData.duration = duration
                }
                
                localCopy.episodeData = episodeData
                local_statuses.append(localCopy)
            }
            
            episodeStatus = local_statuses
        }
        else{//typical path for serializing
            episodeStatus               <- map["episodes_status"]
        }
        
    }
}
