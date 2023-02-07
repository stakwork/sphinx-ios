//
//  BadgeTemplate.swift
//  sphinx
//
//  Created by James Carucci on 2/7/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import ObjectMapper

public var BadgeRewardsMap : [Int:String] = [
    1 : "Earn",
    2 : "Spend"
]
    


class BadgeTemplate: Mappable {
    var icon_url: String?
    var name: String?
    var rewardType : Int?
    var rewardRequirement: Int?
    
    required convenience init(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        icon_url              <- map["icon"]
        name              <- map["name"]
        rewardType <- map["rewardType"]
        rewardRequirement <- map["rewardRequirement"]
    }
    
    func getHumanizedRewardType() -> String?{
        if let valid_type = rewardType,
           let value = BadgeRewardsMap[valid_type]{
            return value
        }
        return nil
    }

}
