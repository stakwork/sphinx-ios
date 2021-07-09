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
        case nodeHUBInvoiceGenerationFailure(message: String)
    }
}
