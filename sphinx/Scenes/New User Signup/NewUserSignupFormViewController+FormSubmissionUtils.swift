//
//  NewUserSignupFormViewController+FormSubmissionUtils.swift
//  sphinx
//
//  Created by Brian Sipple on 6/22/21.
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit


extension NewUserSignupFormViewController {
    
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        handleSubmit()
    }
    
    @IBAction func qrCodeButtonTapped() {
        let viewController = NewQRScannerViewController.instantiate()
        
        viewController.currentMode = NewQRScannerViewController.Mode.ScanAndDismiss
        viewController.delegate = self
        
        present(viewController, animated: true)
    }
}
    

extension NewUserSignupFormViewController {

    func handleSubmit() {
        guard
            let code = codeTextField.text,
            code.isEmpty == false
        else { return }

        guard validateCode(code) else { return }

        view.endEditing(true)
        
        startSignup(with: code)
    }
    
    
    func startSignup(with code: String) {
        if code.isRelayQRCode {
            let (ip, password) = code.getIPAndPassword()
            
            if let ip = ip, let password = password {
                signupWithRelayQRCode(ip: ip, password: password)
            }
        } else if code.isInviteCode {
            signupWithInviteCode(code)
        } else {
            preconditionFailure("Attempted to start sign up without a valid code.")
        }
    }
    
    
    func isCodeValid(_ code: String) -> Bool {
        code.isRelayQRCode || code.isInviteCode
    }
    
    
    func validateCode(_ code: String) -> Bool {
        if isCodeValid(code) {
            return true
        } else {
            var errorMessage: String
            
            if code.isRestoreKeysString {
                errorMessage = "signup.invalid-code.restore-key".localized
            } else if code.isPubKey {
                errorMessage = "invalid.code.pubkey".localized
            } else if code.isLNDInvoice {
                errorMessage = "invalid.code.invoice".localized
            } else {
                errorMessage = "invalid.code".localized
            }
            
            newMessageBubbleHelper.showGenericMessageView(
                text: errorMessage,
                delay: 6,
                textColor: UIColor.white,
                backColor: UIColor.Sphinx.BadgeRed,
                backAlpha: 1.0
            )
            
            return false
        }
    }
    
    func signupWithRelayQRCode(ip: String, password: String) {
        presentConnectingLoadingScreenVC()
        
        let invite = SignupHelper.getDefaultInviter()
        SignupHelper.saveInviterInfo(invite: invite)
        
        connectToNode(ip: ip, password: password)
    }
    
    
    func signupWithInviteCode(_ code: String) {
        presentConnectingLoadingScreenVC()
        
        API.sharedInstance.signupWithCode(
            inviteString: code,
            callback: { [weak self] (invite, ip, pubkey) in
                guard let self = self else { return }
                
                SignupHelper.saveInviterInfo(invite: invite, code: code)
            
                self.connectToNode(ip: ip, pubkey: pubkey)
            },
            errorCallback: { [weak self] in
                guard let self = self else { return }
            
                // TODO: Compute (and localize) the right  message here
                self.handleSignupError(message: "An error occurred while validating the invite code.")
            }
        )
    }
    
    
    func generateTokenAndProceed(pubkey: String, password: String? = nil) {
        let token = EncryptionManager.randomString(length: 20)
        
        generateTokenAndProceed(pubkey: pubkey, token: token, password: password)
    }
    
    
    func generateTokenAndProceed(pubkey: String, token: String, password: String? = nil) {
        generateTokenRetries += 1

        API.sharedInstance.generateToken(
            token: token,
            pubkey: pubkey,
            password: password,
            callback: { [weak self] success in
                guard let self = self else { return }
            
                if success {
                    self.userData.save(authToken: token)
                    self.proceedToNewUserWelcome()
                } else {
                    self.generateTokenError(pubkey: pubkey, token: token, password: password)
                }
            },
            errorCallback: { [weak self] in
                guard let self = self else { return }
                
                self.generateTokenError(pubkey: pubkey, token: token, password: password)
            }
        )
    }
    
    
    func generateTokenError(pubkey: String, token: String, password: String? = nil) {
        if generateTokenRetries < 4 {
            DelayPerformedHelper.performAfterDelay(seconds: 0.5) { [weak self] in
                self?.generateTokenAndProceed(pubkey: pubkey, token: token, password: password)
            }
        } else {
            // TODO: Compute (and localize) the right  message here
            handleSignupError(message: "An error occurred while generating a token for this invite code.")
        }
    }
  

    func proceedToNewUserWelcome() {
        guard let inviter = SignupHelper.getInviter() else {
            let defaultInviter = SignupHelper.getDefaultInviter()

            SignupHelper.saveInviterInfo(invite: defaultInviter)
            
            proceedToNewUserWelcome()
            return
        }
        
        SignupHelper.step = SignupHelper.SignupStep.IPAndTokenSet.rawValue
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }

            let inviteWelcomeVC = InviteWelcomeViewController.instantiate(
                rootViewController: self.rootViewController,
                inviter: inviter
            )

            self.navigationController?.pushViewController(inviteWelcomeVC, animated: true)
        }
    }
    
    
    func presentConnectingLoadingScreenVC() {
        let connectingVC = RestoreUserConnectingViewController.instantiate(
            rootViewController: rootViewController
        )
        
        navigationController?.pushViewController(
            connectingVC,
            animated: true
        )
    }
    
    
    func isNodeConnectQR(string: String) -> Bool {
        let (ip, password) = string.getIPAndPassword()
        
        return ip != nil && password != nil
    }
    
    func connectToNode(ip: String, password: String = "", pubkey: String = "") {
        save(ip: ip, and: password)
        
        if connectTorIfNeededBeforeProceeding() {
            return
        }
        
        generateTokenAndProceed(pubkey: pubkey, password: password)
    }
    
    
    func connectTorIfNeededBeforeProceeding() -> Bool {
        if onionConnector.usingTor() && !onionConnector.isReady() {
            onionConnector.startTor(delegate: self)
            return true
        } else {
            return false
        }
    }
    
    
    func save(ip: String, and password: String) {
        userData.save(ip: ip)
        userData.save(password: password)
    }
    
    
    func handleSignupError(message: String) {
        navigationController?.popViewController(animated: true)
        SignupHelper.resetInviteInfo()
        codeTextField.text = ""
        newMessageBubbleHelper.showGenericMessageView(text: message)
    }
}


extension NewUserSignupFormViewController: QRCodeScannerDelegate {
    
    func didScanQRCode(string: String) {
        codeTextField.text = string
        
        handleSubmit()
    }
}


extension NewUserSignupFormViewController: SphinxOnionConnectorDelegate {
    func onionConnecting() {}
    
    func onionConnectionFinished() {
        let ip = userData.getNodeIP()
        let password = userData.getPassword()
        
        connectToNode(ip: ip, password: password)
    }
    
    func onionConnectionFailed() {
        handleSignupError(message: "tor.connection.failed".localized)
    }
}
