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
    var feedID: String?
    var subscriptionStatus:Bool?
    var lastItemInfo:ContentFeedLastItem?
    var feedURL: String?
    var chatID:String?
    
    
    required convenience init(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        feedID            <- map["feed_id"]
        subscriptionStatus            <- map["subscription_status"]
        lastItemInfo            <- map["last_item_info"]
        feedURL            <- map["feed_url"]
        chatID            <- map["chat_id"]
    }
}
