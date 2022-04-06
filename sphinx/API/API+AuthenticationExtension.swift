//
//  API+AuthenticationExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/03/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation

extension API {
    
    public func generateTokenUnauthenticated(
        token: String,
        pubkey: String,
        password: String? = nil,
        callback: @escaping SuccessCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        var route = "/contacts/tokens"
    
        if let password = password {
            route = "\(route)?pwd=\(password)"
        }
        
        let parameters: [String : AnyObject] = [
            "token" : token as AnyObject,
            "pubkey": pubkey as AnyObject
        ]
        
        guard let request = getUnauthenticatedURLRequest(
                route: route,
                params: parameters as NSDictionary?,
                method: "POST"
        ) else {
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
    
    public func generateToken(
        pubkey: String,
        password: String? = nil,
        additionalHeaders: [String: String] = [:],
        callback: @escaping SuccessCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        var route = "/contacts/tokens"
        if let password = password {
            route = "\(route)?pwd=\(password)"
        }
        
        let parameters: [String : AnyObject] = ["pubkey": pubkey as AnyObject]
        
        guard let request = getURLRequest(
                route: route,
                params: parameters as NSDictionary?,
                method: "POST",
                additionalHeaders: additionalHeaders
        ) else {
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
    
    public func getTransportKey(
        callback: @escaping TransportKeyCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        guard let request = getUnauthenticatedURLRequest(
                route: "/request_transport_key",
                params: nil,
                method: "GET"
        ) else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool,
                       let response = json["response"] as? NSDictionary, success {
                        if let transportKey = response["transport_key"] as? String {
                            callback(transportKey)
                            return
                        }
                    }
                    errorCallback()
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func addGitPAT(
        params: [String: AnyObject],
        callback: @escaping SuccessCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        guard let request = getURLRequest(
                route: "/bot/git",
                params: params as NSDictionary?,
                method: "POST"
        ) else {
            errorCallback()
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
                    errorCallback()
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func addHMACKey(
        params: [String: AnyObject],
        callback: @escaping SuccessCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        guard let request = getURLRequest(
                route: "/hmac_key",
                params: params as NSDictionary?,
                method: "POST"
        ) else {
            errorCallback()
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
                    errorCallback()
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func getHMACKey(
        callback: @escaping HMACKeyCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        guard let request = getURLRequest(
                route: "/hmac_key",
                params: nil,
                method: "GET"
        ) else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool,
                       let response = json["response"] as? NSDictionary, success {
                        if let transportKey = response["encrypted_key"] as? String {
                            callback(transportKey)
                            return
                        }
                    }
                    errorCallback()
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
}
