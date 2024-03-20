//
//  ConnectionCodeSignupHandling.swift
//  sphinx
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import Foundation


protocol ConnectionCodeSignupHandling: UIViewController, SphinxOnionConnectorDelegate {
    var userData: UserData { get }
    var onionConnector: SphinxOnionConnector { get }
    var generateTokenRetries: Int { get set }
    var generateTokenSuccess : Bool {get set}
    var hasAdminRetries : Int {get set}
    
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
    
    func signUp(withSwarmConnectCode connectionCode:String){
        presentConnectingLoadingScreenVC()
        
        let splitString = connectionCode.components(separatedBy: "::")
        if splitString.count > 2{
            let ip = splitString[1]
            let pubKey = splitString[2]
            self.connectToNode(ip: ip, pubkey: pubKey)
        }
        else{
            self.handleSignupConnectionError(
                message: "signup.error-validation-invite-code".localized
            )
        }
    }
    
    func signUp(withSwarmMqttCode connectionCode:String){
        if let url = URL(string: connectionCode),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            
            if let mqtt = queryItems.first(where: { $0.name == "mqtt" })?.value,
               let network = queryItems.first(where: { $0.name == "network" })?.value,
               let relay = queryItems.first(where: { $0.name == "relay" })?.value
            {
                self.connectToSwarm(
                    mqtt: mqtt,
                    network: network,
                    relay: relay
                )
            }

        }
    }
    
    func signUp(withSwarmClaimCode connectionCode:String){
        presentConnectingLoadingScreenVC()
        
        let splitString = connectionCode.components(separatedBy: "::")
        if splitString.count > 2, let token = splitString[2].base64Decoded {
            
            let ip = splitString[1]
            self.userData.save(ip: ip)
            
            userData.continueWithToken(
                token: token,
                completion: { [weak self] in
                    guard let self = self else { return }
                    
                    self.proceedToNewUserWelcome()
                },
                errorCompletion: { [weak self] in
                    guard let self = self else { return }
                    
                    self.handleSignupConnectionError(
                        message: "signup.error-validation-invite-code".localized
                    )
                }
            )
        } else {
            self.handleSignupConnectionError(
                message: "signup.error-validation-invite-code".localized
            )
        }
    }
    
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
    
    func signup_v2_with_test_server(){
        presentConnectingLoadingScreenVC()
    }
    
    func finalizeSignup(){
        let som = SphinxOnionManager.sharedInstance
        if //let _ = som.currentServer,
           let contact = som.pendingContact,
           contact.isOwner == true{
            if let vc = self as? NewUserSignupFormViewController{
                vc.isV2 = true
            }
            som.isV2InitialSetup = true
            self.proceedToNewUserWelcome()
        }
        else{
            self.navigationController?.popViewController(animated: true)
            AlertHelper.showAlert(title: "Error", message: "Unable to connect to Sphinx V2 Test Server")
        }
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
                self.generateTokenSuccess = true
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
        if generateTokenRetries < 4  && generateTokenSuccess == false{
            DelayPerformedHelper.performAfterDelay(seconds: 0.5) { [weak self] in
                self?.generateTokenAndProceed(pubkey: pubkey, token: token, password: password)
            }
        } else {
            handleSignupConnectionError(message: "signup.error-generating-token".localized)
        }
    }
    
    
    func presentConnectingLoadingScreenVC() {
        let connectingVC = RestoreUserConnectingViewController.instantiate()
        
        navigationController?.pushViewController(
            connectingVC,
            animated: true
        )
    }
    
    func connectToSwarm(
        mqtt: String,
        network: String,
        relay: String
    ) {
        let hwl = CrypterManager.HardwareLink(
            mqtt: mqtt,
            network: network,
            relay: relay
        )
        
        UserData.sharedInstance.save(ip: "https://\(relay)")
        
        CrypterManager.sharedInstance.setupSigningDevice(
            vc: self,
            hardwareLink: hwl
        ) { _ in
            self.presentConnectingLoadingScreenVC()
            self.hasAdminRetries = 0
            
            self.checkForAdmin() {
                self.postToGenerateToken {
                    UserDefaults.Keys.setupPhoneSigner.set(true)
                }
            }
        }
        
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
                inviter: inviter
            )
            if let vc = self as? NewUserSignupFormViewController{
                inviteWelcomeVC.isV2 = vc.isV2
            }
            self.navigationController?.pushViewController(inviteWelcomeVC, animated: true)
        }
    }
    
    func checkForAdmin(completion: @escaping ()->()) {
        if hasAdminRetries < 50 {
            hasAdminRetries += 1
            
            API.sharedInstance.getHasAdmin(completionHandler: { result in
                switch result {
                case .success(let success):
                    success ? completion() : DelayPerformedHelper.performAfterDelay(seconds: 2.0, completion: {
                        self.checkForAdmin(completion: completion)
                    })
                case .failure(_):
                    DelayPerformedHelper.performAfterDelay(seconds: 2.0, completion: {
                        self.checkForAdmin(completion: completion)
                    })
                }
            })
        } else {
            AlertHelper.showAlert(title: "signup.setup-swarm-admin-error-title".localized, message: "signup.setup-swarm-admin-error-prompt".localized)
        }
    }
    
    func postToGenerateToken(callback: @escaping ()->()){
        do {
            let (mneomnic, _) = CrypterManager.sharedInstance.getOrCreateWalletMnemonic()
            let network = CrypterManager.sharedInstance.hardwarePostDto.bitcoinNetwork ?? ""
            let keys = try nodeKeys(net: network, seed: mnemonicToSeed(mnemonic: mneomnic))
            
            self.generateTokenAndProceed(
                pubkey: keys.pubkey,
                password: nil
            )
            
            callback()
        } catch {
            print("catch statement in postToGenerateToken with error: \(error)")
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
