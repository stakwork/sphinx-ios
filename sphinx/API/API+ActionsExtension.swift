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
        
        var actionsJson: [[String: Any]] = []
        
        for action in actions {
            let params = action.getParamsDictionary()
            actionsJson.append(params)
        }
        
        guard actionsJson.count > 0 else {
            return
        }
        
        let params: [String: AnyObject] = ["data": actionsJson as AnyObject]
        
        guard let request = getURLRequest(route: "/action_history_bulk", params: params as NSDictionary?, method: "POST") else {
            callback(false)
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success {
                        callback(true)
                        return
                    }
                }
                callback(false)
            case .failure(_):
                callback(false)
            }
        }
    }
    
}
