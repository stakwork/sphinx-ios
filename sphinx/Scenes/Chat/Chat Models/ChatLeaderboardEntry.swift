//
//  ChatLeaderboardEntry.swift
//  sphinx
//
//  Created by James Carucci on 2/8/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import ObjectMapper

class ChatLeaderboardEntry: Mappable {
    var alias : String?
    var earned: Int?
    var spent: Int?
    var tribeUUID:String?
    var reputation:Int?
    var spentRank:Int?
    var earnedRank:Int?

    
    required convenience init(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        alias                    <- map["alias"]
        earned                    <- map["earned"]
        spent                    <- map["spent"]
        tribeUUID                    <- map["tribeUUID"]
        reputation                    <- map["reputation"]
    }
}
