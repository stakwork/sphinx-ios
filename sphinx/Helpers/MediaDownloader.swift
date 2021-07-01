//
//  MediaDownloader.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/07/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import Foundation
import Photos

class MediaDownloader {
    static func askForLibraryPermissions(completion: @escaping (Bool) -> ()) {
        let photos = PHPhotoLibrary.authorizationStatus()
        if photos == .notDetermined {
            PHPhotoLibrary.requestAuthorization({ status in
                if status == .authorized {
                    completion(true)
                } else {
                    completion(false)
                }
            })
        } else {
            completion(photos == .authorized)
        }
    }
    
    static func shouldSaveFile(message: TransactionMessage?, completion: @escaping (Bool, String) -> ()) {
        askForLibraryPermissions(completion: { success in
            if !success {
                completion(false, "photo.library.denied".localized)
                return
            }
            
            func getErrorMessage(success: Bool, itemType: String) -> String {
                let successfulllySave = String(format: "item.successfully.saved".localized, itemType)
                let errorSaving = String(format: "error.saving.item", itemType)
                
                let message = success ? successfulllySave : errorSaving
                return message
            }
            
            if message?.isGif() ?? false || message?.isGiphy() ?? false {
                self.saveGifToPhotos(message: message, completion: { success in
                    completion(success, getErrorMessage(success: success, itemType: "image".localized))
                })
            } else if message?.isPicture() ?? false {
                self.saveImageToPhotos(message: message, completion: { success in
                    completion(success, getErrorMessage(success: success, itemType: "image".localized))
                })
            } else if message?.isVideo() ?? false {
                self.saveVideoToPhotos(message: message, completion: { success in
                    completion(success, getErrorMessage(success: success, itemType: "video".localized))
                })
            }
        })
    }
    
    static func saveImageToPhotos(message: TransactionMessage?, completion: @escaping (Bool) -> ()) {
        if let message = message, let url = message.getMediaUrl() {
            MediaLoader.loadImage(url: url, message: message, completion: { _, image in
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { saved, error in
                    completion(saved)
                }
            }, errorCompletion: { _ in
                completion(false)
            })
            return
        }
        completion(false)
    }
    
    static func saveVideoToPhotos(message: TransactionMessage?, completion: @escaping (Bool) -> ()) {
        if let message = message, let url = message.getMediaUrl() {
            MediaLoader.loadVideo(url: url, message: message, completion: { (_, data, _) in
                if let videoUrl = MediaLoader.saveFileInMemory(data: data, name: "video.mov") {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
                    }) { saved, error in
                        MediaLoader.deleteItemAt(url: videoUrl)
                        completion(saved)
                    }
                    return
                }
                completion(false)
            }, errorCompletion: { _ in
                completion(false)
            })
            return
        }
        completion(false)
    }
    
    static func getGifUrlFrom(message: TransactionMessage) -> URL? {
        if let url = message.getMediaUrl() {
            return url
        } else if let urlString = GiphyHelper.getUrlFrom(message: message.messageContent ?? "", mobile: false) {
            if let url = URL(string: urlString) {
                return url
            }
        }
        return nil
    }
    
    static func saveGifToPhotos(message: TransactionMessage?, completion: @escaping (Bool) -> ()) {
        if let message = message, let url = getGifUrlFrom(message: message) {
            MediaLoader.loadVideo(url: url, message: message, completion: { (_, data, _) in
                if let gifUrl = MediaLoader.saveFileInMemory(data: data, name: "image.gif") {
                    PHPhotoLibrary.shared().performChanges({
                        let request = PHAssetCreationRequest.forAsset()
                        request.addResource(with: .photo, fileURL: gifUrl, options: nil)
                    }) { saved, error in
                        MediaLoader.deleteItemAt(url: gifUrl)
                        completion(saved)
                    }
                    return
                }
                completion(false)
            }, errorCompletion: { _ in
                completion(false)
            })
            return
        }
        completion(false)
    }
}
