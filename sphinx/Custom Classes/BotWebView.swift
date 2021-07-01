//
//  BotWebView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import WebKit

class BotWebView : WKWebView {
    var contentString: String? = ""
    
    override func loadHTMLString(_ string: String, baseURL: URL?) -> WKNavigation? {
        self.contentString = string
        return super.loadHTMLString(string, baseURL: baseURL)
    }
}
