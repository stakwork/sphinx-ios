//
//  NewUserSignupOptionsViewController.swift
//  sphinx
//
//  Created by Brian Sipple on 7/1/21.
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import StoreKit


class NewUserSignupOptionsViewController: UIViewController, ConnectionCodeSignupHandling {
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var screenHeadlineLabel: UILabel!
    @IBOutlet weak var connectionCodeButtonContainer: UIView!
    @IBOutlet weak var connectionCodeButton: UIButton!
    @IBOutlet weak var purchaseLiteNodeButtonContainer: UIView!
    @IBOutlet weak var purchaseLiteNodeButton: UIButton!
    @IBOutlet weak var purchaseLoadingSpinner: UIActivityIndicatorView!
    
    
    internal var rootViewController: RootViewController!
    internal var hubNodeInvoice: API.HUBNodeInvoice?
    

    let newMessageBubbleHelper = NewMessageBubbleHelper()
    let storeKitService = StoreKitService.shared

    var generateTokenRetries = 0
    
    
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
        super.viewDidAppear(animated)

        purchaseLiteNodeButton.isEnabled = liteNodePurchaseProduct != nil
        fetchProductsInformation()
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        storeKitService.delegate = nil
    }
}
 

// MARK: - Action Handling
extension NewUserSignupOptionsViewController {
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        SignupHelper.step = SignupHelper.SignupStep.Start.rawValue
        
        navigationController?.popToRootViewController(animated: true)
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
        
        startPurchase(for: product)
    }
}


// MARK: - Private Helpers
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
        guard storeKitService.isAuthorizedForPayments else {
            purchaseLiteNodeButton.isEnabled = false
            return
        }
        
        storeKitService.fetchProducts(
            matchingIdentifiers: [StoreKitService.ProductIdentifiers.buyLiteNode]
        )
    }

    
    private func stopPurchaseProgressIndicator() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isPurchaseProcessing = false
        }
    }
    
    private func startPurchaseProgressIndicator() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isPurchaseProcessing = false
        }
    }
    
    
    private func startPurchase(for product: SKProduct) {
        startPurchaseProgressIndicator()
        
        // Get a fake invoice for a pre-assigned node from HUB
        API.sharedInstance.generateLiteNodeHUBInvoice { [weak self] result in
            guard let self = self else { return }
            
            self.stopPurchaseProgressIndicator()
            
            switch result {
            case .success(let invoice):
                self.hubNodeInvoice = invoice
                
                print("Successfully generated Lite Node Hub Invoice: \(invoice)")

                // Place a purchase on the AppStore to generate an AppStore receipt.
                self.storeKitService.purchase(product)
            case .failure(let error):
                self.hubNodeInvoice = nil
                
                var alertMessage: String
                
                if case .nodeHUBInvoiceGenerationFailure(let message) = error {
                    alertMessage = message
                } else {
                    alertMessage = "Purchase Eligibility Failed"
                }
                
                AlertHelper.showAlert(
                    title: "Lite Node Purchase Failed",
                    message: alertMessage
                )
            }
        }
    }
    
    
    /// Makes a Request to a HUB endpoint with the App Store receipt and
    /// invoice (obtained from first HUB request).
    ///
    /// The HUB will return the invite if the receipt is validated.
    private func generateConnectionCode(
        fromPurchasedNodeInvoice hubNodeInvoice: API.HUBNodeInvoice
    ) {
        startPurchaseProgressIndicator()

        guard let receiptString = storeKitService.getPurchaseReceipt() else {
            stopPurchaseProgressIndicator()
            
            AlertHelper.showAlert(
                title: "Lite Node Purchase Failed",
                message: "An AppStore purchase receipt could not be found."
            )
            
            return
        }

        API.sharedInstance.validateLiteNodePurchase(
            withAppStoreReceipt: receiptString,
            and: hubNodeInvoice
        ) { [weak self] result in
            guard let self = self else { return }
            
            self.stopPurchaseProgressIndicator()

            DispatchQueue.main.async {
                switch result {
                case .success(let connectionCode):
                    print("Successfully generated Lite Node Connection Code: \(connectionCode)")
                    self.signup(withConnectionCode: connectionCode)
                case .failure(let error):
                    AlertHelper.showAlert(
                        title: "Lite Node Purchase Failed",
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


// MARK: -  StoreKitServiceDelegate
extension NewUserSignupOptionsViewController: StoreKitServiceDelegate {
    
    func storeKitServiceDidObserveTransactionUpdate(
        on queue: SKPaymentQueue,
        updatedTransactions transactions: [SKPaymentTransaction]
    ) {
        guard
            let hubNodeInvoice = hubNodeInvoice,
            transactions.contains(
                where: { transaction in
                    transaction.transactionState == .purchased &&
                    transaction.payment.productIdentifier == liteNodePurchaseProduct?.productIdentifier
                }
            )
        else {
            return
        }
        
        generateConnectionCode(fromPurchasedNodeInvoice: hubNodeInvoice)
    }
    
    
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
}


// MARK: - ConnectionCodeSignupHandling
extension NewUserSignupOptionsViewController {
    
    func handleSignupConnectionError(message: String) {
        // Pop the "Connecting" VC
        navigationController?.popViewController(animated: true)
        
        SignupHelper.resetInviteInfo()
        SignupHelper.step = SignupHelper.SignupStep.NewUserSelected.rawValue

        newMessageBubbleHelper.showGenericMessageView(text: message)
    }
}
