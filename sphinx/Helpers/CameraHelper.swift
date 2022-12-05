//
//  CameraHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/10/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import AVFoundation

class CameraHelper {
    public static func showPhotoLibrary(
        picker: UIImagePickerController,
        vc: UIViewController,
        mediaTypes: [String]? = nil
    ) {
        configure(picker: picker, for: .photoLibrary, mediaTypes: mediaTypes)
        vc.present(picker, animated: true, completion: nil)
    }
    
    public static func showCamera(
        picker: UIImagePickerController,
        camera: UIImagePickerController.CameraDevice,
        mode: UIImagePickerController.CameraCaptureMode = .photo,
        vc: UIViewController,
        mediaTypes: [String]? = nil,
        noCameraBlock: () -> ()
    ) {
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            configure(picker: picker, for: .camera, and: camera, mediaTypes: mediaTypes)
            vc.present(picker, animated: true,completion: nil)
        } else {
            noCameraBlock()
        }
    }
    
    public static func configure(
        picker: UIImagePickerController,
        for sourceType: UIImagePickerController.SourceType,
        and camera: UIImagePickerController.CameraDevice? = nil,
        mediaTypes: [String]? = nil
    ) {
        picker.allowsEditing = false
        picker.sourceType = sourceType
        
        if let camera = camera {
            picker.cameraDevice = camera
        }
        
        if let mediaTypes = mediaTypes {
            picker.mediaTypes = mediaTypes
        } else if let availableTypes = UIImagePickerController.availableMediaTypes(for: sourceType) {
            picker.mediaTypes = availableTypes
        }
        
        picker.videoQuality = .typeIFrame960x540
        picker.videoMaximumDuration = 60
        picker.videoExportPreset = AVAssetExportPreset960x540
        picker.modalPresentationStyle = .fullScreen
    }
    
    public static func showFrontCamera(
        picker: UIImagePickerController,
        mode: UIImagePickerController.CameraCaptureMode = .photo,
        vc: UIViewController,
        mediaTypes: [String]? = nil,
        noCameraBlock: () -> ()
    ) {
        showCamera(picker: picker, camera: .front, mode: mode, vc: vc, mediaTypes: mediaTypes, noCameraBlock: noCameraBlock)
    }
    
    public static func showBackCamera(
        picker: UIImagePickerController,
        mode: UIImagePickerController.CameraCaptureMode = .photo,
        vc: UIViewController,
        mediaTypes: [String]? = nil,
        noCameraBlock: () -> ()
    ) {
        showCamera(picker: picker, camera: .rear, mode: mode, vc: vc, mediaTypes: mediaTypes, noCameraBlock: noCameraBlock)
    }
}
