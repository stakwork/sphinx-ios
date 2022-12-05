//
//  RestoreUserFormViewController+FormSubmissionUtils.swift
//  sphinx
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit


extension RestoreUserFormViewController {
    
    func handleSubmit() {
        guard
            let code = codeTextField.text,
            code.isEmpty == false
        else {
            return
        }

        guard validateCode(code) else { return }

        guard let encryptedKeys = encryptedKeysFromCode(code) else { return }
        
        presentPINVC(using: encryptedKeys)
    }
    
    
    func validateCode(_ code: String) -> Bool {
        if isCodeValid(code) {
            return true
        } else {
            handleInvalidCodeSubmission(code)
            
            return false
        }
    }
    
    
    func connectTorIfNeededBeforeProceeding() -> Bool {
        if onionConnector.usingTor() && !onionConnector.isReady() {
            onionConnector.startTor(delegate: self)
            return true
        }
        return false
    }
    
    
    func encryptedKeysFromCode(_ code: String) -> String? {
        code.getRestoreKeys() ??
        code.fixedRestoreCode.getRestoreKeys()
    }

    
    func isCodeValid(_ code: String) -> Bool {
        code.isRestoreKeysString ||
        code.fixedRestoreCode.isRestoreKeysString
    }
    
    
    func presentPINVC(using encryptedKeys: String) {
        UserDefaults.Keys.defaultPIN.removeValue()
        
        let pinCodeVC = PinCodeViewController.instantiate()
        
        pinCodeVC.doneCompletion = { pin in
            pinCodeVC.dismiss(animated: true, completion: { [weak self] in
                guard let self = self else { return }
                
                self.connectRestoredUser(
                    encryptedKeys: encryptedKeys,
                    pin: pin
                )
            })
        }
        
        pinCodeVC.modalPresentationStyle = .overFullScreen
        
        present(pinCodeVC, animated: true)
        
        presentConnectingLoadingScreenVC()
    }


    func connectRestoredUser(
        encryptedKeys: String,
        pin: String
    ) {
        guard
            let keys = SymmetricEncryptionManager
                .sharedInstance
                .decryptRestoreKeys(
                    encryptedKeys: encryptedKeys.fixedRestoreCode,
                    pin: pin
                ),
            EncryptionManager.sharedInstance.insertKeys(privateKey: keys[0], publicKey: keys[1])
        else {
            errorRestoring(message: "invalid.pin".localized)
            return
        }

        userData.save(ip: keys[2], token: keys[3], pin: pin)

        userData.getAndSaveTransportKey(completion: { [weak self] _ in
            guard let self = self else { return }
            
            self.userData.getOrCreateHMACKey() { [weak self] in
                guard let self = self else { return }
                
                self.goToWelcomeCompleteScene()
            }
        })
    }
    
    
    func presentConnectingLoadingScreenVC() {
        let restoreExistingConnectingVC = RestoreUserConnectingViewController.instantiate(
            rootViewController: rootViewController
        )
        
        navigationController?.pushViewController(
            restoreExistingConnectingVC,
            animated: true
        )
    }
    
    
    func goToWelcomeCompleteScene() {
        if connectTorIfNeededBeforeProceeding() {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            let welcomeCompleteVC = WelcomeCompleteViewController.instantiate(
                rootViewController: self.rootViewController
            )
            
            self.navigationController?.pushViewController(
                welcomeCompleteVC,
                animated: true
            )
        }
    }
    
    
    func errorRestoring(message: String) {
        navigationController?.popViewController(animated: true)
        
        newMessageBubbleHelper.showGenericMessageView(text: message)
    }
    
    
    func handleInvalidCodeSubmission(_ code: String) {
        var errorMessage: String
        
        if code.isRelayQRCode {
            errorMessage = "restore.invalid-code.relay-qr-code".localized
        } else if code.isPubKey {
            errorMessage = "invalid.code.pubkey".localized
        } else if code.isLNDInvoice {
            errorMessage = "invalid.code.invoice".localized
        } else {
            errorMessage = "invalid.code".localized
        }
        
        newMessageBubbleHelper.genericMessageY = (
            UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 60
        ) + 60
        
        newMessageBubbleHelper.showGenericMessageView(
            text: errorMessage,
            delay: 6,
            textColor: UIColor.white,
            backColor: UIColor.Sphinx.BadgeRed,
            backAlpha: 1.0
        )
    }
}



extension RestoreUserFormViewController: SphinxOnionConnectorDelegate {
    func onionConnecting() {}
    
    func onionConnectionFinished() {
        goToWelcomeCompleteScene()
    }
    
    func onionConnectionFailed() {
        errorRestoring(message: "tor.connection.failed".localized)
    }
}
