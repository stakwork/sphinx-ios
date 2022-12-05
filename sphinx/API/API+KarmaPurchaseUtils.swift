//
//  API+KarmaPurchaseUtils.swift
//  sphinx
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import Alamofire


extension API {
    
    public func validateKarmaPurchase(
        withAppStoreReceipt receiptString: String,
        forNodePubKey ownerPublicKey: String,
        andRouteHint routeHint: String,
        then completionHandler: @escaping KarmaPurchaseValidationCallback
    ) {
        let urlPath = "\(API.kHUBServerUrl)/api/v1/nodes/validate_purchase_sats"
        
        let parameters: [String: AnyObject] = [
            "receipt": receiptString as AnyObject,
            "destination_key": ownerPublicKey as AnyObject,
            "route_hint": routeHint as AnyObject,
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
                        .failure(.karmaReceiptValidationFailure(message: errorMessage))
                    )
                    
                    return
                }
                
                completionHandler(.success(()))
            case .failure(let error):
                completionHandler(.failure(.networkError(error)))
                return
            }
        }
    }
}

