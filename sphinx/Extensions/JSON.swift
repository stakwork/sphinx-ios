//
//  JSON.swift
//  sphinx
//
//  Created by Tomas Timinskas on 17/03/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Foundation
import SwiftyJSON

extension JSON {
    func getJSONId() -> Int? {
        var id : Int?
        if let idInt = self["id"].int {
            id = idInt
        } else if let idString = self["id"].string, let idInt = Int(idString) {
            id = idInt
        }
        return id
    }
}
