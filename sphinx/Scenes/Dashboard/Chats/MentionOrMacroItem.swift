//
//  MentionOrMacroItem.swift
//  sphinx
//
//  Created by James Carucci on 6/27/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

public enum MentionOrMacroType{
    case mention
    case macro
}

class MentionOrMacroItem: NSObject{
    
    var type: MentionOrMacroType
    var displayText: String =  ""
    var action: (()->())?
    var image: UIImage? = nil
    var imageContentMode: UIView.ContentMode? = nil
    var icon: String? = nil
    var imageLink: String? = nil
    
    init(
        type: MentionOrMacroType,
        displayText: String,
        image: UIImage? = nil,
        imageContentMode: UIView.ContentMode? = nil,
        imageLink: String? = nil,
        icon: String? = nil,
        action: (() -> ())?
    ) {
        self.type = type
        self.displayText = displayText
        self.action = action
        self.image = image
        self.imageContentMode = imageContentMode
        self.icon = icon
        self.imageLink = imageLink
    }
    
}
