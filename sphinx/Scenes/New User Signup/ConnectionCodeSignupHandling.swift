//
//  ConnectionCodeSignupHandling.swift
//  sphinx
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit



protocol ConnectionCodeSignupHandling: UIViewController, SphinxOnionConnectorDelegate {
    var userData: UserData { get }
    var onionConnector: SphinxOnionConnector { get }
    var generateTokenRetries: Int { get set }
    var rootViewController: RootViewController! { get set }
    
    func signup(withConnectionCode connectionCode: String)
    
    func generateTokenAndProceed(
        pubkey: String,
        password: String?
    )
    
    func generateTokenAndProceed(
        pubkey: String,
        token: String,
        password: String?
    )
    
    func generateTokenError(
        pubkey: String,
        token: String,
        password: String?
    )
    
    func presentConnectingLoadingScreenVC()

    func connectToNode(
        ip: String,
        password: String,
        pubkey: String
    )

    func connectTorIfNeededBeforeProceeding() -> Bool

    func save(
        ip: String,
        and password: String
    )

    func handleSignupConnectionError(message: String)

    func proceedToNewUserWelcome()
}


// MARK: - Default Properties
extension ConnectionCodeSignupHandling {
    var userData: UserData { .sharedInstance }
    var onionConnector: SphinxOnionConnector { .sharedInstance }
}


// MARK: - Default Method Implementations
extension ConnectionCodeSignupHandling {
    
    func signup(withConnectionCode connectionCode: String) {
        presentConnectingLoadingScreenVC()
        
        API.sharedInstance.signupWithCode(
            inviteString: connectionCode,
            callback: { [weak self] (invite, ip, pubkey) in
                guard let self = self else { return }
                
                SignupHelper.saveInviterInfo(invite: invite, code: connectionCode)
            
                self.connectToNode(ip: ip, pubkey: pubkey)
            },
            errorCallback: { [weak self] in
                guard let self = self else { return }
            
                // TODO: Compute (and localize) the right  message here
                self.handleSignupConnectionError(
                    message: "signup.error-validation-invite-code".localized
                )
            }
        )
    }
    
    
    func generateTokenAndProceed(pubkey: String, password: String? = nil) {
        let token = EncryptionManager.randomString(length: 20)
        
        generateTokenAndProceed(pubkey: pubkey, token: token, password: password)
    }
    
    
    func generateTokenAndProceed(pubkey: String, token: String, password: String? = nil) {
        generateTokenRetries += 1
        
        userData.generateToken(
            token: token,
            pubkey: pubkey,
            password: password,
            completion: { [weak self] in
                guard let self = self else { return }
                
                self.proceedToNewUserWelcome()
            },
            errorCompletion: { [weak self] in
                guard let self = self else { return }
                
                self.generateTokenError(pubkey: pubkey, token: token, password: password)
            }
        )
    }
    
    
    func generateTokenError(
        pubkey: String,
        token: String,
        password: String? = nil
    ) {
        if generateTokenRetries < 4 {
            DelayPerformedHelper.performAfterDelay(seconds: 0.5) { [weak self] in
                self?.generateTokenAndProceed(pubkey: pubkey, token: token, password: password)
            }
        } else {
            handleSignupConnectionError(message: "signup.error-generating-token".localized)
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
    
    
    func proceedToNewUserWelcome() {
        guard let inviter = SignupHelper.getInviter() else {
            
            let defaultInviter = SignupHelper.getSupportContact(includePubKey: false)
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
}


// MARK: - Default `SphinxOnionConnectorDelegate` methods
extension ConnectionCodeSignupHandling {
    
    func onionConnecting() {}
    
    func onionConnectionFinished() {
        let ip = userData.getNodeIP()
        let password = userData.getPassword()
        
        connectToNode(ip: ip, password: password)
    }
    
    func onionConnectionFailed() {
        handleSignupConnectionError(message: "tor.connection.failed".localized)
    }
}
