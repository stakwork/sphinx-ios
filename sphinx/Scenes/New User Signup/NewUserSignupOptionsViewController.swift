//
//  NewUserSignupOptionsViewController.swift
//  sphinx
//
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
    @IBOutlet weak var importSeedView: ImportSeedView!
    
    
    internal var hubNodeInvoice: API.HUBNodeInvoice?

    let newMessageBubbleHelper = NewMessageBubbleHelper()
    let storeKitService = StoreKitService.shared

    var generateTokenRetries = 0
    var hasAdminRetries = 0
    var generateTokenSuccess: Bool = false
    
    
    var isPurchaseProcessing: Bool = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: isPurchaseProcessing, loadingWheel: purchaseLoadingSpinner, loadingWheelColor: UIColor.Sphinx.Text, view: view)
        }
    }

    
    var liteNodePurchaseProduct: SKProduct?
    
    
    static func instantiate() -> NewUserSignupOptionsViewController {
        let viewController = StoryboardScene.NewUserSignup.newUserSignupOptionsViewController.instantiate()
        return viewController
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        storeKitService.requestDelegate = self
        storeKitService.transactionObserverDelegate = self

        setupButton(
            connectionCodeButton,
            withTitle: "signup.signup-options.connection-code-button".localized
        )
        
        setupButton(
            purchaseLiteNodeButton,
            withTitle: "signup.signup-options.lite-node-button".localized
        )
        
        fetchProductsInformation()
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        storeKitService.requestDelegate = nil
    }
}
 

// MARK: - Action Handling
extension NewUserSignupOptionsViewController {
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        SignupHelper.step = SignupHelper.SignupStep.Start.rawValue
        
        navigationController?.popToRootViewController(animated: true)
    }
    
    
    @IBAction func connectionCodeButtonTapped(_ sender: UIButton) {
        AlertHelper.showAlert(title: "signup.signer-required-title".localized, message: "signup.signer-required-prompt".localized,completion: {
            CrypterManager.sharedInstance.showQRScanner(presentingVC: self)
        })
    }
    
    
    @IBAction func purchaseLiteNodeButtonTapped(_ sender: UIButton) {
        guard let product = liteNodePurchaseProduct else {
            AlertHelper.showAlert(
                title: "generic.error.title".localized,
                message: "signup.products-fetch-failed".localized
            )
            return
        }
        startPurchase(for: product)
    }
    
    func setupWallet(){
        importSeedView.delegate = self
        CrypterManager.sharedInstance.setupSigningDevice(
            vc: self,
            overrideMessages:true//quietly disconnect MQTT if we need a restart
        ) { relay in
            UserData.sharedInstance.save(ip: "https://\(relay ?? "")")
            self.didTapCancelImportSeed()
            self.importSeedView.textView.resignFirstResponder()
            self.hasAdminRetries = 0
            self.checkForAdmin(relay: relay ?? "", completion: {
                //self.presentConnectingLoadingScreenVC()
                self.postToGenerateToken(callback: {
                })
            })
        }
    }
    
    func checkForAdmin(relay: String,completion: @escaping ()->()) {
        if hasAdminRetries < 50 {
            hasAdminRetries += 1
            API.sharedInstance.getHasAdmin(relay: relay, completionHandler: { result in
                switch result {
                case .success(let success):
                    success ? completion() : DelayPerformedHelper.performAfterDelay(seconds: 2.0, completion: {
                        self.checkForAdmin(relay: relay, completion: completion)
                    })
                case .failure(let error):
                    // Handle the error here if needed
                    print("checkForAdmin error:\(error)")
                    self.checkForAdmin(relay: relay, completion: completion)
                }
            })
        } else {
            AlertHelper.showAlert(title: "signup.setup-swarm-admin-error-title".localized, message: "signup.setup-swarm-admin-error-prompt".localized)
        }
    }
    
    func postToGenerateToken(callback: @escaping ()->()){
        do{
            let (_, seed) = CrypterManager.sharedInstance.getOrCreateWalletMnemonic()
            let network = CrypterManager.sharedInstance.hardwarePostDto.bitcoinNetwork ?? ""
            let keys = try nodeKeys(net: network, seed: seed.hexString)
            let token = EncryptionManager.randomString(length: 20)
            
            self.generateTokenAndProceed(pubkey: keys.pubkey, password: nil)
            callback()
        }
        catch{
            print("catch statement in postToGenerateToken with error: \(error)")
        }
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
        startPurchaseProgressIndicator()
        
        guard storeKitService.isAuthorizedForPayments else {
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
    
    internal func startPurchaseProgressIndicator() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isPurchaseProcessing = true
        }
    }
    
    
    private func startPurchase(for product: SKProduct) {
        startPurchaseProgressIndicator()
        
        // Get a fake invoice for a pre-assigned node from HUB
        API.sharedInstance.generateLiteNodeHUBInvoice { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let invoice):
                self.hubNodeInvoice = invoice
                
                print("Successfully generated Lite Node Hub Invoice: \(invoice)")
                // Place a purchase on the AppStore to generate an AppStore receipt.
                self.storeKitService.purchase(product)
            case .failure(let error):
                self.stopPurchaseProgressIndicator()
                self.hubNodeInvoice = nil
                
                var alertMessage: String
                
                if case .nodeInvoiceGenerationFailure(let message) = error {
                    alertMessage = message
                } else {
                    alertMessage = "signup.purchase-eligibility-failed".localized
                }
                
                AlertHelper.showAlert(
                    title: "signup.lite-node-purchase-failed".localized,
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
                title: "signup.lite-node-purchase-failed".localized,
                message: "error.app-store-purchase-receipt-not-found".localized
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
                        title: "signup.lite-node-purchase-failed".localized,
                        message: """
                        \("error.app-store-receipt-validation-failed".localized)
                        
                        Error: \(error.localizedDescription)
                        
                        \("generic.contact-support".localized)
                        """
                    )
                }
            }
        }
    }
}


