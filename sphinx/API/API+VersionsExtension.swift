//
//  APIVersionsExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 08/01/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension API {
    func getAppVersions(callback: @escaping AppVersionsCallback) {
        guard let request = getURLRequest(route: "/app_versions", method: "GET") else {
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        if let version = response["ios"] as? String {
                            callback(version)
                            return
                        }
                    }
                }
            case .failure(_):
                print("Error getting app version")
            }
        }
    }
}
