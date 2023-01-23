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
        //episodeID                      <- map["episode_id"]
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
    var chatID:String?
    var itemID: String?
    var satsPerMinute: Int?
    var playerSpeed: Float?
    var episodeStatus: [EpisodeStatus]?
    
    
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
        episodeStatus               <- map["episode_status"]
    }
}
