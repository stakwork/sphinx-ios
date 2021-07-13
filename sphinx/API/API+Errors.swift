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
            return "error.url.request.creation.failed".localized
        case .unexpectedResponseData:
            return "error.unexpected.api.response".localized
        case .networkError(let error):
            return "\("error.network".localized) \(error.localizedDescription)"
        case .nodeInvoiceGenerationFailure(message: let message):
            return "\("error.node.invoice.generation.failed".localized) \(message)"
        case .karmaReceiptValidationFailure(message: let message):
            return "\("error.karma.receipt.validation.failed".localized) \(message)"
        }
    }
}
