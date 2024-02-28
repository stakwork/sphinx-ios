//
//  NewUserSignupFormViewController+FormSubmissionUtils.swift
//  sphinx
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit


extension NewUserSignupFormViewController {
    
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        handleSubmit()
    }
    
    @IBAction func qrCodeButtonTapped() {
        let viewController = NewQRScannerViewController.instantiate(
            currentMode: NewQRScannerViewController.Mode.ScanAndDismiss
        )
        viewController.delegate = self
        
        present(viewController, animated: true)
    }
    
    @IBAction func connectToTestServer(){
        print("connecting to test server")
        let som = SphinxOnionManager.sharedInstance
        som.vc = self
        som.shouldPostUpdates = true
        //som.chooseImportOrGenerateSeed()
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
        
        if(code.isV2InviteCode){
            SphinxOnionManager.sharedInstance.vc = self
            SphinxOnionManager.sharedInstance.chooseImportOrGenerateSeed(completion: {success in
                if(success){
                    SphinxOnionManager.sharedInstance.redeemInvite(inviteCode: code, completion: { rr in
                        if let mnemonic = UserData.sharedInstance.getMnemonic(),
                           let rr = rr,
                           SphinxOnionManager.sharedInstance.createMyAccount(mnemonic: mnemonic){
                            SphinxOnionManager.sharedInstance.handleRunReturn(rr: rr)
                            self.signup_v2_with_test_server()
                        }
                        SphinxOnionManager.sharedInstance.vc = nil
                    })
                }
            })
        }
        else{
            startSignup(with: code)
        }
    }
    
    
    func startSignup(with code: String) {
        if code.isRelayQRCode {
            let (ip, password) = code.getIPAndPassword()
            
            if let ip = ip, let password = password {
                signupWithRelayQRCode(ip: ip, password: password)
            }
        } else if code.isInviteCode {
            signup(withConnectionCode: code)
        }
        else if code.isSwarmConnectCode{
            signUp(withSwarmConnectCode: code)
        }
        else if code.isSwarmClaimCode{
            signUp(withSwarmClaimCode: code)
        }
        else if code.isSwarmGlyphAction{
            signUp(withSwarmMqttCode: code)
        }
        else {
            preconditionFailure("Attempted to start sign up without a valid code.")
        }
    }
    
    
    func isCodeValid(_ code: String) -> Bool {
        return code.isRelayQRCode || code.isInviteCode || code.isSwarmClaimCode || code.isSwarmConnectCode || code.isSwarmGlyphAction
    }
    //sphinx.chat://?action=invite&d=EMxQifHIEKUzDUkq3TrkIbvIoFMxaKClqy_Fd5YVUNQCJKxcE6wCunsStg4GYXEZUuNxl23z5d6QJHd3q51wgzkCrczX9XTRfWJ1QbRH9HSTkW544zwVg7qZNmB7NcqZw5IHWiAACF0ABDM0LjIyOS41Mi4yMDA=
    
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
        
        let invite = SignupHelper.getSupportContact(includePubKey: false)
        SignupHelper.saveInviterInfo(invite: invite)
        
        connectToNode(ip: ip, password: password)
    }
    
    
    func handleSignupConnectionError(message: String) {
        // Pop the "Connecting" VC
        navigationController?.popViewController(animated: true)

        SignupHelper.resetInviteInfo()

        codeTextField.text = ""
        newMessageBubbleHelper.showGenericMessageView(text: message)
    }
}


extension NewUserSignupFormViewController: QRCodeScannerDelegate {
    
    func didScanQRCode(string: String) {
        codeTextField.text = string
        
        textFieldDidEndEditing(codeTextField)
        
        handleSubmit()
    }
}
