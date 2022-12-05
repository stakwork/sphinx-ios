//
//  GroupsManager+Bot.swift
//  sphinx
//
//  Created by Tomas Timinskas on 25/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON

extension GroupsManager {
    struct Bot {
        var prefix: String = ""
        var price: Int = 0
        var commands: [BotCommand] = []
        
        init(json: JSON) {
            self.prefix = json["prefix"].string ?? ""
            self.price = json["price"].int ?? 0
            
            var commandObjects: [BotCommand] = []
            
            for cmd in json["commands"].array ?? [] {
                let commandObject = BotCommand(json: cmd)
                commandObjects.append(commandObject)
            }
            
            self.commands = commandObjects
        }
    }

    struct BotCommand {
        var command: String? = nil
        var price: Int? = nil
        var minPrice: Int? = nil
        var maxPrice: Int? = nil
        var priceIndex: Int? = nil
        var adminOnly: Bool? = nil
        
        init(json: JSON) {
            self.command = json["command"].string
            self.price = json["price"].int
            self.minPrice = json["min_price"].int
            self.maxPrice = json["max_price"].int
            self.priceIndex = json["price_index"].int
            self.adminOnly = json["admin_only"].bool
        }
    }
}
