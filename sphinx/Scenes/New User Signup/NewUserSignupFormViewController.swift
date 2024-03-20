//
//  NewUserSignupFormViewController.swift
//  sphinx
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import CoreData


class NewUserSignupFormViewController: UIViewController, ConnectionCodeSignupHandling {
    
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var codeTextFieldContainer: UIView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var connectToServerButton: UIButton!
    @IBOutlet weak var submitButtonContainer: UIView!
    @IBOutlet weak var submitButtonArrow: UILabel!
    @IBOutlet weak var importSeedContainer: UIView!
    @IBOutlet weak var importSeedView : ImportSeedView!
    
    let authenticationHelper = BiometricAuthenticationHelper()
    let newMessageBubbleHelper = NewMessageBubbleHelper()
    
    var generateTokenRetries = 0
    var generateTokenSuccess: Bool = false
    var hasAdminRetries: Int = 0
    
    var isV2:Bool = false
    var server : Server? = nil
    var balance : String? = nil
    var selfContactFetchListener: NSFetchedResultsController<UserContact>?
    var watchdogTimer: Timer?
    
    static func instantiate() -> NewUserSignupFormViewController {
        let viewController = StoryboardScene.NewUserSignup.newUserSignupFormViewController.instantiate()
        return viewController
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        newMessageBubbleHelper.genericMessageY = (
            UIApplication.shared.windows.first?.safeAreaInsets.top ?? 60
        ) + 60

        setupCodeField()
        setupSubmitButton()
        
        titleLabel.text = "new.user".localized.uppercased()
        addAccessibilityIdentifiers()
    }
    
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        SignupHelper.step = SignupHelper.SignupStep.Start.rawValue
        
        navigationController?.popToRootViewController(animated: true)
    }
    
    func addAccessibilityIdentifiers(){
        connectToServerButton.accessibilityIdentifier = connectToServerButton.titleLabel?.text
        submitButton.accessibilityIdentifier = "submit"
    }
}


extension NewUserSignupFormViewController {
 
    func setupSubmitButton() {
        submitButton.layer.cornerRadius = submitButton.frame.size.height / 2
        submitButton.clipsToBounds = true
        submitButton.setTitle("signup.submit".localized, for: .normal)
        
        connectToServerButton.layer.cornerRadius = submitButton.layer.cornerRadius
        connectToServerButton.clipsToBounds = true
        connectToServerButton.isEnabled = true
        connectToServerButton.isUserInteractionEnabled = true
        connectToServerButton.superview?.bringSubviewToFront(connectToServerButton)
        
        disableSubmitButton()
    }
    
    
    func setupCodeField() {
        codeTextFieldContainer.layer.cornerRadius = codeTextFieldContainer.frame.size.height / 2
        codeTextFieldContainer.layer.borderWidth = 1
        codeTextFieldContainer.layer.borderColor = UIColor.Sphinx.OnboardingPlaceholderText.resolvedCGColor(with: self.view)
        codeTextFieldContainer.clipsToBounds = true
        
        codeTextField.clipsToBounds = true
        codeTextField.placeholder = "signup.form.paste.code.placeholder".localized
        codeTextField.delegate = self
    }
    
    
    func disableSubmitButton() {
        submitButtonContainer.alpha = 0.3
        
        submitButton.isEnabled = false
        submitButton.backgroundColor = UIColor.white
        submitButton.setTitleColor(.black, for: .normal)
        submitButtonArrow.textColor = UIColor.white
        
        submitButton.removeShadow()
    }
    
    
    func enableSubmitButton() {
        submitButtonContainer.alpha = 1.0
        
        submitButton.isEnabled = true
        submitButton.backgroundColor = UIColor.Sphinx.PrimaryBlue
        submitButton.setTitleColor(.white, for: .normal)
        submitButtonArrow.textColor = UIColor.white
        
        submitButton.addShadow(location: .bottom, opacity: 0.5, radius: 2.0)
    }
}


extension NewUserSignupFormViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        handleSubmit()
        
        return true
    }
    

    func textFieldDidEndEditing(_ textField: UITextField) {
        if isCodeValid(textField.text ?? "") {
            enableSubmitButton()
        } else {
            disableSubmitButton()
        }
    }
    
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let currentString = textField.text! as NSString
        let newString = currentString.replacingCharacters(in: range, with: string)
        
        guard newString.isEmpty == false else { return true }
        
        if validateCode(newString as String) {
            enableSubmitButton()
        } else {
            disableSubmitButton()
        }
        return true
    }
}


extension NewUserSignupFormViewController : ImportSeedViewDelegate{
    func showImportSeedView() {
        importSeedView.showWith(delegate: self)
        importSeedContainer.isHidden = false
        importSeedView.context = .SphinxOnionPrototype
        importSeedView.accessibilityIdentifier = "importSeedView"
        importSeedView.textView.accessibilityIdentifier = "importSeedView.textView"
        importSeedView.confirmButton.accessibilityIdentifier = "importSeedView.confirmButton"
        importSeedView.cancelButton.accessibilityIdentifier = "importSeedView.cancelButton"
    }
    
    @objc func handleServerNotification(n: Notification) {
        if let server = n.userInfo?["server"] as? Server{
            self.server = server
            server.managedObjectContext?.saveContext()
        }
    }
    
    @objc func handleBalanceNotification(n:Notification){
        if let balance = n.userInfo?["balance"] as? String{
            self.balance = balance
        }
    }
    
    
    func showImportSeedView(
        network: String,
        host: String,
        relay: String
    ){
        importSeedView.showWith(
            delegate: self,
            network: network,
            host: host,
            relay: relay
        )
        importSeedContainer.isHidden = false
    }
    
    func didTapCancelImportSeed() {
        importSeedContainer.isHidden = true
    }
    
    func didTapConfirm() {
        if(importSeedView.context == .SphinxOnionPrototype){
            importSeedContainer.isHidden = true
            UserData.sharedInstance.save(walletMnemonic: importSeedView.textView.text)
            if let code = codeTextField.text,
               validateCode(code){
                handleInviteCodeV2SignUp(code: code)
            }
        }
        else{
            let success = CrypterManager.sharedInstance.performWalletFinalization(
                network: importSeedView.network,
                host: importSeedView.host,
                relay: importSeedView.relay,
                enteredMnemonic: importSeedView.textView.text
            )
            
            importSeedContainer.isHidden = !success
        }
    }
    
}
