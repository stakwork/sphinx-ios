//
//  RestoreUserFormViewController.swift
//  sphinx
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import CoreData

class RestoreUserFormViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var codeTextFieldContainer: UIView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var submitButtonContainer: UIView!
    @IBOutlet weak var submitButtonArrow: UILabel!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var keychainRestoreButtonContainer: UIView!
    @IBOutlet weak var keychainRestoreLabel: UILabel!
    
    
    let userData = UserData.sharedInstance
    let onionConnector = SphinxOnionConnector.sharedInstance
    let authenticationHelper = BiometricAuthenticationHelper()
    let newMessageBubbleHelper = NewMessageBubbleHelper()
    
    var selfContactFetchListener: NSFetchedResultsController<UserContact>?
    var watchdogTimer: Timer?
    
    static func instantiate() -> RestoreUserFormViewController {
        let viewController = StoryboardScene.RestoreUser.restoreUserFormViewController.instantiate()
        return viewController
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        newMessageBubbleHelper.genericMessageY = (
            UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 60
        ) + 60

        setupKeychainButtonContainer()
        setupCodeField()
        setupSubmitButton()
        
        keychainRestoreLabel.text = "restore.keychain".localized
        titleLabel.text = "connect".localized.uppercased()
    }
    
    
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        handleSubmit()
    }
    
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        SignupHelper.step = SignupHelper.SignupStep.Start.rawValue
        
        self.navigationController?.popToRootViewController(animated: true)
    }
}


extension RestoreUserFormViewController {
 
    func setupSubmitButton() {
        submitButton.setTitle("submit".localized, for: .normal)
        submitButton.layer.cornerRadius = submitButton.frame.size.height / 2
        submitButton.clipsToBounds = true
        
        disableSubmitButton()
    }
    
    
    internal func setupCodeField() {
        codeTextFieldContainer.layer.cornerRadius = codeTextFieldContainer.frame.size.height / 2
        codeTextFieldContainer.layer.borderWidth = 1
        codeTextFieldContainer.layer.borderColor = UIColor.Sphinx.OnboardingPlaceholderText.resolvedCGColor(with: self.view)
        codeTextFieldContainer.clipsToBounds = true
        
        codeTextField.placeholder = "restore.form.paste.keys.placeholder".localized
        codeTextField.delegate = self
    }
    
    
    func setupKeychainButtonContainer() {
        keychainRestoreButtonContainer.alpha = userData.isRestoreAvailable() ? 1.0 : 0.0
    }
    
    
    func disableSubmitButton() {
        submitButtonContainer.alpha = 0.3
        
        submitButton.isEnabled = false
        submitButton.backgroundColor = UIColor.white
        submitButton.setTitleColor(.black, for: .normal)
        submitButton.removeShadow()
        
        submitButtonArrow.textColor = UIColor.white
    }
    
    
    func enableSubmitButton() {
        submitButtonContainer.alpha = 1.0
        
        submitButton.isEnabled = true
        submitButton.backgroundColor = UIColor.Sphinx.PrimaryBlue
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.addShadow(location: .bottom, opacity: 0.5, radius: 2.0)
        
        submitButtonArrow.textColor = UIColor.white
    }
    
    
    func save(ip: String, and password: String) {
        userData.save(ip: ip)
        userData.save(password: password)
    }
}


extension RestoreUserFormViewController: UITextFieldDelegate {
    
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
