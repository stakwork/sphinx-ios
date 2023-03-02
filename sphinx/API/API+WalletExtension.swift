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
import ObjectMapper

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
    
    func getAssetsByID(
        assetIDs:[Int],
        callback: @escaping GetBadgeCallback,
        errorCallback: @escaping EmptyCallback
    ){
        if(assetIDs.isEmpty){
            callback([])
            return
        }
        let params = [
            "ids":assetIDs
        ]
        
        let baseURL = "https://liquid.sphinx.chat"
        let url = baseURL + "/asset/filter"
        guard let request = createRequest(url, bodyParams: params as NSDictionary, method: "POST") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let results = data as? NSArray {
                    print(results)
                    if let mappedResults = Mapper<Badge>().mapArray(JSONObject: Array(results)){
                        callback(mappedResults)
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func getBadgeAssets(
        user_uuid:String,
        callback: @escaping GetBadgeCallback,
        errorCallback: @escaping EmptyCallback
    ){
        let urlPath = API.kTribesServerBaseURL + "/person/uuid/\(user_uuid)/assets"
        
        let urlComponents = URLComponents(string: urlPath)!
        
        guard let urlString = urlComponents.url?.absoluteString else {
            errorCallback()
            return
        }
        
        guard let request = createRequest(
            urlString,
            bodyParams: nil,
            method: "GET"
        ) else {
            errorCallback()
            return
        }
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? [NSDictionary],
                   let mappedValues = Mapper<Badge>().mapArray(JSONObject: json){
                    print(json)
                    callback(mappedValues)
                    //callback(json)
                    return
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }

}
