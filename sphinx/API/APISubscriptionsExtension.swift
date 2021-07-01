//
//  APISubscriptionsExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension API {
    public func getSubscriptionsFor(contact: UserContact?, callback: @escaping GetSubscriptionsCallback, errorCallback: @escaping EmptyCallback) {
        guard let contactId = contact?.id else {
            errorCallback()
            return
        }
        
        guard let request = getURLRequest(route: "/subscriptions/contact/\(contactId)", method: "GET") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"], success {
                        callback(JSON(response).arrayValue)
                    } else {
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func createSubscription(parameters: [String : AnyObject], callback: @escaping CreateSubscriptionCallback, errorCallback: @escaping EmptyCallback) {
        guard let request = getURLRequest(route: "/subscriptions", params: parameters as NSDictionary?, method: "POST") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        callback(JSON(response))
                    } else {
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func editSubscription(id: Int, parameters: [String : AnyObject], callback: @escaping CreateSubscriptionCallback, errorCallback: @escaping EmptyCallback) {
        guard let request = getURLRequest(route: "/subscription/\(id)", params: parameters as NSDictionary?, method: "PUT") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        callback(JSON(response))
                    } else {
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func deleteSubscription(id: Int, callback: @escaping SuccessCallback) {
        guard let request = getURLRequest(route: "/subscription/\(id)", method: "DELETE") else {
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
    
    public func pauseSubscription(id: Int, callback: @escaping CreateSubscriptionCallback, errorCallback: @escaping EmptyCallback) {
        toggleSubscriptionState(route: "pause", id: id, callback: callback, errorCallback: errorCallback)
    }
    
    public func restartSubscription(id: Int, callback: @escaping CreateSubscriptionCallback, errorCallback: @escaping EmptyCallback) {
        toggleSubscriptionState(route: "restart", id: id, callback: callback, errorCallback: errorCallback)
    }
    
    public func toggleSubscriptionState(route: String, id: Int, callback: @escaping CreateSubscriptionCallback, errorCallback: @escaping EmptyCallback) {
        guard let request = getURLRequest(route: "/subscription/\(id)/\(route)", method: "PUT") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        callback(JSON(response))
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
