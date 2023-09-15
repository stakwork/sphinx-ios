//
//  ChatAttachmentViewControllerExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import GiphyUISDK
import SDWebImage
import Photos
import PhotosUI

extension ChatAttachmentViewController : AttachmentsDelegate {
    func willDismissPresentedVC() {
        closeButtonTouched()
    }
    
    func shouldStartUploading(attachmentObject: AttachmentObject) {}
    func shouldSendGiphy(message: String, data: Data) {}
    func didTapReceiveButton() {}
    func didTapSendButton() {}
}

extension ChatAttachmentViewController {
    func isButtonDisabled(option: OptionsButton) -> Bool {
        switch(option) {
        case OptionsButton.Request:
            return (self.chat?.isGroup() ?? false)
        case OptionsButton.Send:
            let publicGroup = self.chat?.isPublicGroup() ?? false
            if !publicGroup {
                return false
            }
            if self.chat?.tribeInfo?.hasLoopoutBot ?? false {
                sendOptionTitle.text = "Send Onchain"
                return false
            }
            return true
        case OptionsButton.Message:
            return isThread
        default:
            break
        }
        return false
    }
}

extension ChatAttachmentViewController: ChatMessageTextFieldViewDelegate {
    func didDetectPossibleMacro(macro: String) {
        //
    }
    
    func didDetectPossibleMention(mentionText: String) {
        //Implement mentions
    }
    
    func didChangeText(text: String) {
        updatePreview(message: text, price: price)
    }
    
    func shouldSendMessage(text: String, type: Int, completion: @escaping (Bool) -> ()) {
        shouldSend(message: text, completion: completion)
    }
    
    func didTapSendBlueButton() {
        shouldSend()
    }
    
    func shouldSend(
        message: String? = nil,
        completion: ((Bool) -> ())? = nil
    ) {
        if let giphy = selectedGiphy,
            let messageString = giphyHelper.getMessageStringFrom(media: giphy.0, text: message) {
            delegate?.shouldSendGiphy(message: messageString, data: giphy.1)
            dismissView()
            completion?(true)
            
            return
        }
        uploadAndSend(message: message, completion: completion)
    }
    
    func didChangeAccessoryViewHeight(heightDiff: CGFloat, updatedText: String) {
        updatePreview(message: updatedText, price: price)
    }
}

extension ChatAttachmentViewController : MessageReplyViewDelegate {
    func didCloseReplyView() {
        delegate?.didCloseReplyView()
    }
}

extension ChatAttachmentViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        DispatchQueue.main.async {
            if let chosenImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
                    let requestOptions = PHImageRequestOptions()
                    requestOptions.isSynchronous = true
                    
                    PHImageManager.default().requestImageDataAndOrientation(for: asset, options: requestOptions, resultHandler: { (imageData, _, _, _) in
                        if let data = imageData, data.isAnimatedImage() {
                            let animated = SDAnimatedImage(data: data)
                            self.gifSelected(animatedImage: animated, staticImage: chosenImage)
                        } else {
                            self.imageSelected(image: chosenImage)
                        }
                    })
                } else {
                    self.imageSelected(image: chosenImage)
                }
            } else if let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL {
                self.videoSelected(videoURL: videoURL)
            }
            picker.dismiss(animated:true, completion: nil)
        }
    }
    
    func gifSelected(animatedImage: SDAnimatedImage?, staticImage: UIImage?, allowPrice: Bool = true) {
        hideOptionsContainer()
        
        viewTitle.text = "send.gif.upper".localized
        selectedAnimatedImage = animatedImage
        selectedImage = staticImage
        showImagePreview(animatedImage: animatedImage, allowPrice: allowPrice)
    }
    
    func imageSelected(image: UIImage?) {
        hideOptionsContainer()
        
        viewTitle.text = "send.image.upper".localized
        selectedImage = image
        showImagePreview(image: image)
    }
    
    func showImagePreview(
        image: UIImage? = nil,
        animatedImage: SDAnimatedImage? = nil,
        allowPrice: Bool = true
    ) {
        if allowPrice { showPriceContainer() }
        loading = image == nil && animatedImage == nil
        
        previewImageView.alpha = 1.0
        previewImageView.contentMode = .scaleAspectFit
        
        if let image = image {
            previewImageView.image = image
        } else if let animatedImage = animatedImage {
            previewImageView.image = animatedImage
            previewImageView.startAnimating()
        }
        
        showGeneralViews()
    }
    
    func showGeneralViews() {
        headerContainer.alpha = 1.0
        contentStackView.isHidden = false
        bottomView.isHidden = false
    }

    func showMessageLabel() {
        view.backgroundColor = UIColor.white
        hideOptionsContainer()
        showPriceContainer()
        
        viewTitle.text = "send.paid.message.upper".localized
        showPreviewVC()
        showGeneralViews()
        
        headerContainer.addShadow(location: .bottom, opacity: 0.15, radius: 1.0)
        headerContainer.clipsToBounds = false
    }
    
    func showFilePreview(data: Data, fileName: String) {
        showPriceContainer()
        showFileInfoContainer()
        
        fileInfoView.configure(data: data, fileName: fileName)
        showGeneralViews()
        
        headerContainer.addShadow(location: .bottom, opacity: 0.15, radius: 1.0)
        headerContainer.clipsToBounds = false
    }
    
    func videoSelected(videoURL: NSURL) {
        hideOptionsContainer()
        
        viewTitle.text = "send.video.upper".localized
        selectedVideo = MediaLoader.getDataFromUrl(url: videoURL as URL)
        
        if let thumbnail = AttachmentsManager.sharedInstance.getThumbnailFromVideo(videoURL: videoURL as URL) {
            selectedImage = thumbnail
            showImagePreview(image: thumbnail)
        }
    }

    @objc func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: {})
    }
}

