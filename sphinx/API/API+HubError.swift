//
//  API+Errors.swift
//  sphinx
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import Alamofire


extension API {
    
    enum RequestError: Swift.Error {
        case failedToCreateRequestURL
        case failedToCreateRequest(urlPath: String)
        case missingResponseData
        case decodingError(DecodingError)
        case unknownError(Swift.Error)
        case unexpectedResponseData
        case failedToFetchContentFeed
        case networkError(AFError)
        case nodeInvoiceGenerationFailure(message: String)
        case karmaReceiptValidationFailure(message: String)
    }
}


extension API.RequestError: LocalizedError {
    
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
        case .failedToCreateRequestURL:
            return "error.request.urlCreation.failed".localized
        case .missingResponseData:
            return "error.request.missingResponseData".localized
        case .decodingError(let error):
            return "\("error.request.decodingFailed".localized) \(error)"
        case .unknownError(let error):
            return "\("error.request.unknown".localized) \(error)"
        case .failedToFetchContentFeed:
            return "error.request.contentFeedFetch.failed".localized
        }
    }
}
