//
//  ContentFeedLastItem.swift
//  sphinx
//
//  Created by James Carucci on 1/10/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import ObjectMapper


class ContentFeedLastItem: Mappable {
    var contentID: String?
    var contentType: FeedType?
    var playbackDuration: Int?
    var lastPlayedTime: Int?
    
    
    required convenience init(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        contentID            <- map["content_id"]
        contentType            <- map["content_type"]
        playbackDuration            <- map["playback_duration"]
        lastPlayedTime            <- map["last_played_time"]
    }
}
