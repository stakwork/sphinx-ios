//
//  APITransactionsExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 30/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension API {
    public func getTransactionsList(page: Int, itemsPerPage: Int, callback: @escaping GetTransactionsCallback, errorCallback: @escaping EmptyCallback) {
        let offset = (page - 1) * itemsPerPage
        let limit = itemsPerPage
        
        guard let request = getURLRequest(route: "/payments?offset=\(offset)&limit=\(limit)&include_failures=true", method: "GET") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"], success {
                        self.processAndReturnTransactions(jsonArray: JSON(response).arrayValue, callback: callback)
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func processAndReturnTransactions(jsonArray: [JSON], callback: @escaping GetTransactionsCallback) {
        var transactionsArray = [PaymentTransaction]()
        
        for json in jsonArray {
            let paymentT = PaymentTransaction(json: json)
            transactionsArray.append(paymentT)
        }
        
        callback(transactionsArray)
    }
}
