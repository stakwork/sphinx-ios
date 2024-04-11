//
//  GroupsManager+TribesInfo.swift
//  sphinx
//
//  Created by Tomas Timinskas on 25/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation

extension GroupsManager {
    
    struct TribeInfo: Equatable {
        var name : String? = nil
        var description : String? = nil
        var img : String? = nil
        var groupKey : String? = nil
        var ownerPubkey : String? = nil
        var ownerAlias : String? = nil
        var pin : String? = nil
        var host : String! = nil
        var uuid : String! = nil
        var tags : [Tag] = []
        var priceToJoin : Int? = nil
        var pricePerMessage : Int? = nil
        var amountToStake : Int? = nil
        var timeToStake : Int? = nil
        var unlisted : Bool = false
        var privateTribe : Bool = false
        var deleted : Bool = false
        var appUrl : String? = nil
        var secondBrainUrl : String? = nil
        var feedUrl : String? = nil
        var feedContentType : FeedContentType? = nil
        var ownerRouteHint : String? = nil
        var bots : [Bot] = []
        var badgeIds: [Int] = []
        
        static func == (lhs: TribeInfo, rhs: TribeInfo) -> Bool {
            return lhs.name           == rhs.name &&
                   lhs.description    == rhs.description &&
                   lhs.uuid           == rhs.uuid &&
                   lhs.host           == rhs.host &&
                   lhs.groupKey       == rhs.groupKey
        }
        
        var hasLoopoutBot : Bool {
            get {
                for bot in bots {
                    if bot.prefix == "/loopout" {
                        return true
                    }
                }
                return false
            }
        }
        
        var isValid: Bool {
            get {
                return name != nil && description != nil && groupKey != nil
            }
        }
    }
}
