//
//  API+ActionsExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/11/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON

extension API {
    
    func syncActions(
        actions: [ActionTrack],
        callback: @escaping SyncActionsCallback
    ) {
        
        var actionsJson: [[String: AnyObject]] = []
        
        for action in actions {
            var actionDictionary:[String: AnyObject] = [:]
            actionDictionary["type"] = action.type as AnyObject
            actionDictionary["meta_data"] = action.metaData as AnyObject
            
            actionsJson.append(actionDictionary)
        }
        
        guard actionsJson.count > 0 else {
            return
        }
        
        let params: [String: AnyObject] = ["data": actionsJson as AnyObject]
        
        guard let request = getURLRequest(route: "/action_history_bulk", params: params as NSDictionary?, method: "POST") else {
            callback(false)
            return
        }
        
        //NEEDS TO BE CHANGED
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let _ = data as? NSDictionary {
                    callback(true)
                } else {
                    callback(false)
                }
            case .failure(let error):
                callback(false)
            }
        }
    }
    
}
