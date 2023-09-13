//
//  API+AuthenticationExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/03/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import Alamofire

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
//                        print("generateTokenUnauthenticated success json:\(json)")
//                        print("generateTokenUnauthenticated success status:\(String(describing: response.response?.statusCode))")
                    } else {
                        errorCallback()
//                        print("generateTokenUnauthenticated failure json:\(json)")
//                        print("generateTokenUnauthenticated failure status:\(String(describing: response.response?.statusCode))")
                    }
                }
            case .failure(let error):
                errorCallback()
//                print("generateTokenUnauthenticated request failure:\(error)")
//                print("generateTokenUnauthenticated failure status:\(String(describing: response.response?.statusCode))")
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
//        print("generateToken request:\(request)")
//        print("generateToken params:\(parameters)")
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success {
                        callback(success)
//                        print("generateToken success json:\(json)")
//                        print("generateToken success status:\(String(describing: response.response?.statusCode))")
                    } else {
                        errorCallback()
//                        print("generateToken failure json:\(json)")
//                        print("generateToken failure request:\(String(describing: response.request))")
//                        print("generateToken failure response: \(String(describing: response.response))")
//                        print("generateToken failure status:\(String(describing: response.response?.statusCode))")
                    }
                }
            case .failure(let error):
                errorCallback()
//                print("generateTokenAuthenticated request failure:\(error)")
//                print("generateTokenAuthenticated failure status:\(String(describing: response.response?.statusCode))")
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
    
    public func getHasAdmin(
        completionHandler: @escaping GetHasAdminCompletionHandler
    ){
        guard let request = getURLRequest(
                route: "/has_admin",
                params: nil,
                method: "GET"
        ) else {
            completionHandler(.failure(.failedToCreateRequestURL))
            return
        }
        
       AF.request(request).responseJSON { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["response"] as? Bool, success {
                        completionHandler(.success(true))
                        print("getHasAdmin success:\(success) & Status Code:\(String(describing: response.response?.statusCode))")
                    } else {
                        completionHandler(.success(false))
                        print("getHasAdmin Status Code:\(String(describing: response.response?.statusCode))")
                    }
                }
            case .failure(let error):
                completionHandler(.failure(.networkError(error)))
                print("getHasAdmin Error: \(error) & Status Code:\(String(describing: response.response?.statusCode))")
            }
        }
    }
    
}
