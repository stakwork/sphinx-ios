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
    var icon_url: String?
    var name: String?
    var amount_available: Int?
    var amount_issued: Int?
    var chat_id: Int?
    var claim_amount: Int?
    var reward_type: Int?
    var requirements: String?

    
    required convenience init(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        icon_url              <- map["icon_url"]
        name              <- map["name"]
        amount_available              <- map["amount_available"]
        amount_issued              <- map["amount_issued"]
        chat_id              <- map["chat_id"]
        claim_amount              <- map["claim_amount"]
        reward_type              <- map["reward_type"]
        requirements            <- map["requirements"]
    }
}
