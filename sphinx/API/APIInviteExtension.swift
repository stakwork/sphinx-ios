//
//  APIInviteExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension API {
    public func createUserInvite(parameters: [String : AnyObject], callback: @escaping CreateInviteCallback, errorCallback: @escaping EmptyCallback) {
        guard let request = getURLRequest(route: "/invites", params: parameters as NSDictionary?, method: "POST") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let contact = json["contact"] as? NSDictionary, success {
                        callback(JSON(contact))
                    } else {
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func finishInvite(inviteString: String, callback: @escaping SuccessCallback) {
        let parameters: [String : AnyObject] = ["invite_string" : inviteString as AnyObject]
        
        guard let request = getURLRequest(route: "/invites/finish", params: parameters as NSDictionary?, method: "POST") else {
            callback(false)
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success {
                        callback(true)
                    } else {
                        callback(false)
                    }
                }
            case .failure(_):
                callback(false)
            }
        }
    }
    
    public func generateToken(token: String, pubkey: String, password: String? = nil, callback: @escaping SuccessCallback, errorCallback: @escaping EmptyCallback) {
        var route = "/contacts/tokens"
        if let password = password {
            route = "\(route)?pwd=\(password)"
        }
        
        let parameters: [String : AnyObject] = ["token" : token as AnyObject, "pubkey": pubkey as AnyObject]
        
        guard let request = getURLRequest(route: route, params: parameters as NSDictionary?, method: "POST", authenticated: false) else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success {
                        callback(success)
                    } else {
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func payInvite(inviteString: String, callback: @escaping PayInviteCallback, errorCallback: @escaping EmptyCallback) {
        guard let request = getURLRequest(route: "/invites/\(inviteString)/pay", method: "POST") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        if let invite = response["invite"] as? NSDictionary {
                            callback(JSON(invite))
                        } else {
                            errorCallback()
                        }
                    } else {
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    //HUB calls
    public func signupWithCode(inviteString: String, callback: @escaping SignupWithCodeCallback, errorCallback: @escaping EmptyCallback) {
        let url = "\(API.kHUBServerUrl)/api/v1/signup"
        
        let parameters: [String : AnyObject] = ["invite_string" : inviteString as AnyObject]
        
        guard let request = createRequest(url, params: parameters as NSDictionary?, method: "POST") else {
            errorCallback()
            return
        }
        
        AF.request(request).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let status = json["status"] as? String, status == "ok" {
                        if let object = json["object"] as? NSDictionary {
                            if let ip = object["ip"] as? String, let invite = object["invite"] as? NSDictionary {
                                let pubkey = object["pubkey"] as? String ?? ""
                                let inviteObject = JSON(invite)
                                callback(inviteObject, ip, pubkey)
                                return
                            }
                        }
                        errorCallback()
                    } else {
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func getLowestPrice(callback: @escaping LowestPriceCallback, errorCallback: @escaping EmptyCallback) {
        let url = "\(API.kHUBServerUrl)/api/v1/nodes/pricing"
        
        guard let request = createRequest(url, params: nil, method: "GET") else {
            errorCallback()
            return
        }
        
        AF.request(request).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let status = json["status"] as? String, status == "ok" {
                        if let object = json["object"] as? NSDictionary {
                            if let price = object["price"] as? Double {
                                callback(price)
                                return
                            }
                        }
                        errorCallback()
                    } else {
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
}
