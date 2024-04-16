//
//  NewContactDelegatesExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/12/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

extension NewContactViewController {
    func updateProfile() {
        guard let contact = contact else {
            return
        }
        
        let routeHint = routeHintTextField.text ?? ""
        
        if !routeHint.isEmpty && !routeHint.isRouteHint && !routeHint.isV2RouteHint {
            showErrorAlert(message: "invalid.route.hint".localized)
        } else if let nickname = nickNameTextField.text, contact.id > 0 && nickname != "", nickname != contact.nickname {
            UserContactsHelper.updateContact(contact: contact, nickname: nickname, routeHint: routeHintTextField.text, callback: { success in
                self.loading = false

                if success {
                    self.delegate?.shouldReloadContacts?(reload: true, dashboardTabIndex: -1)
                    self.backButtonTouched()
                } else {
                    self.showErrorAlert(message: "generic.error.message".localized)
                }
            })
        } else {
            backButtonTouched()
        }
    }
    
    func createV2Contact(){
        let nickname = nickNameTextField.text ?? ""
        let pubkey = addressTextField.text ?? ""
        let routeHint = routeHintTextField.text ?? ""
        
        if !pubkey.isEmpty && !pubkey.isPubKey {
            showErrorAlert(message: "invalid.pubkey".localized)
        } else if !routeHint.isEmpty && !routeHint.isV2RouteHint {
            showErrorAlert(message: "invalid.route.hint".localized)
        } else if nickname.isEmpty || pubkey.isEmpty {
            showErrorAlert(message: "nickname.address.required".localized)
        } else {
            let pin = groupPinContainer.getPin()
            UserContactsHelper().createV2Contact(nickname: nickname, pubKey: pubkey, routeHint: routeHint,pin: pin, callback: { (success, _) in
                self.loading = false
                
                if success {
                    self.delegate?.shouldReloadContacts?(reload: true, dashboardTabIndex: 1)
                    self.closeButtonTouched()
                } else {
                    self.showErrorAlert(message: "generic.error.message".localized)
                }
            })
        }
    }
   
    func createContact() {
        let nickname = nickNameTextField.text ?? ""
        let pubkey = addressTextField.text ?? ""
        let routeHint = routeHintTextField.text ?? ""
        
        if !pubkey.isEmpty && !pubkey.isPubKey {
            showErrorAlert(message: "invalid.pubkey".localized)
        } else if !routeHint.isEmpty && !routeHint.isRouteHint && !routeHint.isV2RouteHint {
            showErrorAlert(message: "invalid.route.hint".localized)
        } else if nickname.isEmpty || pubkey.isEmpty {
            showErrorAlert(message: "nickname.address.required".localized)
        } else {
            let pin = groupPinContainer.getPin()
            UserContactsHelper.createContact(nickname: nickname, pubKey: pubkey, routeHint: routeHint, pin: pin, callback: { (success, _) in
                self.loading = false

                if success {
                    self.delegate?.shouldReloadContacts?(reload: true, dashboardTabIndex: 1)
                    self.closeButtonTouched()
                } else {
                    self.showErrorAlert(message: "generic.error.message".localized)
                }
            })
        }
    }
    
    func showErrorAlert(message: String) {
        loading = false
        AlertHelper.showAlert(title: "generic.error.title".localized, message: message)
    }
}

extension NewContactViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        validateFields()
        view.endEditing(true)
        return true
    }
    
    func validateFields() {
        if let nickName = nickNameTextField.text, nickName == "" {
            saveEnabled = false
            return
        }
        saveEnabled = true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentString = textField.text! as String
        let newString = (currentString as NSString).replacingCharacters(in: range, with: string) as String
        if newString.isVirtualPubKey {
            DelayPerformedHelper.performAfterDelay(seconds: 0.3, completion: {
                self.completePubkeyComponents(newString)
            })
        }
        else if let parsedContact = SphinxOnionManager.sharedInstance.parseContactInfoString(fullContactInfo: newString){
            DelayPerformedHelper.performAfterDelay(seconds: 0.3, completion: {
                self.addressTextField.text = parsedContact.0
                self.routeHintTextField.text = parsedContact.1 + "_" + parsedContact.2
                self.routeHintTextField.becomeFirstResponder()
            })
        }
        return true
    }
    
    func completePubkeyComponents(_ string: String) {
        let (pubkey, routeHint) = string.pubkeyComponents
        addressTextField.text = pubkey
        routeHintTextField.text = routeHint
        routeHintTextField.becomeFirstResponder()
    }
}

extension NewContactViewController : QRCodeScannerDelegate {
    func didScanQRCode(string: String) {
        if string.isVirtualPubKey {
            completePubkeyComponents(string)
        } else if string.isPubKey {
            addressTextField.text = string
        }
    }
}

extension NewContactViewController : SubscriptionFormDelegate {
    func shouldUpdate(contact: UserContact?) {
        if let contactId = contact?.id {
            self.contact = UserContact.getContactWith(id: contactId)
            shouldRealodChat = true
        }
    }
}

