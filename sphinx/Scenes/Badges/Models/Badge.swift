//
//  Badge.swift
//  sphinx
//
//  Created by James Carucci on 12/28/22.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import ObjectMapper

class Badge: Mappable {
    var badge_id: Int?
    var icon_url: String?
    var name: String?
    var amount_created: Int?
    var amount_issued: Int?
    var chat_id: Int?
    var claim_amount: Int?
    var reward_type: Int?
    var reward_requirement: Int?
    var memo: String?
    //var asset: String?
    var activationState : Bool = false

    
    required convenience init(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        icon_url                    <- map["icon"]
        name                        <- map["name"]
        amount_created             <- map["amount_created"]
        amount_issued              <- map["amount_issued"]
        //New Fields?
        memo                        <- map["memo"]
        //asset              <- map["asset"]
        chat_id                     <- map["chat_id"]
        claim_amount                <- map["claim_amount"]
        reward_type                 <- map["reward_type"]
        reward_requirement          <- map["reward_requirement"]
        activationState             <- map["active"]
        badge_id                    <- map["badge_id"]
    }
}
