//
//  APILogsExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 04/02/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension API {
    func getLogs(callback: @escaping LogsCallback, errorCallback: @escaping EmptyCallback){
        guard let request = getURLRequest(route: "/logs", method: "GET") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"], success {
                        if let logs = JSON(response).string {
                            callback(logs)
                        }
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
}
