//
//  VoIPRequestMessage.swift
//  sphinx
//
//  Created by James Carucci on 2/27/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import ObjectMapper

class VoIPRequestMessage : Mappable{
    var recurring:Bool = false
    var cron : String?
    var link:String?
    
    required convenience init(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        link        <- map["link"]
        recurring   <- map["recurring"]
        cron        <- map["cron"]
    }
}
