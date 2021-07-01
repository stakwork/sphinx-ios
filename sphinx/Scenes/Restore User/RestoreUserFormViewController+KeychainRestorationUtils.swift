//
//  RestoreUserFormViewController+KeychainRestorationUtils.swift
//  sphinx
//
//  Created by Brian Sipple on 6/17/21.
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit


extension RestoreUserFormViewController {
    
    @IBAction func keychainRestoreButtonTouched() {
        authenticationHelper.authenticationAction(policy: .deviceOwnerAuthentication) { success in
            if success {
                self.goToKeychainRestore()
            }
        }
    }
    
    func goToKeychainRestore() {
        let viewController = KeychainRestoreViewController.instantiate(delegate: self)
        
        present(viewController, animated: true)
    }
}


extension RestoreUserFormViewController: KeychainRestoreDelegate {
    
    func goToApp() {
        goToWelcomeCompleteScene()
    }
    
    func willDismiss() {
        setupKeychainButtonContainer()
    }
}
