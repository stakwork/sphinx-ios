//
//  NSObject.swift
//  sphinx
//
//  Created by Tomas Timinskas on 23/09/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation

extension NSObject {
    
    static func jsonToData(json: [String: AnyObject]) -> Data? {
        var data: Data? = nil
        do {
            data = try JSONSerialization.data(withJSONObject: json, options: [])
        } catch let error as NSError {
            print("NSJSONSerialization Error: \(error)")
        }
        return data
    }

    func toJson() -> AnyObject? {
        var json: AnyObject? = nil
        if let data = self as? Data {
            do {
                json = try JSONSerialization.jsonObject(with: data, options: []) as AnyObject
            } catch let error as NSError {
                print("NSJSONSerialization Error: \(error)")
            }
        }
        return json
    }
}
