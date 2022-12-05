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
}


// MARK: - HUB calls
extension API {
    
    public func signupWithCode(
        inviteString: String,
        callback: @escaping SignupWithCodeCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        let url = "\(API.kHUBServerUrl)/api/v1/signup"
        
        let parameters: [String : AnyObject] = ["invite_string" : inviteString as AnyObject]
        
        guard let request = createRequest(url, bodyParams: parameters as NSDictionary?, method: "POST") else {
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
        
        guard let request = createRequest(url, bodyParams: nil, method: "GET") else {
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
    
    
    public func generateLiteNodeHUBInvoice(
        then completionHandler: @escaping NodePurchaseInvoiceCallback
    ) {
        let urlPath = "\(API.kHUBServerUrl)/api/v1/nodes/purchase"
        
        guard let request = createRequest(
            urlPath,
            bodyParams: nil,
            method: "POST"
        ) else {
            completionHandler(.failure(.failedToCreateRequest(urlPath: urlPath)))
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                guard let json = data as? Dictionary<String, Any> else {
                    completionHandler(.failure(.unexpectedResponseData))
                    return
                }
                
                guard
                    let success = json["success", default: false] as? Bool,
                    success == true
                else {
                    guard
                        let error = json["error"] as? Dictionary<String, Any>,
                        let errorMessage = error["message"] as? String
                    else {
                        completionHandler(.failure(.unexpectedResponseData))
                        return
                    }
                    
                    completionHandler(
                        .failure(.nodeInvoiceGenerationFailure(message: errorMessage))
                    )
                    
                    return
                }
                
                guard
                    let response = json["response"] as? Dictionary<String, Any>,
                    let invoice = response["invoice"] as? String
                else {
                    completionHandler(.failure(.unexpectedResponseData))
                    return
                }
                
                completionHandler(.success(invoice))
            case .failure(let error):
                completionHandler(.failure(.networkError(error)))
                return
            }
        }
    }
    
    
    public func validateLiteNodePurchase(
        withAppStoreReceipt receiptString: String,
        and hubNodeInvoice: HUBNodeInvoice,
        then completionHandler: @escaping NodePurchaseValidationCallback
    ) {
        let urlPath = "\(API.kHUBServerUrl)/api/v1/nodes/validate_purchase"

        let parameters: [String: AnyObject] = [
            "receipt": receiptString as AnyObject,
            "invoice": hubNodeInvoice as AnyObject
        ]
        
        guard let request = createRequest(
            urlPath,
            bodyParams: parameters as NSDictionary?,
            method: "POST"
        ) else {
            completionHandler(.failure(.failedToCreateRequest(urlPath: urlPath)))
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                guard let json = data as? Dictionary<String, Any> else {
                    completionHandler(.failure(.unexpectedResponseData))
                    return
                }
                
                guard
                    let json = data as? Dictionary<String, Any>,
                    let success = json["success", default: false] as? Bool,
                    success == true
                else {
                    guard
                        let error = json["error"] as? Dictionary<String, Any>,
                        let errorMessage = error["message"] as? String
                    else {
                        completionHandler(.failure(.unexpectedResponseData))
                        return
                    }
                    
                    completionHandler(
                        .failure(.nodeInvoiceGenerationFailure(message: errorMessage))
                    )
                    
                    return
                }
                
                guard
                    let response = json["response"] as? Dictionary<String, Any>,
                    let inviteCode = response["invite_code"] as? String
                else {
                    completionHandler(.failure(.unexpectedResponseData))
                    return
                }
                
                completionHandler(.success(inviteCode))
            case .failure(let error):
                completionHandler(.failure(.networkError(error)))
                return
            }
        }
    }
}
