//
//  URL.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/03/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import Foundation

extension URL {
    
    func getLinkAction() -> String? {
        return self.query?.getLinkAction()
    }
    
    var domain: String? {
        get {
            if let hostName = self.host  {
                let host = hostName.replacingOccurrences(of: "http://", with: "")
                                   .replacingOccurrences(of: "https://", with: "")
                                   .replacingOccurrences(of: "www.", with: "")
                
                let components = host.components(separatedBy: ".")
                if components.count > 0 {
                    return String(components[0])
                }
            }
            return self.host
        }
    }
}

extension String {
    func getLinkAction() -> String? {
        let components = self.components(separatedBy: "&")
        
        for component in components {
            if component.contains("action") {
                let elements = component.components(separatedBy: "=")
                if elements.count > 1 {
                    return elements[1]
                }
            }
        }
        return nil
    }
}
