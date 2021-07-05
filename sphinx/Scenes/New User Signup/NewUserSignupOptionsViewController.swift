//
//  NewUserSignupOptionsViewController.swift
//  sphinx
//
//  Created by Brian Sipple on 7/1/21.
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import StoreKit


class NewUserSignupOptionsViewController: UIViewController {
    @IBOutlet weak var screenHeadlineLabel: UILabel!
    @IBOutlet weak var connectionCodeButtonContainer: UIView!
    @IBOutlet weak var connectionCodeButton: UIButton!
    @IBOutlet weak var purchaseLiteNodeButtonContainer: UIView!
    @IBOutlet weak var purchaseLiteNodeButton: UIButton!
    @IBOutlet weak var purchaseLoadingSpinner: UIActivityIndicatorView!
    
    
    private var rootViewController: RootViewController!
    
    
    let storeKitService = StoreKitService.shared
    
    
    var isPurchaseProcessing: Bool = false {
        didSet {
            purchaseLoadingSpinner.isHidden = isPurchaseProcessing == false
        }
    }

    
    var liteNodePurchaseProduct: SKProduct? {
        didSet {
            purchaseLiteNodeButton.isEnabled = liteNodePurchaseProduct != nil
        }
    }
    
    
    static func instantiate(
        rootViewController: RootViewController
    ) -> NewUserSignupOptionsViewController {
        let viewController = StoryboardScene.NewUserSignup.newUserSignupOptionsViewController.instantiate()
        
        viewController.rootViewController = rootViewController
        
        return viewController
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        storeKitService.delegate = self
        SKPaymentQueue.default().add(self)

        setupButton(
            connectionCodeButton,
            withTitle: "signup.signup-options.connection-code-button".localized
        )
        
        setupButton(
            purchaseLiteNodeButton,
            withTitle: "signup.signup-options.lite-node-button".localized
        )
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        fetchProductsInformation()
    }
    
    
    @IBAction func connectionCodeButtonTapped(_ sender: UIButton) {
        let nextVC = NewUserSignupDescriptionViewController.instantiate(
            rootViewController: rootViewController
        )
        
        navigationController?.pushViewController(nextVC, animated: true)
    }
    
    
    @IBAction func purchaseLiteNodeButtonTapped(_ sender: UIButton) {
        guard let product = liteNodePurchaseProduct else {
            preconditionFailure()
        }
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
}


extension NewUserSignupOptionsViewController {
 
    private func setupButton(
        _ button: UIButton,
        withTitle title: String
    ) {
        
        button.setTitle(title, for: .normal)
        button.layer.cornerRadius = button.frame.size.height / 2
        button.clipsToBounds = true
        
        button.addShadow(location: .bottom, opacity: 0.2, radius: 2.0)
    }
    
    
    private func fetchProductsInformation() {
        guard SKPaymentQueue.canMakePayments() else {
            purchaseLiteNodeButton.isEnabled = false
            return
        }
        
        storeKitService.fetchProducts(
            matchingIdentifiers: [StoreKitService.ProductIdentifiers.buyLiteNode]
        )
    }
}
    


// MARK: -  StoreKitServiceDelegate
extension NewUserSignupOptionsViewController: StoreKitServiceDelegate {
    
    func storeKitServiceDidReceiveResponse(_ response: SKProductsResponse) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.liteNodePurchaseProduct = response
                .products
                .first(where: {
                    $0.productIdentifier == StoreKitService.ProductIdentifiers.buyLiteNode
                }
            )
        }
    }
    
    
    func storeKitServiceDidReceiveMessage(_ message: String) {
        
    }
    
    
    func stopPurchaseProgress() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isPurchaseProcessing = false
        }
    }
    
    
    func validateReceipt(transaction: SKPaymentTransaction) {
        guard let receiptURL = storeKitService.receiptURL else {
            stopPurchaseProgress()
            return
        }
        
        guard let receiptData = try? storeKitService.getReceiptData(at: receiptURL) else {
            stopPurchaseProgress()
            return
        }
        
        let receiptString = receiptData.base64EncodedString(options: [])
                
        /**
         * TODO: Make a Request to a HUB endpoint with the receipt and
         * invoice (obtained from first HUB request).
         *
         *  - The HUB will return the invite if the receipt is validated.
         *  - From there, we need to handle/indicate the response to the user as appropriate.
         */
        API.sharedInstance.validateLiteNodePurchase(using: receiptString) { result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.stopPurchaseProgress()
                
                switch result {
                case .success:
                    // TODO: Present Invite Code
                    AlertHelper.showAlert(
                        title: "Lite Node Purchase",
                        message: "Receipt Validation Succeeded"
                    )
                    break
                case .failure:
                    // TODO: Handle failure
                    AlertHelper.showAlert(
                        title: "Lite Node Purchase",
                        message: "Receipt Validation Failed"
                    )
                }
            }
        }
    }
}



// MARK: - SKPaymentTransactionObserver

extension NewUserSignupOptionsViewController: SKPaymentTransactionObserver {

    func paymentQueue(
        _ queue: SKPaymentQueue,
        updatedTransactions transactions: [SKPaymentTransaction]
    ) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                validateReceipt(transaction: transaction)
//                transactionState = .purchasing
            case .purchased:
//                transactionState = .purchased
                queue.finishTransaction(transaction)
            case .restored:
//                transactionState = .restored
                queue.finishTransaction(transaction)
            case .failed, .deferred:
//                transactionState = .failed
                queue.finishTransaction(transaction)
                AlertHelper.showAlert(
                    title: "Lite Node Purchase",
                    message: "Payment Failed"
                )
            default:
                print("Unknown transaction state: \(transaction.transactionState)")
                queue.finishTransaction(transaction)
            }
        }
    }
}
