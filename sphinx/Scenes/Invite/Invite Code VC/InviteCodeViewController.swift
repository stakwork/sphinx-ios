//
//  InviteCodeViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import SwiftyJSON

class InviteCodeViewController: KeyboardEventsViewController {
    
    private weak var delegate: MenuDelegate?
    var rootViewController : RootViewController!

    @IBOutlet weak var whiteLogo: UIImageView!
    @IBOutlet weak var sphinxLabel: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var codeFieldContainer: UIView!
    @IBOutlet weak var inviteCodeTextField: UITextField!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var loadingWheelLabel: UILabel!
    @IBOutlet weak var whiteLogoTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var fieldContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var keychainRestoreContainer: UIView!
    
    let kErrorTitle = "whoops".localized
    let kWelcomeTitle = "welcome".localized
    let kErrorSubtitle = "contact.support".localized
    let kWelcomeSubtitle = "paste.invite.text".localized
    let kErrorSubtitleBold = "support@sphinx.chat"
    let kWelcomeSubtitleBold = ""
    
    let userData = UserData.sharedInstance
    let onionConnector = SphinxOnionConnector.sharedInstance
    let authenticationHelper = BiometricAuthenticationHelper()
    let messageBubbleHelper = NewMessageBubbleHelper()
    
    var generateTokenRetries = 0
    
