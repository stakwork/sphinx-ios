//
//  TribeMemberInfoView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/12/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

@objc protocol TribeMemberInfoDelegate : class {
    func didUpdateUploadProgress(uploadString: String)
    @objc optional func didChangeImageOrAlias()
}

class TribeMemberInfoView: UIView {
    
    weak var delegate: TribeMemberInfoDelegate?
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var aliasTextField: UITextField!
    @IBOutlet weak var pictureTextField: UITextField!
    @IBOutlet weak var pictureImageView: UIImageView!
    
    var field: UITextField? = nil
    var fieldValue: String? = nil
    var imageSelected = false
    
    var imagePickerManager = ImagePickerManager.sharedInstance
    
    var uploadCompletion: ((String?, String?) -> ())? = nil
    
    let ACCEPTABLE_CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_ "
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("TribeMemberInfoView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        aliasTextField.delegate = self
        pictureTextField.delegate = self
    }
    
    func configureWith(
        vc: UIViewController,
        accessoryView: UIView,
        alias: String?,
        picture: String? = nil,
        shouldFixAlias: Bool = false
    ) {
        if let vc = vc as? TribeMemberInfoDelegate {
            self.delegate = vc
        }
        
        imagePickerManager.configurePicker(vc: vc)
        imagePickerManager.setPickerDelegateView(view: self)
        
        aliasTextField.inputAccessoryView = accessoryView
        pictureTextField.inputAccessoryView = accessoryView
        
        aliasTextField.text = shouldFixAlias ? alias?.fixedAlias : alias
        pictureTextField.text = picture ?? ""
        
        loadImage(pictureUrl: picture)
    }
    
    func loadImage(pictureUrl: String?) {
        if let pictureUrl = pictureUrl, let url = URL(string: pictureUrl), !pictureUrl.isEmpty && pictureUrl.isValidURL {
            pictureImageView.layer.cornerRadius = pictureImageView.frame.height / 2
            pictureImageView.clipsToBounds = true
            
            MediaLoader.asyncLoadImage(imageView: pictureImageView, nsUrl: url, placeHolderImage: UIImage(named: "profileImageIcon"), completion: {
                self.pictureImageView.contentMode = .scaleAspectFill
            })
        } else {
            pictureTextField.text = ""
            pictureImageView.contentMode = .center
            pictureImageView.image = UIImage(named: "profileImageIcon")
        }
    }
    
    func shouldRevert() {
        if let field = field, let fieldValue = fieldValue {
            field.text = fieldValue
        }
    }
    
    @IBAction func pictureButtonTouched() {
        imagePickerManager.setPickerDelegateView(view: self)
        imagePickerManager.showAlert(title: "profile.image".localized, message: "select.option".localized, sourceView: pictureImageView)
    }
    
    @IBAction func aliasDidChanged(_ sender: UITextField) {
        if (sender.text?.contains(" ") == true) {
            allowedCharactersToast(true)
        }
        sender.text = sender.text?.replacingOccurrences(of: " ", with: "_")
    }
}

extension TribeMemberInfoView : UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        field = textField
        fieldValue = textField.text
        
        if (textField == aliasTextField) {
            aliasTextField.text = aliasTextField.text?.fixedAlias ?? aliasTextField.text
        }
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField == pictureTextField {
            loadImage(pictureUrl: textField.text)
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let cs = NSCharacterSet(charactersIn: ACCEPTABLE_CHARACTERS).inverted
        let filtered = string.components(separatedBy: cs).joined(separator: "")
        let allowed = (string == filtered)
        
        allowedCharactersToast(!allowed)

        return allowed
    }
    
    func allowedCharactersToast(_ show: Bool) {
        guard show else {
            return
        }
        NewMessageBubbleHelper().showGenericMessageView(text: "alias.allowed-characters".localized)
    }
}

extension TribeMemberInfoView : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let chosenImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let fixedImage = chosenImage.fixedOrientation()
            self.pictureImageView.image = fixedImage
            self.pictureTextField.text = "image".localized.capitalized
            self.imageSelected = true
            
            picker.dismiss(animated: true)
            
            delegate?.didChangeImageOrAlias?()
        }
    }
    
    func uploadImage(completion: @escaping (String?, String?) -> ()) {
        uploadCompletion = completion
        
        if let alias = aliasTextField.text, alias.isEmpty {
            completion(nil, nil)
        }
        
        if let image = pictureImageView.image, imageSelected {
            uploadImage(image: image)
            return
        }
        let pictureUrl = (pictureTextField.text?.isValidURL ?? false) ? pictureTextField.text : ""
        completion(aliasTextField.text, pictureUrl)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func uploadImage(image: UIImage) {
        if let imgData = image.jpegData(compressionQuality: 0.5) {
            let attachmentsManager = AttachmentsManager.sharedInstance
            attachmentsManager.setDelegate(delegate: self)
            
            let attachmentObject = AttachmentObject(data: imgData, type: AttachmentsManager.AttachmentType.Photo)
            attachmentsManager.uploadImage(attachmentObject: attachmentObject, route: "public")
        }
    }
}

extension TribeMemberInfoView : AttachmentsManagerDelegate {
    func didUpdateUploadProgress(progress: Int) {
        let uploadedMessage = String(format: "uploaded.progress".localized, progress)
        delegate?.didUpdateUploadProgress(uploadString: uploadedMessage)
    }
    
    func didSuccessUploadingImage(url: String) {
        if let image = pictureImageView.image?.fixedOrientation() {
            MediaLoader.storeImageInCache(img: image, url: url, message: nil)
        }
        pictureTextField.text = url
        
        if let uploadCompletion = uploadCompletion {
            uploadCompletion(aliasTextField.text, url)
        }
    }
}

