//
//  DiscoverTribeData.swift
//  sphinx
//
//  Created by James Carucci on 1/4/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import ObjectMapper

class DiscoverTribeData: Mappable {
    var imgURL: String?
    var description: String?
    var name: String?
    var uuid : String?
    var host : String?
    var pubkey:String?
    
    required convenience init(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        imgURL            <- map["img"]
        name              <- map["name"]
        description       <- map["description"]
        uuid              <- map["uuid"]
        host              <- map["host"]
        pubkey            <- map["pubkey"]
    }
}
