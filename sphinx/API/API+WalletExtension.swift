//
//  APIWalletExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension API {
    func getWalletBalance(
        callback: @escaping BalanceCallback,
        errorCallback: @escaping EmptyCallback
    ){
        guard let request = getURLRequest(
                route: "/balance",
                method: "GET"
        ) else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"], success {
                        let data = JSON(response).dictionaryValue
                        if let balance = data["balance"]?.intValue {
                            callback(balance)
                            return
                        }
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func getWalletLocalAndRemote(callback: @escaping BalancesCallback, errorCallback: @escaping EmptyCallback){
        guard let request = getURLRequest(route: "/balance/all", method: "GET") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"], success {
                        let data = JSON(response).dictionaryValue
                        if let localBalance = data["local_balance"]?.intValue, let remoteBalance = data["remote_balance"]?.intValue {
                            callback(localBalance, remoteBalance)
                            return
                        }
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func generateOnchainAddress(callback: @escaping OnchainAddressCallback, errorCallback: @escaping EmptyCallback){
        guard let request = getURLRequest(route: "/query/onchain_address/cash", method: "GET") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let address = json["response"] as? String, success && !address.isEmpty {
                        callback(address)
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