    var loading = false {
        didSet {
            loadingWheelLabel.text = loading ? loadingWheelLabel.text : ""
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.white, view: view)
        }
    }
    
    static func instantiate(rootViewController : RootViewController, delegate: MenuDelegate) -> InviteCodeViewController {
        let viewController = StoryboardScene.Invite.inviteCodeViewController.instantiate()
        viewController.rootViewController = rootViewController
        viewController.delegate = delegate
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rootViewController.setStatusBarColor(light: true)
        
        whiteLogoTopConstraint.constant = 220
        whiteLogo.superview?.layoutIfNeeded()
        sphinxLabel.alpha = 1.0
        titleLabel.alpha = 0.0
        subtitleLabel.alpha = 0.0
        codeFieldContainer.alpha = 0.0
        
        codeFieldContainer.layer.cornerRadius = codeFieldContainer.frame.size.height / 2
        codeFieldContainer.clipsToBounds = true
        codeFieldContainer.addShadow(location: .bottom, color: UIColor.Sphinx.PrimaryBlueBorder, opacity: 0.5, radius: 2.0)
        inviteCodeTextField.delegate = self
        
        completeTexts(showError: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5) {
            self.animateView()
        }
    }
    
    @objc override func keyboardWillShow(_ notification: Notification) {
        let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
        animateForKeyboard(visible: true, keyboardHeight: keyboardHeight ?? 0)
    }
    
    @objc override func keyboardWillHide(_ notification: Notification) {
        animateForKeyboard(visible: false, keyboardHeight: 0)
    }
    
    func animateView() {
        whiteLogoTopConstraint.constant = 90
        
        UIView.animate(withDuration: 0.5, animations: {
            self.whiteLogo.superview?.layoutIfNeeded()
            self.sphinxLabel.alpha = 0.0
        }, completion: {_ in
            UIView.animate(withDuration: 0.3, animations: {
                self.titleLabel.alpha = 1.0
                self.subtitleLabel.alpha = 1.0
                self.codeFieldContainer.alpha = 1.0
                self.keychainRestoreContainer.alpha = self.userData.isRestoreAvailable() ? 1.0 : 0.0
            })
        })
    }
    
    func animateForKeyboard(visible: Bool, keyboardHeight: CGFloat) {
        let fieldContainerHeight: CGFloat = 65
        let finalAnimationPosition: CGFloat = codeFieldContainer.frame.origin.y - 100
        let bottomLimit = WindowsManager.getWindowHeight() - keyboardHeight - fieldContainerHeight - 10
        let topConstraint = bottomLimit < finalAnimationPosition ? -(codeFieldContainer.frame.origin.y - bottomLimit) : -100
        
        fieldContainerTopConstraint.constant = visible ? topConstraint : 0
        UIView.animate(withDuration: 0.5, animations: {
            self.codeFieldContainer.superview?.layoutIfNeeded()
            self.titleLabel.alpha = visible ? 0.0 : 1.0
            self.subtitleLabel.alpha = visible ? 0.0 : 1.0
        })
    }
    
    func animateInvalidCode(showError: Bool) {
        UIView.animate(withDuration: 0.3, animations: {
            self.codeFieldContainer.alpha = 0.0
            self.titleLabel.alpha = 0.0
            self.subtitleLabel.alpha = 0.0
        }, completion: {_ in
            self.completeTexts(showError: showError)
            
            UIView.animate(withDuration: 0.3, animations: {
                self.titleLabel.alpha = 1.0
                self.subtitleLabel.alpha = 1.0
                self.codeFieldContainer.alpha = showError ? 0.0 : 1.0
            })
        })
    }
    
    @IBAction func keychainRestoreButtonTouched() {
        authenticationHelper.authenticationAction(policy: .deviceOwnerAuthentication) { success in
            if success {
                self.goToKeychainRestore()
            }
        }
    }
    
    func goToKeychainRestore() {
        let viewController = KeychainRestoreViewController.instantiate(delegate: self)
        self.present(viewController, animated: true)
    }
    
    @IBAction func qrCodeButtonTouched() {
        let viewController = NewQRScannerViewController.instantiate()
        viewController.currentMode = NewQRScannerViewController.Mode.ScanAndDismiss
        viewController.delegate = self
        self.present(viewController, animated: true)
    }
    
    func nextButtonTouched() {
        if let code = inviteCodeTextField.text, code != "" {
            if !validateCode(code: code) {
                return
            }
            
            loading = true
            
            if isNodeConnectQR(string: code) {
                return
            }
            
            if isRestoreQR(string: code) || isRestoreQR(string: code.fixedRestoreCode) {
                return
            }
            
            signupWith(code: code)
        }
    }
    
    func signupError() {
        SignupHelper.resetInviteInfo()
        
        DelayPerformedHelper.performAfterDelay(seconds: 1.5) {
            self.loading = false
            self.animateInvalidCode(showError: true)
        }
        DelayPerformedHelper.performAfterDelay(seconds: 4.0) {
            self.inviteCodeTextField.text = ""
            self.animateInvalidCode(showError: false)
        }
    }
    
    func signupWith(code: String) {
        API.sharedInstance.signupWithCode(inviteString: code, callback: { (invite, ip, pubkey) in
            UserData.sharedInstance.save(ip: ip)
            
            SignupHelper.saveInviterInfo(invite: invite, code: code)
            self.generateTokenAndProceed(pubkey: pubkey)
        }, errorCallback: {
            self.signupError()
        })
    }
    
    func generateTokenAndProceed(pubkey: String, password: String? = nil) {
        let token = EncryptionManager.randomString(length: 20)
        generateTokenAndProceed(pubkey: pubkey, token: token, password: password)
    }
    
    func generateTokenAndProceed(pubkey: String, token: String, password: String? = nil) {
        generateTokenRetries = generateTokenRetries + 1
        
        API.sharedInstance.generateToken(token: token, pubkey: pubkey, password: password, callback: { success in
            if success {
                self.userData.save(authToken: token)
                self.goToInviteWelcome()
            } else {
                self.generateTokenError(pubkey: pubkey, token: token, password: password)
            }
        }, errorCallback: {
            self.generateTokenError(pubkey: pubkey, token: token, password: password)
        })
    }
    
    func generateTokenError(pubkey: String, token: String, password: String? = nil) {
        if generateTokenRetries < 4 {
            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                self.generateTokenAndProceed(pubkey: pubkey, token: token, password: password)
            })
            return
        }
        signupError()
    }
    
    func goToInviteWelcome() {
        SignupHelper.step = SignupHelper.SignupStep.IPAndTokenSet.rawValue
        
        guard let inviter = SignupHelper.getInviter() else {
            let defaultInviter = SignupHelper.getDefaultInviter()
            SignupHelper.saveInviterInfo(invite: defaultInviter)
            goToInviteWelcome()
            return
        }
        
        let inviteWelcome = InviteWelcomeViewController.instantiate(rootViewController: rootViewController, inviter: inviter)
        self.navigationController?.pushViewController(inviteWelcome, animated: true)
    }
    
    func completeTexts(showError: Bool) {
        let normalFont = UIFont(name: "Roboto-Regular", size: 17.0)!
        let boldFont = UIFont(name: "Roboto-Bold", size: 17.0)!
        
        self.titleLabel.text = showError ? self.kErrorTitle : self.kWelcomeTitle
        let text = showError ? self.kErrorSubtitle : self.kWelcomeSubtitle
        let boldText = showError ? self.kErrorSubtitleBold : self.kWelcomeSubtitleBold
        self.subtitleLabel.attributedText = String.getAttributedText(string: text, boldStrings: [boldText], font: normalFont, boldFont: boldFont)
    }
}
