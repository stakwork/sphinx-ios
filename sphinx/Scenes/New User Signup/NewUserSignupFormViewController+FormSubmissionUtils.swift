//
//  NewUserSignupFormViewController+FormSubmissionUtils.swift
//  sphinx
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import CoreData


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
                if(success),
                  let code = self.codeTextField.text{
                    self.handleInviteCodeV2SignUp(code: code)
                }
                else{
                    AlertHelper.showAlert(title: "Error redeeming invite", message: "Please try again or ask for another invite.")
                }
                SphinxOnionManager.sharedInstance.vc = nil
            })
        }
        else{
            startSignup(with: code)
        }
    }
    
    func handleInviteCodeV2SignUp(code:String){
        if let mnemonic = UserData.sharedInstance.getMnemonic(),
           SphinxOnionManager.sharedInstance.createMyAccount(mnemonic: mnemonic){
            SphinxOnionManager.sharedInstance.redeemInvite(inviteCode: code)
            setupWatchdogTimer()
            listenForSelfContactRegistration()//get callbacks ready for sign up
            self.signup_v2_with_test_server()
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


extension NewUserSignupFormViewController : NSFetchedResultsControllerDelegate{
    
    
    private func listenForSelfContactRegistration() {
            let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext

            let fetchRequest: NSFetchRequest<UserContact> = UserContact.fetchRequest()
            // Assuming 'isOwner' and 'routeHint' are attributes of your UserContact entity
            fetchRequest.predicate = NSPredicate(format: "isOwner == true AND routeHint != nil")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
            
            selfContactFetchListener = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: managedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
            selfContactFetchListener?.delegate = self

            do {
                try selfContactFetchListener?.performFetch()
                // Check if we already have the desired data
                if let _ = selfContactFetchListener?.fetchedObjects?.first {
                    watchdogTimer?.invalidate()
                    watchdogTimer = nil
                    finalizeSignup()
                    self.selfContactFetchListener = nil
                }
            } catch let error as NSError {
                watchdogTimer?.invalidate()
                self.selfContactFetchListener = nil
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            // Called when the content of the fetchedResultsController changes.
            if let _ = controller.fetchedObjects?.first {
                finalizeSignup()
                self.selfContactFetchListener = nil
                watchdogTimer?.invalidate()
                watchdogTimer = nil
            }
        }
    
    private func setupWatchdogTimer() {
            watchdogTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                
                // Check if the fetch result is still nil
                if self.selfContactFetchListener?.fetchedObjects?.first == nil {
                    // Perform the fallback action
                    DispatchQueue.main.async {
                        self.navigationController?.popViewController(animated: true)
                        AlertHelper.showAlert(title: "Error", message: "Unable to connect to Sphinx V2 Test Server")
                    }
                }
            }
        }
}
