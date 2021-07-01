//
//  InviteCodeViewControllerExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 26/04/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import UIKit

extension InviteCodeViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        nextButtonTouched()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentString = textField.text! as NSString
        let newString = currentString.replacingCharacters(in: range, with: string) as NSString
        
        messageBubbleHelper.hideGenericMessage()
        
        if (newString as String) == UIPasteboard.general.string {
            let _ = validateCode(code: newString as String)
        }
        return true
    }
    
    func validateCode(code: String) -> Bool {
        messageBubbleHelper.genericMessageY = 60
        
        if code.isRelayQRCode {
            return true
        } else if code.isRestoreKeysString || code.fixedRestoreCode.isRestoreKeysString {
            return true
        } else if code.isInviteCode {
            return true
        }
        
        if code.isPubKey {
            messageBubbleHelper.showGenericMessageView(text: "invalid.code.pubkey".localized, delay: 10, textColor: UIColor.white, backColor: UIColor.Sphinx.BadgeRed, backAlpha: 1.0)
            return false
        } else if code.isLNDInvoice {
            messageBubbleHelper.showGenericMessageView(text: "invalid.code.invoice".localized, delay: 10, textColor: UIColor.white, backColor: UIColor.Sphinx.BadgeRed, backAlpha: 1.0)
            return false
        }

        let invalidCodeMessage = (code.isRestoreKeysStringLength ? "wrong.restore.string" : "invalid.code").localized
        messageBubbleHelper.showGenericMessageView(text: invalidCodeMessage, delay: 10, textColor: UIColor.white, backColor: UIColor.Sphinx.BadgeRed, backAlpha: 1.0)
        return false
    }
}

extension InviteCodeViewController : MenuDelegate {
    func shouldOpenLeftMenu() {
        if let drawer = rootViewController?.getDrawer() {
            drawer.setDrawerState(.opened, animated: true)
        }
    }
}

extension InviteCodeViewController : QRCodeScannerDelegate, KeychainRestoreDelegate {
    func didScanQRCode(string: String) {
        inviteCodeTextField.text = string
        nextButtonTouched()
    }
    
    func isNodeConnectQR(string: String) -> Bool {
        let (ip, password) = string.getIPAndPassword()
        if let ip = ip, let password = password {
            connectToNode(ip: ip, password: password)
            return true
        }
        return false
    }
    
    func connectToNode(ip: String, password: String) {
        loading = true
        save(ip: ip, and: password)
        
        if connectTorIfNeeded() {
            return
        }

        let invite = SignupHelper.getDefaultInviter()
        SignupHelper.saveInviterInfo(invite: invite)
        self.generateTokenAndProceed(pubkey: "", password: password)
    }
    
    func save(ip: String, and password: String) {
        userData.save(ip: ip)
        userData.save(password: password)
    }
    
    func isRestoreQR(string: String) -> Bool {
        if let encryptedKeys = string.getRestoreKeys() {
            presentPINVC(encryptedKeys: encryptedKeys)
            return true
        }
        return false
    }
    
    func presentPINVC(encryptedKeys: String) {
        UserDefaults.Keys.defaultPIN.removeValue()
        
        let pinCodeVC = PinCodeViewController.instantiate()
        pinCodeVC.doneCompletion = { pin in
            pinCodeVC.dismiss(animated: true, completion: {
                self.restore(encryptedKeys: encryptedKeys, with: pin)
            })
        }
        self.present(pinCodeVC, animated: true)
    }
    
    func restore(encryptedKeys: String, with pin: String) {
        loading = true
        
        if let keys = SymmetricEncryptionManager.sharedInstance.decryptRestoreKeys(encryptedKeys: encryptedKeys.fixedRestoreCode, pin: pin) {
            if EncryptionManager.sharedInstance.insertKeys(privateKey: keys[0], publicKey: keys[1]) {
                self.userData.save(ip: keys[2], token: keys[3], andPin: pin)
                
                UserDefaults.Keys.didJustRestore.set(true)
                goToApp()
                return
            }
        }
        errorRestoring(message: "invalid.pin".localized)
    }
    
    func goToApp() {
        if connectTorIfNeeded() {
            return
        }
        
        SignupHelper.completeSignup()
        UserDefaults.Keys.lastPinDate.set(Date())
        
        let mainCoordinator = MainCoordinator(rootViewController: rootViewController)
        mainCoordinator.presentInitialDrawer()
    }
    
    func errorRestoring(message: String) {
        loading = false
        NewMessageBubbleHelper().showGenericMessageView(text: message)
    }
    
    func willDismiss() {
        self.keychainRestoreContainer.alpha = self.userData.isRestoreAvailable() ? 1.0 : 0.0
    }
}

extension InviteCodeViewController : SphinxOnionConnectorDelegate {
    func onionConnecting() {
        loadingWheelLabel.text = "establishing.tor.circuit".localized
    }
    
    func connectTorIfNeeded() -> Bool {
        if onionConnector.usingTor() && !onionConnector.isReady() {
            loadingWheelLabel.text = "establishing.tor.circuit".localized
            onionConnector.startTor(delegate: self)
            return true
        }
        return false
    }
    
    func onionConnectionFinished() {
        let restoring = UserDefaults.Keys.didJustRestore.get(defaultValue: false)
        
        if restoring {
            goToApp()
        } else {
            loadingWheelLabel.text = "wait.tor.request".localized
            
            let ip = userData.getNodeIP()
            let password = userData.getPassword()
            connectToNode(ip: ip, password: password)
        }
    }
    
    func onionConnectionFailed() {
        errorRestoring(message: "tor.connection.failed".localized)
    }
}
