//
//  API+Errors.swift
//  sphinx
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import Alamofire


extension API {
    enum HUBError: Swift.Error {
        case failedToCreateRequest(urlPath: String)
        case unexpectedResponseData
        case networkError(AFError)
        case nodeInvoiceGenerationFailure(message: String)
        case karmaReceiptValidationFailure(message: String)
    }
}



extension API.HUBError: LocalizedError {
    
    var errorDescription: String? {
        switch self {
        case .failedToCreateRequest:
            return "URL Request Creation Failed"
        case .unexpectedResponseData:
            return "Unexpected API Response"
        case .networkError(let error):
            return "Network Error: \(error.localizedDescription)"
        case .nodeInvoiceGenerationFailure(message: let message):
            return "Node Invoice Generation Failed. Error Message: \(message)"
        case .karmaReceiptValidationFailure(message: let message):
            return "Karma Receipt Validation Failed. Error Message: \(message)"
        }
    }
}
