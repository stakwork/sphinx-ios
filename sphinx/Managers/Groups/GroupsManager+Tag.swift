//
//  GroupsManager+Tag.swift
//  sphinx
//
//  Created by Tomas Timinskas on 25/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation

extension GroupsManager {
    struct Tag {
        var image : String
        var description : String
        var selected : Bool = false
        
        init(image: String, description: String, selected: Bool = false) {
            self.image = image
            self.description = description
            self.selected = selected
        }
    }
}
