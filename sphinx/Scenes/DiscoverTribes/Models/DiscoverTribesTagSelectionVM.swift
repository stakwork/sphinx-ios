//
//  DiscoverTribesTagSelectionVM.swift
//  sphinx
//
//  Created by James Carucci on 1/16/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class DiscoverTribesTagSelectionVM{
    var vc: DiscoverTribesTagSelectionVC
    let possibleTags : [String] = [
        "Bitcoin",
        "NSFW",
        "Lightning",
        "Podcast",
        "Crypto",
        "Music",
        "Tech",
        "Altcoins"
    ]
    var selectedTags : [String] = []
    
    init(vc:DiscoverTribesTagSelectionVC) {
        self.vc = vc
    }
}
