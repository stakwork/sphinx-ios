//
//  StoreKitService.swift
//  sphinx
//
//  Created by Brian Sipple on 7/3/21.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import StoreKit


// MARK: - StoreKitServiceDelegate

protocol StoreKitServiceDelegate: AnyObject {
    
    /// Provides the delegate with the App Store's response.
    func storeKitServiceDidReceiveResponse(_ response: SKProductsResponse)
    
    /// Provides the delegate with the error encountered during the product request.
    func storeKitServiceDidReceiveMessage(_ message: String)
}



final class StoreKitService: NSObject {
    typealias ProductIdentifier = String
    
    enum ProductIdentifiers {
        static let add1000Karma = "com.gl.sphinx.1000karma"
        static let buyLiteNode = "com.gl.sphinx.liteNode"
    }
    
    
//    let productIdentifiers: [ProductIdentifier]
    
    
    /// Valid products that are available for sale in the App Store.
    private var availableProducts = [SKProduct]()
    
    
    /// Invalid products that are not available for sale in the App Store.
    //    private var invalidProductIdentifiers = [ProductIdentifier]()
    
    //    private var purchasedProductIdentifiers: Set<ProductIdentifier> = []
    
    
    /// Keeps a strong reference to the product request.
    private var productRequest: SKProductsRequest?
    
    
    /// Keeps track of all valid products (these products are available for sale in the App Store) and of all invalid product identifiers.
    //    private var storeResponse = [Section]()
    
    
    weak var delegate: StoreKitServiceDelegate?
    
    
    // MARK: - Init    private override init() {}
    private override init() {}

}


extension StoreKitService {
    static let shared: StoreKitService = .init()
}


extension StoreKitService {
    
    var isAuthorizedForPayments: Bool {
        SKPaymentQueue.canMakePayments()
    }
    
    
    var receiptURL: URL? {
        Bundle.main.appStoreReceiptURL
    }
}


extension StoreKitService {
    
    func fetchProducts(matchingIdentifiers identifiers: [String]) {
        let productIdentifiers = Set(identifiers)
        
        productRequest?.cancel()
        
        productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productRequest?.delegate = self
        
        productRequest?.start()
    }
    
    
    func getReceiptData(at url: URL) throws -> Data {
        return try Data(contentsOf: url, options: [.alwaysMapped])
    }
}




// MARK: - SKProductsRequestDelegate

extension StoreKitService: SKProductsRequestDelegate {
    
    func productsRequest(
        _ request: SKProductsRequest,
        didReceive response: SKProductsResponse
    ) {
        delegate?.storeKitServiceDidReceiveResponse(response)
    }
}


// MARK: - SKRequestDelegate

extension StoreKitService: SKRequestDelegate {

    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to load list of products.")
        print("Error: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            self.delegate?.storeKitServiceDidReceiveMessage(error.localizedDescription)
        }
    }
}


