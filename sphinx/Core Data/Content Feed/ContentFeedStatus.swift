//
//  ContentFeedStatus.swift
//  sphinx
//
//  Created by James Carucci on 1/10/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import ObjectMapper

class ContentFeedStatus: Mappable {
    var feedID: String = ""
    var feedURL: String = ""
    var subscriptionStatus:Bool = false
    var chatID:String?
    var itemID: String?
    var playbackDuration: Int?
    var lastPlayedTime: Int?
    var satsPerMinute: Int?
    var playerSpeed: Float?
    
    
    required convenience init(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        feedID                      <- map["feed_id"]
        feedURL                     <- map["feed_url"]
        subscriptionStatus          <- map["subscription_status"]
        chatID                      <- map["chat_id"]
        itemID                      <- map["item_id"]
        playbackDuration            <- map["playback_duration"]
        lastPlayedTime              <- map["last_played_time"]
        satsPerMinute               <- map["sats_per_minute"]
        playerSpeed                 <- map["player_speed"]
    }
}
