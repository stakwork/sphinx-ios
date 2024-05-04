//
//  GroupNameViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class GroupNameViewController: UIViewController {
    
    weak var delegate: NewContactVCDelegate?
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var groupImageButton: UIButton!
    @IBOutlet weak var uploadedLabel: UILabel!
    @IBOutlet weak var groupNameFieldContainer: UIView!
    @IBOutlet weak var groupNameTextField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var fieldContainerTopConstraint: NSLayoutConstraint!
    
    var imagePickerManager = ImagePickerManager.sharedInstance
    var imageSet = false
    
    var groupsManager = GroupsManager.sharedInstance
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.Sphinx.Text, view: view)
        }
    }
    
    static func instantiate(delegate: NewContactVCDelegate?) -> GroupNameViewController {
        let viewController = StoryboardScene.Groups.groupNameViewController.instantiate()
        viewController.delegate = delegate
        
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        doneButton.layer.cornerRadius = doneButton.frame.size.height / 2
        doneButton.clipsToBounds = true
        doneButton.addShadow(location: .bottom, opacity: 0.5, radius: 2.0)
        
        groupImageView.layer.cornerRadius = groupImageView.frame.size.height / 2
        groupImageView.clipsToBounds = true
        groupImageView.contentMode = .scaleAspectFill
        
        groupNameFieldContainer.layer.cornerRadius = groupNameFieldContainer.frame.size.height / 2
        groupNameFieldContainer.layer.borderWidth = 1
        groupNameFieldContainer.layer.borderColor = UIColor.Sphinx.LightDivider.resolvedCGColor(with: self.view)
        
        doneButton.isHidden = true
        groupNameTextField.delegate = self
        imagePickerManager.configurePicker(vc: self)
    }
    
    @IBAction func groupImageButtonTouched() {
        imagePickerManager.showAlert(title: "group.image".localized, message: "select.option".localized, sourceView: groupImageView)
    }
    
    @IBAction func backButtonTouched() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func doneButtonTouched() {
        if let groupName = groupNameTextField.text, groupName != "" {
            loading = true
            groupsManager.setName(name: groupName)
            createGroup()
        }
    }
    
    func createGroup() {
        let (valid, params) = groupsManager.getGroupParams()
        
        if !valid {
            errorCreatingGroup()
            return
        }
        
        API.sharedInstance.createGroup(params: params, callback: { chatJson in
            if let chat = Chat.insertChat(chat: chatJson) {
                self.finishCreatingGroup(chat: chat)
            } else {
                self.errorCreatingGroup()
            }
        }, errorCallback: {
            self.errorCreatingGroup()
        })
    }
    
    func errorCreatingGroup() {
        loading = false
        AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
    }
    
    func finishCreatingGroup(chat: Chat) {
        if let image = self.groupImageView.image, imageSet {
            uploadImage(image: image, for: chat)
        } else {
            shouldDismissView()
        }
    }
    
    func uploadImage(image: UIImage, for chat: Chat) {
        let id = chat.id
        let fixedImage = image.fixedOrientation()
       
        API.sharedInstance.uploadImage(chatId: id, image: fixedImage, progressCallback: { progress in
            self.uploadedLabel.isHidden = false
            
            let uploadedString = String(format: "uploaded.progress", progress)
            self.uploadedLabel.text = uploadedString
        }, callback: { (success, fileUrl) in
            if let fileUrl = fileUrl, success {
                self.imageUploaded(photoUrl: fileUrl, chat: chat)
            } else {
                self.imageUploaded(photoUrl: nil, chat: chat)
            }
        })
    }
    
    func imageUploaded(photoUrl: String?, chat: Chat) {
        if let photoUrl = photoUrl {
            chat.photoUrl = photoUrl
        }
        self.shouldDismissView()
    }
    
    func shouldDismissView() {
        self.delegate?.shouldReloadContacts?(reload: true, dashboardTabIndex: -1)
        self.dismiss(animated: true, completion: nil)
    }
}

extension GroupNameViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var currentString = textField.text! as NSString
        currentString = currentString.replacingCharacters(in: range, with: string) as NSString
        if currentString.length < 100 {
            return true
        }
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        animateFieldAndImage(keyboardVisible: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text {
            doneButton.isHidden = text == ""
        }
        animateFieldAndImage(keyboardVisible: false)
    }
    
    func animateFieldAndImage(keyboardVisible: Bool) {
        fieldContainerTopConstraint.constant = keyboardVisible ? -120 : 35
        
        UIView.animate(withDuration: 0.3, animations: {
            self.groupNameFieldContainer.superview?.layoutIfNeeded()
            self.groupImageView.alpha = keyboardVisible ? 0.0 : 1.0
            self.groupImageButton.alpha = keyboardVisible ? 0.0 : 1.0
        })
    }
}

extension GroupNameViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let chosenImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.imageSet = true
            self.groupImageView.image = chosenImage
            
            picker.dismiss(animated:true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
