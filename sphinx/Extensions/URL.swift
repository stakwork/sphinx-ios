//
//  URL.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
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
    
    var pathWithParams: String {
        let path = self.path
        if let query = self.query {
            return "\(path)?\(query)"
        }
        return path
    }
}

extension String {
    func getLinkAction() -> String? {
        let components = self.components(separatedBy: "&")
        
        for component in components {
            if component.contains("action") {
                let elements = component.components(separatedBy: "=")
                if elements.count > 1 {
                    let key = elements[0]
                    return component.replacingOccurrences(of: "\(key)=", with: "")
                }
            }
        }
        return nil
    }
}
