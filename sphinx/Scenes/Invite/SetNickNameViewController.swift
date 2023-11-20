//
//  SetNickNameViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/10/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import SwiftyJSON

class SetNickNameViewController: SetDataViewController {
    
    @IBOutlet weak var fieldLabel: UILabel!
    @IBOutlet weak var textFieldContainer: UIView!
    @IBOutlet weak var nickNameField: UITextField!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    var isV2 : Bool = false
    
    static func instantiate() -> SetNickNameViewController {
        let viewController = StoryboardScene.Invite.setNickNameViewController.instantiate()
        return viewController
    }
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.white, view: view)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setStatusBarColor()

        nextButton.isHidden = true
        
        textFieldContainer.layer.cornerRadius = textFieldContainer.frame.size.height / 2
        textFieldContainer.layer.borderWidth = 1
        textFieldContainer.layer.borderColor = UIColor.Sphinx.LightDivider.resolvedCGColor(with: self.view)
        
        nickNameField.delegate = self
        nickNameField.accessibilityIdentifier = "nicknameTextField"
        nextButton.accessibilityIdentifier = "nextButton"
        self.view.accessibilityIdentifier = "backgroundView"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        nickNameField.becomeFirstResponder()
    }
    
    func validateNickname()->String?{
        if let nickname = nickNameField.text, nickname != ""{
            return nickname
        }
        return nil
    }
    
    @IBAction func nextButtonTouched() {
        if isV2,
            let nickname = validateNickname(),
            let selfContact = SphinxOnionManager.sharedInstance.pendingContact,
            selfContact.isOwner == true{
            selfContact.nickname = nickname
            self.goToProfilePicture()
        }
        else if isV2 == false, let _ = validateNickname() {
            loading = true
            
            API.sharedInstance.getContacts(callback: {(contacts, _, _) -> () in
                self.insertAndUpdateOwner(contacts: contacts)
            })
        } else {
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "nickname.cannot.empty".localized)
        }
    }
    
    func insertAndUpdateOwner(contacts: [JSON]) {
        UserContactsHelper.insertContacts(contacts: contacts)
        UserData.sharedInstance.saveNewNodeOnKeychain()
        
        let id = UserData.sharedInstance.getUserId()
        let parameters = ["alias" : (nickNameField.text ?? "") as AnyObject]
        
        API.sharedInstance.updateUser(id: id, params: parameters, callback: { contact in
            self.loading = false
            let _ = UserContactsHelper.insertContact(contact: contact)
            self.goToProfilePicture()
        }, errorCallback: {
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
        })
    }
    
    func goToProfilePicture() {
        let profilePictureVC = SetProfileImageViewController.instantiate(nickname: nickNameField.text ?? nil)
        profilePictureVC.isV2 = self.isV2
        self.navigationController?.pushViewController(profilePictureVC, animated: true)
    }
}

extension SetNickNameViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var currentString = textField.text! as NSString
        currentString = currentString.replacingCharacters(in: range, with: string) as NSString
        animateFieldLabel(show: currentString != "")
        return true
    }
    
    func animateFieldLabel(show: Bool) {
        UIView.animate(withDuration: 0.2, animations: {
            self.fieldLabel.alpha = show ? 1.0 : 0.0
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text {
            nextButton.isHidden = text == ""
        }
    }
}
