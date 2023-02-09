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
    typealias SignVerifyCallback = ((String?) -> ())
    typealias GetPersonInfoCallback = ((Bool, JSON?) -> ())
    typealias GetExternalRequestByKeyCallback = ((Bool, JSON?) -> ())
    typealias PeopleTorRequestCallback = ((Bool) -> ())
    typealias GetPersonProfileCallback = ((Bool, JSON?) -> ())
    typealias GetTribeMemberProfileCallback = ((Bool, TribeMemberStruct?) -> ())
    
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
    
    public func signBase64(b64: String, callback: @escaping SignVerifyCallback) {
        guard let request = getURLRequest(route: "/signer/\(b64)", method: "GET") else {
            callback(nil)
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        if let sig = response["sig"] as? String {
                            callback(sig)
                            return
                        }
                    }
                }
                callback(nil)
            case .failure(_):
                callback(nil)
            }
        }
    }
    
    public func authorizeExternal(host: String,
                                  challenge: String,
                                  token: String,
                                  params: [String: AnyObject],
                                  callback: @escaping SuccessCallback) {
        
        let url = "https://\(host)/verify/\(challenge)?token=\(token)"
        
        guard let request = createRequest(url, bodyParams: params as NSDictionary, method: "POST") else {
            callback(false)
            return
        }
        
        AF.request(request).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                if let _ = data as? NSDictionary {
                    callback(true)
                }
            case .failure(_):
                callback(false)
            }
        }
    }
    
    public func getPersonInfo(host: String,
                              pubkey: String,
                              callback: @escaping GetPersonInfoCallback) {
        
        let url = "https://\(host)/person/\(pubkey)"
        
        guard let request = createRequest(url, bodyParams: nil, method: "GET") else {
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
            case .failure(_):
                callback(false, nil)
            }
        }
    }
    
    public func getExternalRequestByKey(host: String,
                                        key: String,
                                        callback: @escaping GetExternalRequestByKeyCallback) {
        
        let url = "https://\(host)/save/\(key)"
        
        guard let request = createRequest(url, bodyParams: nil, method: "GET") else {
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
            case .failure(_):
                callback(false, nil)
            }
        }
    }
    
    public func savePeopleProfile(params: [String: AnyObject],
                                  callback: @escaping PeopleTorRequestCallback) {
        
        guard let request = getURLRequest(route: "/profile", params: params as NSDictionary, method: "POST") else {
            callback(false)
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool,
                       let _ = json["response"] as? NSDictionary, success {
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
    
    public func deletePeopleProfile(params: [String: AnyObject],
                                    callback: @escaping PeopleTorRequestCallback) {
        
        guard let request = getURLRequest(route: "/profile", params: params as NSDictionary, method: "DELETE") else {
            callback(false)
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool,
                       let _ = json["response"] as? NSDictionary, success {
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
    
    public func redeemBadgeTokens(params: [String: AnyObject],
                                  callback: @escaping PeopleTorRequestCallback) {
        
        guard let request = getURLRequest(route: "/claim_on_liquid", params: params as NSDictionary, method: "POST") else {
            callback(false)
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool,
                       let _ = json["response"] as? NSDictionary, success {
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
    
    public func getTribeMemberInfo(
        person: String,
        callback: @escaping GetTribeMemberProfileCallback
    ) {
        
        guard let host = person.personHost, let uuid = person.personUUID else {
            callback(false, nil)
            return
        }
        
        //let test = "cd9dm5ua5fdtsj2c2mtg"
        let url = "https://\(host)/person/uuid/\(uuid)"
        
        guard let request = createRequest(url, bodyParams: nil, method: "GET") else {
            callback(false, nil)
            return
        }
        
        AF.request(request).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    let tribeMember = TribeMemberStruct(json: JSON(json))
                    callback(true, tribeMember)
                    return
                }
                callback(false, nil)
            case .failure(_):
                callback(false, nil)
            }
        }
    }
}
