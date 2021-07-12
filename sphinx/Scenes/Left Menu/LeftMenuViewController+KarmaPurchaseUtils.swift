//
//  LeftMenuViewController+KarmaPurchaseUtils.swift
//  sphinx
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import StoreKit




// MARK: -  StoreKitServiceRequestDelegate
extension LeftMenuViewController: StoreKitServiceRequestDelegate {
    
    func storeKitServiceDidReceiveResponse(_ response: SKProductsResponse) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.karmaPurchaseProduct = response
                .products
                .first(where: {
                    $0.productIdentifier == StoreKitService.ProductIdentifiers.add1000Karma
                }
            )
        }
    }
    
    
    func storeKitServiceDidReceiveMessage(_ message: String) {
    }
}


// MARK: -  StoreKitServiceTransactionObserverDelegate
extension LeftMenuViewController: StoreKitServiceTransactionObserverDelegate {
    
    func storeKitServiceDidObserveTransactionUpdate(
        on queue: SKPaymentQueue,
        updatedTransactions transactions: [SKPaymentTransaction]
    ) {
        guard transactions.contains(where: { transaction in
            transaction.transactionState == .purchased &&
            transaction.payment.productIdentifier == karmaPurchaseProduct?.productIdentifier
        }) else {
            return
        }
        
        finalizeKarmaPurchase()
    }
    
    func storeKitServiceDidObserveTransactionRemovedFromQueue() {}
}
    

extension LeftMenuViewController {
    
    func finalizeKarmaPurchase() {
        guard let receiptString = storeKitService.getPurchaseReceipt() else {
            AlertHelper.showAlert(
                title: "Karma Purchase Failed",
                message: "An AppStore purchase receipt could not be found."
            )
            
            return
        }
        
        guard
            let ownerPubKey = UserContact.getOwner()?.publicKey,
            let routeHint = UserContact.getOwner()?.routeHint
        else {
            AlertHelper.showAlert(
                title: "Karma Purchase Failed",
                message: "Node Address Information Invalid"
            )
            
            return
        }

        API.sharedInstance.validateKarmaPurchase(
            withAppStoreReceipt: receiptString,
            forNodePubKey: ownerPubKey,
            andRouteHint: routeHint
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Successfully purchased Karma")
                    
                // TODO: How should the UI update or provide any user feedback here?
                case .failure(let error):
                    AlertHelper.showAlert(
                        title: "Karma Purchase Failed",
                        message: """
                        AppStore Receipt Validation Failed.
                        
                        Error: \(error.localizedDescription)
                        """
                    )
                }
            }
        }
    }
}
