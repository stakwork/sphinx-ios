//
//  NewUserSignupFormViewController.swift
//  sphinx
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit


class NewUserSignupFormViewController: UIViewController, ConnectionCodeSignupHandling {
    
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var codeTextFieldContainer: UIView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var submitButtonContainer: UIView!
    @IBOutlet weak var submitButtonArrow: UILabel!
    @IBOutlet weak var importSeedView : ImportSeedView!

    let authenticationHelper = BiometricAuthenticationHelper()
    let newMessageBubbleHelper = NewMessageBubbleHelper()
    
    var generateTokenRetries = 0
    var generateTokenSuccess: Bool = false
    var hasAdminRetries: Int = 0

    
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
    }
    
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        SignupHelper.step = SignupHelper.SignupStep.Start.rawValue
        
        navigationController?.popToRootViewController(animated: true)
    }
}


extension NewUserSignupFormViewController {
 
    func setupSubmitButton() {
        submitButton.layer.cornerRadius = submitButton.frame.size.height / 2
        submitButton.clipsToBounds = true
        submitButton.setTitle("signup.submit".localized, for: .normal)
        
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
    }
    
    func didTapCancelImportSeed() {
        importSeedView.textView.resignFirstResponder()
        importSeedView.textView.text = ""
        importSeedView.isHidden = true
        importSeedView.activityView.stopAnimating()
    }
    
    func didTapConfirm() {
        importSeedView.activityView.startAnimating()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [self] in
            
            let words = importSeedView.textView.text.split(separator: " ").map { String($0).trim().lowercased() }
            let (error, additionalString) = CrypterManager.sharedInstance.validateSeed(words: words)
            
            if let error = error {
                AlertHelper.showAlert(title: "profile.seed-validation-error-title".localized, message: error.localizedDescription + (additionalString ?? ""))
                return
            }
            
            self.importSeedView.activityView.isHidden = false
            self.importSeedView.activityView.backgroundColor = UIColor.Sphinx.PrimaryBlue
            
            CrypterManager.sharedInstance.performWalletFinalization(
                network: importSeedView.network,
                host: importSeedView.host,
                relay: importSeedView.relay,
                enteredMnemonic: importSeedView.textView.text
            )
        })
    }
    
}
