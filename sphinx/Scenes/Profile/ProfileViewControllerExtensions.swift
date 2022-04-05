//
//  ProfileViewControllerExtensions.swift
//  sphinx
//
//  Created by Tomas Timinskas on 06/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

extension ProfileViewController {
    func shouldChangePIN() {
        let pinCodeVC = SetPinCodeViewController.instantiate(rootViewController: rootViewController, mode: SetPinCodeViewController.SetPinMode.Change)
        pinCodeVC.doneCompletion = { pin in
            pinCodeVC.dismiss(animated: true, completion: {
                if pin == UserData.sharedInstance.getPrivacyPin() {
                    AlertHelper.showAlert(title: "generic.error.title".localized, message: "pins.must.be.different".localized)
                    return
                }
                AlertHelper.showTwoOptionsAlert(title: "pin.change".localized, message: "confirm.pin.change".localized, confirm: {
                    GroupsPinManager.sharedInstance.didUpdateStandardPin(newPin: pin)
                    self.newMessageBubbleHelper.showGenericMessageView(
                        text: "pin.changed".localized,
                        delay: 6,
                        textColor: UIColor.white,
                        backColor: UIColor.Sphinx.PrimaryGreen,
                        backAlpha: 1.0
                    )
                })
            })
        }
        self.present(pinCodeVC, animated: true)
    }
    
    func shouldChangePrivacyPIN() {
        let isPrivacyPinSet = GroupsPinManager.sharedInstance.isPrivacyPinSet()
        let mode: SetPinCodeViewController.SetPinMode = isPrivacyPinSet ? .Change : .Set
        let pinCodeVC = SetPinCodeViewController.instantiate(rootViewController: rootViewController, mode: mode, pinMode: .Privacy, subtitle: "")
        pinCodeVC.doneCompletion = { pin in
            pinCodeVC.dismiss(animated: true, completion: {
                if pin == UserData.sharedInstance.getAppPin() {
                    AlertHelper.showAlert(title: "generic.error.title".localized, message: "pins.must.be.different".localized)
                    return
                }
                AlertHelper.showTwoOptionsAlert(title: "pin.change".localized, message: "confirm.privacy.pin.change".localized, confirm: {
                    GroupsPinManager.sharedInstance.didUpdatePrivacyPin(newPin: pin)
                    self.privacyPinLabel.text = "change.privacy.pin".localized
                    let alertLabel = (isPrivacyPinSet ? "privacy.pin.changed" : "privacy.pin.set").localized
                    
                    self.newMessageBubbleHelper.showGenericMessageView(
                        text: alertLabel,
                        delay: 6,
                        textColor: UIColor.white,
                        backColor: UIColor.Sphinx.PrimaryGreen,
                        backAlpha: 1.0
                    )
                })
            })
        }
        self.present(pinCodeVC, animated: true)
    }
}

extension ProfileViewController : UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        currentField = textField
        previousFieldValue = textField.text
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            if textField.tag == ProfileFields.RelayUrl.rawValue {
                updateRelayURL()
                return true
            }
            
            if textField.tag == ProfileFields.Name.rawValue {
                setFieldsAfterEdit()
                return true
            }
            
            if textField.tag == ProfileFields.MeetingPmtAmt.rawValue {
                if let value = Int(text) {
                    UserContact.kTipAmount = value
                }
                setFieldsAfterEdit()
                return true
            }
            
            if text.isValidURL {
                switch (textField.tag) {
                case ProfileFields.InvitesServer.rawValue:
                    API.kHUBServerUrl = text
                    break
                case ProfileFields.MemesServer.rawValue:
                    API.kAttachmentsServerUrl = text
                    break
                case ProfileFields.VideoCallServer.rawValue:
                    API.kVideoCallServer = text
                    break
                default:
                    break
                }
            }
        }
        setFieldsAfterEdit()
        return true
    }
    
    func setFieldsAfterEdit() {
        updateProfile()
        configureServers()
        view.endEditing(true)
    }
    
    func shouldRevertValue() {
        if let currentField = currentField, let previousFieldValue = previousFieldValue, previousFieldValue != "" {
            currentField.text = previousFieldValue
        }
    }
    
    func updateProfile(photoUrl: String? = nil) {
        if let profile = UserContact.getOwner() {
            if profile.id < 0 {
                return
            }
            
            let nickname = profile.nickname ?? ""
            let privatePhoto = profile.privatePhoto
            
            let updatedName = nameTextField.text ?? nickname
            let updatedPrivatePhoto = !sharePhotoSwitch.isOn
            
            if nickname == updatedName && privatePhoto == updatedPrivatePhoto && photoUrl == nil {
                return
            }
            
            var parameters = [String : AnyObject]()
            parameters["alias"] = updatedName as AnyObject?
            parameters["private_photo"] = updatedPrivatePhoto as AnyObject?
            
            if let photoUrl = photoUrl, !photoUrl.isEmpty {
                parameters["photo_url"] = photoUrl as AnyObject?
            }
            
            API.sharedInstance.updateUser(id: profile.id, params: parameters, callback: { contact in
                let _ = self.contactsService.insertContact(contact: contact)
                self.configureProfile()
            }, errorCallback: {
                self.configureProfile()
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
            })
        }
    }
}

extension ProfileViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let chosenImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            dismiss(animated:true, completion: {
                self.profileImageView.image = chosenImage
                self.profileImageView.contentMode = .scaleAspectFill
                self.uploadImage(image: chosenImage)
            })
        }
    }
    
    func uploadImage(image: UIImage) {
        let fixedImage = image.fixedOrientation()
        
        if let profile = UserContact.getOwner(), profile.id > 0, let imgData = fixedImage.jpegData(compressionQuality: 0.5) {
            uploading = true
            
            let attachmentsManager = AttachmentsManager.sharedInstance
            attachmentsManager.setDelegate(delegate: self)
            
            let attachmentObject = AttachmentObject(data: imgData, type: AttachmentsManager.AttachmentType.Photo)
            attachmentsManager.uploadImage(attachmentObject: attachmentObject, route: "public")
        } else {
            configureProfile()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension ProfileViewController : AttachmentsManagerDelegate {
    func didUpdateUploadProgress(progress: Int) {
        let uploadedMessage = String(format: "uploaded.progress".localized, progress)
        uploadingLabel.text = uploadedMessage
    }
    
    func didSuccessUploadingImage(url: String) {
        if let image = profileImageView.image?.fixedOrientation() {
            MediaLoader.storeImageInCache(img: image, url: url)
        }
        updateProfile(photoUrl: url)
    }
}

extension ProfileViewController : AppearenceViewDelegate {
    func didChangeAppearance() {
        sizeView.setViewBorder()
        settingsTabView.setViewBorder()
    }
}

extension ProfileViewController : SettingsTabsDelegate {
    func didChangeSettingsTab(tag: Int) {
        for tab in tabContainers {
            tab.isHidden = tab.tag != tag
        }
    }
}

extension ProfileViewController : NotificationSoundDelegate {
    func didUpdateSound() {
        configureProfile()
    }
}
