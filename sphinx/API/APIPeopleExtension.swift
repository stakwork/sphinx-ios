//
//  APIPeopleExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 26/05/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension API {
    
    typealias VerifyExternalCallback = ((Bool, NSDictionary?) -> ())
    typealias GetPersonInoCallback = ((Bool, JSON?) -> ())
    
    public func verifyExternal(callback: @escaping VerifyExternalCallback) {
        guard let request = getURLRequest(route: "/verify_external", method: "POST") else {
            callback(false, nil)
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        callback(true, response)
                    }
                }
            case .failure(_):
                callback(false, nil)
            }
        }
    }
    
    public func authorizeExternal(host: String,
                                  challenge: String,
                                  token: String,
                                  params: [String: AnyObject],
                                  callback: @escaping SuccessCallback) {
        
        let url = "https://\(host)/verify/\(challenge)?token=\(token)"
        
        guard let request = createRequest(url, params: params as NSDictionary, method: "POST") else {
            callback(false)
            return
        }
        
        AF.request(request).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                if let _ = data as? NSDictionary {
                    callback(true)
                }
            case .failure(let _):
                callback(false)
            }
        }
    }
    
    public func getPersonInfo(host: String,
                              pubkey: String,
                              callback: @escaping GetPersonInoCallback) {
        
        let url = "https://\(host)/person/\(pubkey)"
        
        guard let request = createRequest(url, params: nil, method: "GET") else {
            callback(false, nil)
            return
        }
        
        AF.request(request).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    callback(true, JSON(json))
                    return
                }
                callback(false, nil)
            case .failure(let _):
                callback(false, nil)
            }
        }
    }
}