// MARK: -  StoreKitServiceTransactionObserverDelegate
extension NewUserSignupOptionsViewController: StoreKitServiceTransactionObserverDelegate {
    
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
    
    func storeKitServiceDidObserveTransactionRemovedFromQueue() {
        stopPurchaseProgressIndicator()
    }
}
    
 
// MARK: -  StoreKitServiceRequestDelegate
extension NewUserSignupOptionsViewController: StoreKitServiceRequestDelegate {
    func storeKitServiceDidReceiveResponse(_ response: SKProductsResponse) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.liteNodePurchaseProduct = response
                .products
                .first(where: {
                    $0.productIdentifier == StoreKitService.ProductIdentifiers.buyLiteNode
                }
            )
            
            self.stopPurchaseProgressIndicator()
        }
    }
    
    
    func storeKitServiceDidReceiveMessage(_ message: String) {
        AlertHelper.showAlert(
            title: "generic.error.title".localized,
            message: "\("signup.products-fetch-failed".localized)\n Error: \(message)"
        )
        stopPurchaseProgressIndicator()
    }
}


// MARK: - ConnectionCodeSignupHandling
extension NewUserSignupOptionsViewController {
    
    func handleSignupConnectionError(message: String) {
        // Pop the "Connecting" VC
        navigationController?.popViewController(animated: true)
        
        SignupHelper.resetInviteInfo()

        newMessageBubbleHelper.showGenericMessageView(text: message)
    }
}


extension NewUserSignupOptionsViewController : ImportSeedViewDelegate{
    func showImportSeedView(network:String,host:String,relay:String){
        self.importSeedView.isHidden = false
        self.importSeedView.delegate = self
        importSeedView.network = network
        importSeedView.host = host
        importSeedView.relay = relay
        self.view.bringSubviewToFront(importSeedView)
        
        importSeedView.layer.zPosition = 999
    }
    
    func didTapCancelImportSeed() {
        self.importSeedView.textView.resignFirstResponder()
        self.importSeedView.textView.text = ""
        self.importSeedView.isHidden = true
        self.importSeedView.activityView.stopAnimating()
    }
    
    func didTapConfirm() {
        self.importSeedView.activityView.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [self] in
            let words = self.importSeedView.textView.text.split(separator: " ").map { String($0).trim().lowercased() }
            let (error, additionalString) = CrypterManager.sharedInstance.validateSeed(words: words)
            if let error = error {
                AlertHelper.showAlert(title: "profile.seed-validation-error-title".localized, message: error.localizedDescription + (additionalString ?? ""))
                return
            }
            self.importSeedView.activityView.isHidden = false
            self.importSeedView.activityView.backgroundColor = UIColor.Sphinx.PrimaryBlue
            CrypterManager.sharedInstance.performWalletFinalization(network: self.importSeedView.network, host: self.importSeedView.host, relay: importSeedView.relay,enteredMnemonic: self.importSeedView.textView.text)
        })
    }
    
}
