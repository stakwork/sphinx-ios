//
//  ContentTagTimestamp.swift
//  sphinx
//
//  Created by James Carucci on 9/21/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import ObjectMapper

class ContentTagTimestamp: Mappable {
    var tag: String = ""
    var start: Double = 0.0
    var end: Double = 0.0

    required init?(map: Map) {
    }

    func mapping(map: Map) {
        tag <- map["tag"]
        start <- map["start"]
        end <- map["end"]
    }
}
