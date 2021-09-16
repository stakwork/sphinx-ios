//
//  SetProfileImageViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/10/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class SetProfileImageViewController: SetDataViewController {
    
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var imageLoadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var selectImageLabel: UILabel!
    @IBOutlet weak var changeImageButtonContainer: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var uploadingLabel: UILabel!
    
    var nickname: String? = nil
    var imageSet = false
    
    var imagePickerManager = ImagePickerManager.sharedInstance
    
    static func instantiate(rootViewController : RootViewController, nickname: String?) -> SetProfileImageViewController {
        let viewController = StoryboardScene.Invite.setProfileImageViewController.instantiate()
        viewController.rootViewController = rootViewController
        viewController.contactsService = rootViewController.contactsService
        viewController.nickname = nickname
        
        return viewController
    }
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: imageLoadingWheel, view: view)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rootViewController.setStatusBarColor(light: false)
        
        profileImageView.layer.cornerRadius = profileImageView.frame.size.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        
        imageLoadingWheel.layer.cornerRadius = imageLoadingWheel.frame.size.height / 2
        imageLoadingWheel.clipsToBounds = true
        
        changeImageButtonContainer.layer.cornerRadius = changeImageButtonContainer.frame.size.height / 2
        changeImageButtonContainer.clipsToBounds = true
        
        nextButton.setTitle("skip.upper".localized, for: .normal)
        nicknameLabel.text = nickname ?? "nickname".localized
        
        imagePickerManager.configurePicker(vc: self)
    }
    
    @IBAction func changeImageButtonTouched() {
        imagePickerManager.showAlert(title: "profile.image".localized, message: "select.option".localized, sourceView: profileImageView)
    }
    
    @IBAction func backButtonTouched() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func nextButtonTouched() {
        if let image = self.profileImageView.image, imageSet {
            loading = true
            uploadImage(image: image)
        } else {
            goToSphinxDesktopAd()
        }
    }
    
    func uploadImage(image: UIImage) {
        let fixedImage = image.fixedOrientation()
        
        if let profile = UserContact.getOwner(), profile.id > 0, let imgData = fixedImage.jpegData(compressionQuality: 0.5) {
            let uploadMessage = String(format: "uploaded.progress".localized, 0)
            
            self.uploadingLabel.isHidden = false
            self.uploadingLabel.text = uploadMessage
            
            let attachmentsManager = AttachmentsManager.sharedInstance
            attachmentsManager.setDelegate(delegate: self)
            
            let attachmentObject = AttachmentObject(data: imgData, type: AttachmentsManager.AttachmentType.Photo)
            attachmentsManager.uploadImage(attachmentObject: attachmentObject, route: "public")
        } else {
            loading = false
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
        }
    }
    
    func updateProfile(photoUrl: String) {
        let id = UserData.sharedInstance.getUserId()
        let parameters = ["photo_url" : photoUrl as AnyObject]
        
        API.sharedInstance.updateUser(id: id, params: parameters, callback: { contact in
            self.loading = false
            let _ = self.contactsService.insertContact(contact: contact)
            self.goToSphinxDesktopAd()
        }, errorCallback: {
            self.loading = false
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
        })
    }
    
    func goToSphinxDesktopAd() {
        SignupHelper.step = SignupHelper.SignupStep.PersonalInfoSet.rawValue
        
        let sphinxDesktopAdVC = SphinxDesktopAdViewController.instantiate(rootViewController: rootViewController)
        self.navigationController?.pushViewController(sphinxDesktopAdVC, animated: true)
    }
}

extension SetProfileImageViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let chosenImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            loading = true
            
            dismiss(animated:true, completion: {
                self.imageSet = true
                self.profileImageView.image = chosenImage
                self.nextButton.setTitle("next.upper".localized, for: .normal)
                self.selectImageLabel.text = "change.image".localized
                self.loading = false
            })
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension SetProfileImageViewController : AttachmentsManagerDelegate {
    func didUpdateUploadProgress(progress: Int) {
        let uploadMessage = String(format: "uploaded.progress".localized, progress)
        uploadingLabel.text = uploadMessage
    }
    
    func didSuccessUploadingImage(url: String) {
        if let image = profileImageView.image?.fixedOrientation() {
            MediaLoader.storeImageInCache(img: image, url: url)
        }
        updateProfile(photoUrl: url)
    }
}
