//
//  AddTribeMemberViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 29/08/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

@objc protocol AddTribeMemberDelegate: class {
    func shouldReloadMembers()
}

class AddTribeMemberViewController: KeyboardEventsViewController, BackCameraVC {
    
    weak var delegate: AddTribeMemberDelegate?
    
    @IBOutlet weak var formScrollView: UIScrollView!
    @IBOutlet weak var memberImageView: UIImageView!
    @IBOutlet weak var imageUrlTextField: UITextField!
    @IBOutlet var formFields: [UITextField]!
    
    @IBOutlet weak var addMemberButton: UIButton!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    @IBOutlet weak var uploadingContainer: UIView!
    @IBOutlet weak var uploadingWheel: UIActivityIndicatorView!
    
    @IBOutlet var keyboardAccessoryView: UIView!
    
    var currentField : UITextField?
    var previousFieldValue : String?
    
    var chat: Chat!
    var viewModel: AddTribeMemberViewModel!
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.white, view: view)
        }
    }
    
    var uploadingPhoto = false {
        didSet {
            uploadingContainer.alpha = uploadingPhoto ? 1.0 : 0.0
            LoadingWheelHelper.toggleLoadingWheel(loading: uploadingPhoto, loadingWheel: uploadingWheel, loadingWheelColor: UIColor.Sphinx.Text, view: view)
        }
    }
    
    static func instantiate(
        with chat: Chat,
        delegate: AddTribeMemberDelegate?
    ) -> AddTribeMemberViewController {
        let viewController = StoryboardScene.Groups.addTribeMemberViewController.instantiate()
        viewController.chat = chat
        viewController.delegate = delegate
        viewController.viewModel = AddTribeMemberViewModel(vc: viewController)
        
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareView()
    }
    
    @objc override func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            formScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        }
    }

    @objc override func keyboardWillHide(_ notification: Notification) {
        formScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func prepareView() {
        memberImageView.layer.cornerRadius = memberImageView.frame.size.height / 2
        addMemberButton.layer.cornerRadius = addMemberButton.frame.size.height / 2
        
        configureFields()
    }
    
    func configureFields() {
        for field in formFields {
            field.delegate = self
            field.inputAccessoryView = keyboardAccessoryView
        }
    }
    
    func toggleConfirmButton() {
        addMemberButton.isHidden = !viewModel.isMemberInfoValid()
    }
}

extension AddTribeMemberViewController : UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        completeValue(textField: textField)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        currentField = textField
        previousFieldValue = textField.text
    }
    
    func shouldRevertValue() {
        if let currentField = currentField, let previousFieldValue = previousFieldValue {
            currentField.text = previousFieldValue
        }
    }
    
    func completeValue(textField: UITextField) {
        viewModel.completeValue(textField: textField)
        completeUrlAndLoadImage(textField: textField)
        toggleConfirmButton()
    }
    
    func completeUrlAndLoadImage(textField: UITextField) {
        if (textField.tag != AddTribeMemberViewModel.MemberFields.Image.rawValue) {
            return
        }
        
        let imgUrl = textField.text ?? ""
        
        if imgUrl.isValidURL {
            viewModel.completeImageUrl(imageUrl: imgUrl)
            
            if let nsUrl = URL(string: imgUrl) {
                showImage(url: nsUrl, contentMode: .scaleAspectFill)
            }
        } else if memberImageView.image == nil {
            showImage(image: UIImage(named: "profileImageIcon"), contentMode: .center)
            textField.text = ""
        }
    }
    
    func showImage(image: UIImage? = nil, url: URL? = nil, contentMode: UIView.ContentMode) {
        viewModel.shouldUploadImage = false
        
        if let image = image {
            memberImageView.image = image
        } else if let url = url {
            MediaLoader.asyncLoadImage(imageView: memberImageView, nsUrl: url, placeHolderImage: UIImage(named: "profileImageIcon"))
        }
        memberImageView.contentMode = contentMode
    }
    
    func showErrorAlert() {
        loading = false
        AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
    }
    
    @IBAction func memberImageButtonTouched() {
        viewModel.showImagePicker()
    }
    
    @IBAction func keyboardButtonTouched(_ sender: UIButton) {
        switch (sender.tag) {
        case KeyboardButtons.Done.rawValue:
            break
        case KeyboardButtons.Cancel.rawValue:
            shouldRevertValue()
            break
        default:
            break
        }
        view.endEditing(true)
    }
    
    @IBAction func addMemberButtonTouched() {
        viewModel.uploadImage(image: memberImageView.image)
    }
    
    func dismissOnSuccess() {
        delegate?.shouldReloadMembers()
        self.dismiss(animated: true)
    }
    
    @IBAction func closeButtonTouched() {
        self.dismiss(animated: true)
    }
}

extension AddTribeMemberViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let chosenImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            picker.dismiss(animated:true, completion: {
                self.showImage(image: chosenImage, contentMode: .scaleAspectFill)
                self.viewModel.shouldUploadImage = true
                self.imageUrlTextField.text = ""
            })
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
