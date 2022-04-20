//
//  ImagePickerManager.swift
//  sphinx
//
//  Created by Tomas Timinskas on 28/10/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class ImagePickerManager {
    
    class var sharedInstance : ImagePickerManager {
        struct Static {
            static let instance = ImagePickerManager()
        }
        return Static.instance
    }
    
    var picker = UIImagePickerController()
    var viewController : UIViewController?
    
    func configurePicker(vc: UIViewController) {
        self.viewController = vc
        self.picker = UIImagePickerController()
        
        if let vc = vc as? (UIImagePickerControllerDelegate & UINavigationControllerDelegate) {
            self.picker.delegate = vc
        }
    }
    
    func setPickerDelegateView(view: UIView) {
        self.picker = UIImagePickerController()
        
        if let view = view as? (UIImagePickerControllerDelegate & UINavigationControllerDelegate) {
            self.picker.delegate = view
        }
    }
    
    func showAlert(
        title: String,
        message: String,
        sourceView: UIView,
        mediaTypes: [String]? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "camera".localized, style: .default , handler:{ (UIAlertAction)in
            self.showCamera(mediaTypes: mediaTypes)
        }))
        
        alert.addAction(UIAlertAction(title: "photo.library".localized, style: .default , handler:{ (UIAlertAction)in
            self.showPhotoLibrary(mediaTypes: mediaTypes)
        }))
        
        alert.addAction(UIAlertAction(title: "dismiss".localized, style: .cancel, handler:{ (UIAlertAction)in
            if let vc = self.viewController as? AttachmentsDelegate {
                vc.willDismissPresentedVC()
            }
        }))
        
        alert.popoverPresentationController?.sourceView = sourceView
        alert.popoverPresentationController?.sourceRect = sourceView.bounds
        
        if let vc = self.viewController {
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    func showPhotoLibrary(
        mediaTypes: [String]? = nil
    ) {
        if let vc = self.viewController {
            CameraHelper.showPhotoLibrary(picker: self.picker, vc: vc, mediaTypes: mediaTypes)
        }
    }
    
    func showCamera(
        mode: UIImagePickerController.CameraCaptureMode = .photo,
        mediaTypes: [String]? = nil
    ) {
        if let vc = self.viewController {
            let conformsToBackCameraProtocol = (vc as? BackCameraVC) != nil
            
            if conformsToBackCameraProtocol {
                CameraHelper.showBackCamera(picker: self.picker, mode: mode, vc: vc, noCameraBlock: {
                    self.noCameraAvailable()
                })
            } else {
                CameraHelper.showFrontCamera(picker: self.picker, mode: mode, vc: vc, noCameraBlock: {
                    self.noCameraAvailable()
                })
            }
        }
    }
    
    func noCameraAvailable() {
        AlertHelper.showAlert(title: "generic.error.title".localized, message: "no.camera.available".localized, completion: {
            if let vc = self.viewController as? AttachmentsDelegate {
                vc.willDismissPresentedVC()
            }
        })
    }
}