extension ChatAttachmentViewController {
    func showPreviewVC() {
        previewVC = PaidMessagePreviewViewController.instantiate()
        addChildVC(child: previewVC!, container: paidMessagePreviewVCContainer)

        paidMessagePreviewVCContainer.isHidden = false
        updatePreview(message: "", price: price)
    }
    
    func updatePreview(message: String, price: Int) {
        if let previewVC = previewVC {
            let previewMessage = message == ChatAttachmentViewController.kFieldPlaceHolder ? "" : message
            previewVC.configureMessageWith(text: previewMessage, andPrice: price)
        }
    }
}

extension ChatAttachmentViewController : AttachmentPriceDelegate {
    func showPriceVC() {
        priceVC = AttachmentPriceViewController.instantiate(delegate: self, price: price)
        addChildVC(child: priceVC!, container: attachmentPriceVCContainer)
        
        attachmentPriceVCContainer.isHidden = false
    }
    
    func shouldHidePriceChildVC(amount: Int? = nil) {
        priceVC?.view.removeFromSuperview()
        priceVC?.removeFromParent()
        priceVC = nil
        attachmentPriceVCContainer.isHidden = true
        
        if let amount = amount {
            price = amount
            
            let amountString = amount.formattedWithSeparator
            priceLabel.text = (amount > 0) ? "\(amountString)" : "set.price.upper".localized
            priceUnitLabel.text = (amount > 0) ? "sat" : ""
            
            updatePreview(message: newChatAccessoryView.getMessage(), price: price)
        }
    }
}

extension ChatAttachmentViewController : GiphyDelegate {
    func didSelectMedia(giphyViewController: GiphyUISDK.GiphyViewController, media: GiphyUISDK.GPHMedia) {
        if let url = media.url(rendition: .original, fileType: .gif) {
            hideAllGiphyView(giphyViewController: giphyViewController)
            
            GiphyHelper.getGiphyDataFrom(url: url, messageId: -1, completion: { (data, error) in
                if let data = data {
                    let animated = SDAnimatedImage(data: data)
                    let image = UIImage(data: data)
                    
                    self.selectedGiphy = (media, data)
                    
                    self.gifSelected(animatedImage: animated, staticImage: image, allowPrice: false)
                }
            })
        }
    }
    
    func hideAllGiphyView(giphyViewController: GiphyUISDK.GiphyViewController) {
        hideOptionsContainer()
        showImagePreview(allowPrice: false)
        giphyViewController.dismiss(animated: true, completion: nil)
    }

    func didDismiss(controller: GiphyUISDK.GiphyViewController?) {}
}

extension ChatAttachmentViewController : UIDocumentPickerDelegate {
    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentAt url: URL
    ) {
        do {
            selectedFileData = try Data(contentsOf: url)
        } catch {}
        
        let mimeType = url.absoluteString.mimeTypeForPath()
        let fileExtension = mimeType.getExtensionFromMimeType()
        fileName = (url.absoluteString as NSString).lastPathComponent.percentNotEscaped ?? "file.\(fileExtension)"
        selectedImage = selectedFileData?.getPDFThumbnail(size: self.view.frame.size)
        toggleOptionsContainer(show: false)
        
        if let image = selectedImage {
            showImagePreview(image: image)
        } else if let fileData = selectedFileData {
            showFilePreview(data: fileData, fileName: fileName!)
        }
    }
}
