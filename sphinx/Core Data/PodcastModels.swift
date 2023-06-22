//
//  PodcastModels.swift
//  sphinx
//
//  Created by Tomas Timinskas on 03/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreData


struct PodcastComment {
    var feedId:String? = nil
    var itemId:String? = nil
    var timestamp:Int? = nil
    var title: String? = nil
    var text: String? = nil
    var url: String? = nil
    var pubkey: String? = nil
    var uuid: String? = nil
    
    func getJsonString(withComment comment: String) -> String? {
        let pubkey = UserData.sharedInstance.getUserPubKey()
        var json: [String: AnyObject] = [:]
        if let feedId = feedId {
            json["feedID"] = feedId as AnyObject
        }
        if let itemId = itemId {
            json["itemID"] = itemId as AnyObject
        }
        if let timestamp = timestamp {
            json["ts"] = timestamp as AnyObject
        }
        if let title = title {
            json["title"] = "\(title)" as AnyObject
        }
        if let url = url {
            json["url"] = "\(url)" as AnyObject
        }
        if let pubkey = pubkey {
            json["pubkey"] = "\(pubkey)" as AnyObject
        }
        json["text"] = "\(comment)" as AnyObject
                
        if #available(iOS 13.0, *) {
            if let strJson = JSON(json).rawString(.utf8, options: .withoutEscapingSlashes) {
                return "\(PodcastFeed.kClipPrefix)\(strJson)"
            }
        } else {
            if let strJson = JSON(json).rawString() {
                return "\(PodcastFeed.kClipPrefix)\(strJson)"
            }
        }
        return nil
    }
    
    func isValid() -> Bool {
        return timestamp != nil && title != nil && url != nil
    }
}
