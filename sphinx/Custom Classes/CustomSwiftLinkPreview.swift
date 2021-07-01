//
//  CustomSwiftLinkPreview.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import SwiftLinkPreview

class CustomSwiftLinkPreview {
    
    class var sharedInstance : SwiftLinkPreview {
        struct Static {
            static let instance = SwiftLinkPreview(cache: InMemoryCache())
        }
        return Static.instance
    }
    
}
