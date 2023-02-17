//
//  TribeMemberProfile.swift
//  sphinx
//
//  Created by Tomas Timinskas on 14/11/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON

struct TribeMemberStruct {
    
    let id: Int
    let description: String
    let img: String
    let ownerAlias: String
    let ownerContactKey: String
    let ownerRouteHint: String
    let priceToMeet: Int
    let uniqueName: String
    let uuid: String
    let extras: TribeMemberProfileExtrasDto?
    let badges: [JSON]
    
    init(json: JSON) {
        self.id = json["id"].intValue
        self.description = json["description"].stringValue
        self.img = json["img"].stringValue
        self.ownerAlias = json["owner_alias"].stringValue
        self.ownerContactKey = json["owner_contact_key"].stringValue
        self.ownerRouteHint = json["owner_route_hint"].stringValue
        self.priceToMeet = json["price_to_meet"].intValue
        self.uniqueName = json["unique_name"].stringValue
        self.uuid = json["uuid"].stringValue
        self.badges = json["badges"].arrayValue
        
        if let extras = json["extras"].dictionary, let extrasJson = JSON(rawValue: extras) {
            self.extras = TribeMemberProfileExtrasDto(json: extrasJson)
        } else {
            self.extras = TribeMemberProfileExtrasDto(json: JSON())
        }
    }
}

struct TribeMemberProfileExtrasDto {
    var codingLanguages: [String] = []
    var github: [String] = []
    var twitter: [String] = []
    var posts: [String] = []
    var tribes: [String] = []
    
    var codingLanguagesString: String {
        if codingLanguages.count > 0 {
            return codingLanguages.joined(separator: ",")
        }
        return "-"
    }
    
    var twitterString: String {
        if twitter.count > 0 {
            return twitter.first?.tribeMemberProfileValue ?? "-"
        }
        return "-"
    }
    
    var githubString: String {
        if github.count > 0 {
            return github.first?.tribeMemberProfileValue ?? "-"
        }
        return "-"
    }
    
    var postsString: String {
        return String(posts.count)
    }
    
    init(json: JSON) {
        if let languages = json["coding_languages"].array {
            for l in languages {
                if let l = l["value"].string {
                    codingLanguages.append(l)
                }
            }
        }
        
        if let gh = json["github"].array {
            for g in gh {
                if let g = g["value"].string {
                    github.append(g)
                }
            }
        }
        
        if let tw = json["twitter"].array {
            for t in tw {
                if let t = t["value"].string {
                    twitter.append(t)
                }
            }
        }
        
        if let tr = json["tribes"].array {
            for t in tr {
                if let t = t["value"].string {
                    tribes.append(t)
                }
            }
        }
        
        if let pt = json["post"].array {
            for p in pt {
                if let p = p["title"].string {
                    posts.append(p)
                }
            }
        }
    }
}
