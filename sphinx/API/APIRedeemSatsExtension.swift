//
//  APIRedeemSatsExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import Alamofire

extension API {
    func redeemSats(url: String, params: [String: AnyObject], callback: @escaping EmptyCallback, errorCallback: @escaping EmptyCallback){
        guard let request = createRequest(url, bodyParams: params as NSDictionary, method: "POST") else {
            errorCallback()
            return
        }
        
        AF.request(request).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success {
                        callback()
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
