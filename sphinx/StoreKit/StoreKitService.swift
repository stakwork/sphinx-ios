//
//  StoreKitService.swift
//  sphinx
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import StoreKit


// MARK: - StoreKitServiceRequestDelegate

protocol StoreKitServiceRequestDelegate: AnyObject {
    
    /// Provides the delegate with the App Store's response.
    func storeKitServiceDidReceiveResponse(_ response: SKProductsResponse)
    
    /// Provides the delegate with the error encountered during the product request.
    func storeKitServiceDidReceiveMessage(_ message: String)
}


// MARK: - StoreKitServiceTransactionObserverDelegate

protocol StoreKitServiceTransactionObserverDelegate: AnyObject {
    
    func storeKitServiceDidObserveTransactionUpdate(
        on queue: SKPaymentQueue,
        updatedTransactions transactions: [SKPaymentTransaction]
    )
    
    func storeKitServiceDidObserveTransactionRemovedFromQueue()
}


final class StoreKitService: NSObject {
    typealias ProductIdentifier = String
    
    enum ProductIdentifiers {
        static let add1000Karma = "com.gl.sphinx.1000karma"
        static let buyLiteNode = "com.gl.sphinx.liteSphinxNode"
    }
    
    
    /// Valid products that are available for sale in the App Store.
    private var availableProducts = [SKProduct]()
    
    
    /// Invalid products that are not available for sale in the App Store.
    //    private var invalidProductIdentifiers = [ProductIdentifier]()
    
    //    private var purchasedProductIdentifiers: Set<ProductIdentifier> = []
    
    
    /// Keeps a strong reference to the product request.
    private var productRequest: SKProductsRequest?
    
    
    weak var requestDelegate: StoreKitServiceRequestDelegate?
    weak var transactionObserverDelegate: StoreKitServiceTransactionObserverDelegate?
    
    
    // MARK: - Init
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


// MARK: -  Public Methods
extension StoreKitService {
    
    func fetchProducts(matchingIdentifiers identifiers: [String]) {
        let productIdentifiers = Set(identifiers)
        
        productRequest?.cancel()
        
        productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productRequest?.delegate = self
        
        productRequest?.start()
    }
    
    /// Create and add a payment request to the payment queue.
    func purchase(_ product: SKProduct) {
        let payment = SKMutablePayment(product: product)
    
        SKPaymentQueue.default().add(payment)
    }
    
    
    func getPurchaseReceipt() -> String? {
        guard let receiptURL = receiptURL else {
            // TODO: Properly handle this
            return nil
        }
        
        guard let receiptData = try? getReceiptData(at: receiptURL) else {
            // TODO: Properly handle this
            return nil
        }
        
        return receiptData.base64EncodedString(options: [])
    }
    
    
    func restoreProducts() {
        print("Restoring products ...")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}


// MARK: -  Private Helpers
extension StoreKitService {
    
    private func getReceiptData(at url: URL) throws -> Data {
        return try Data(contentsOf: url, options: [.alwaysMapped])
    }
}



// MARK: - SKProductsRequestDelegate
extension StoreKitService: SKProductsRequestDelegate {
    
    func productsRequest(
        _ request: SKProductsRequest,
        didReceive response: SKProductsResponse
    ) {
        requestDelegate?.storeKitServiceDidReceiveResponse(response)
    }
}


// MARK: - SKRequestDelegate
extension StoreKitService: SKRequestDelegate {

    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to load list of products.")
        print("Error: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            self.requestDelegate?.storeKitServiceDidReceiveMessage(error.localizedDescription)
        }
    }
}


// MARK: - SKPaymentTransactionObserver

extension StoreKitService: SKPaymentTransactionObserver {

    func paymentQueue(
        _ queue: SKPaymentQueue,
        updatedTransactions transactions: [SKPaymentTransaction]
    ) {
        transactionObserverDelegate?.storeKitServiceDidObserveTransactionUpdate(
            on: queue,
            updatedTransactions: transactions
        )
        
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                break
            case .purchased:
                queue.finishTransaction(transaction)
            case .restored:
                queue.finishTransaction(transaction)
            case .deferred:
                break
            case .failed:
                queue.finishTransaction(transaction)
            @unknown default:
                print("Unknown transaction state: \(transaction.transactionState)")
                queue.finishTransaction(transaction)
            }
        }
    }
    
    /// Logs all transactions that have been removed from the payment queue.
    func paymentQueue(
        _ queue: SKPaymentQueue,
        removedTransactions transactions: [SKPaymentTransaction]
    ) {
        transactionObserverDelegate?.storeKitServiceDidObserveTransactionRemovedFromQueue()
        
        for transaction in transactions {
            print("\(transaction.payment.productIdentifier) was removed from the payment queue.")
        }
    }
}

