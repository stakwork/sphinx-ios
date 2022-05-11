//
//  PictureSentTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 29/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import SDWebImageFLPlugin

class PictureSentTableViewCell: CommonPictureTableViewCell, MediaUploadingCellProtocol, MessageRowProtocol {
    
    static let kPictureBubbleHeight: CGFloat = 210.0
    static let kPDFBubbleHeight: CGFloat = 150.0
    static let kPictureMessageMargin: CGFloat = 0.0
    
    @IBOutlet weak var seenSign: UILabel!
    @IBOutlet weak var uploadCancelButton: UIButton!
    @IBOutlet weak var errorContainer: UIView!
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var attachmentPriceView: AttachmentPriceView!
    
    var uploading = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat)
        
        commonConfigurationForMessages()
        configureImageAndMessage()
        configureUploading()
        configureMessageStatus()
        configurePrice(messageRow: messageRow)

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func configurePrice(messageRow: TransactionMessageRow) {
        let price = messageRow.transactionMessage.getAttachmentPrice() ?? 0
        let statusAttributes = messageRow.transactionMessage.getPurchaseStatusLabel(queryDB: false)
        attachmentPriceView.configure(price: price, status: statusAttributes)
    }
    
    func configureImageAndMessage() {
        guard let messageRow = messageRow else {
            return
        }
        
        gifOverlayView.alpha = 0.0
        pdfInfoView.isHidden = true
        
        let ratio = GiphyHelper.getAspectRatioFrom(message: messageRow.transactionMessage.messageContent ?? "")
        let bubbleHeight = messageRow.transactionMessage.isPDF() ? PictureSentTableViewCell.kPDFBubbleHeight : PictureSentTableViewCell.kPictureBubbleHeight
        let bubbleSize = CGSize(width: PictureSentTableViewCell.kPictureBubbleHeight, height: bubbleHeight / CGFloat(ratio))
        bubbleView.showOutgoingPictureBubble(messageRow: messageRow, size: bubbleSize)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: bubbleSize, incoming: false)
        
        tryLoadingImage(messageRow: messageRow, bubbleSize: bubbleSize)
        
        messageBubbleView.clearBubbleView()
        
        if messageRow.transactionMessage.hasMessageContent() || messageRow.isBoosted {
            let (label, _) = messageBubbleView.showOutgoingMessageBubble(messageRow: messageRow, fixedBubbleWidth: PictureSentTableViewCell.kPictureBubbleHeight)
            addLinksOnLabel(label: label)
        }
    }
    
    func tryLoadingImage(messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        uploading = false
        
        if let url = messageRow.transactionMessage.getMediaUrl() {
            loadImage(url: url, messageRow: messageRow, bubbleSize: bubbleSize)
        } else if !uploading {
            if messageRow.transactionMessage.isGiphy() {
                loadGiphy(messageRow: messageRow, bubbleSize: bubbleSize)
            } else {
                imageLoadingFailed()
            }
        }
    }
    
    override func imageLoadingFailed() {
        super.imageLoadingFailed()
    }
    
    override func toggleLoadingImage(loading: Bool) {
        super.toggleLoadingImage(loading: loading)
    }
    
    override func loadImageInBubble(messageRow: TransactionMessageRow, size: CGSize, image: UIImage? = nil, gifData: Data? = nil) {
        super.loadImageInBubble(messageRow: messageRow, size: size)
        toggleLoadingImage(loading: false)
        
        pictureImageView.image = nil
        bubbleView.showOutgoingPictureBubble(messageRow: messageRow, size: size, image: image, gifData: gifData)
    }
    
    func configureMessageStatus() {
        guard let messageRow = messageRow else {
            return
        }
        
        let received = messageRow.transactionMessage.received()
        let failed = messageRow.transactionMessage.failed()
        let expired = messageRow.transactionMessage.isMediaExpired()
        configureLockSign()
        
        seenSign.text = received ? "flash_on" : ""
        seenSign.alpha = received ? 1.0 : 0.0
        errorContainer.alpha = failed || expired ? 1.0 : 0.0
        errorMessageLabel.text = expired ? "media.terms.expired".localized : "message.failed".localized
    }
    
    func configureUploading() {
        guard let messageRow = messageRow, messageRow.transactionMessage.getMediaUrl() == nil else {
            return
        }
        
        if messageRow.transactionMessage?.isCancelled() ?? false {
            return
        }
        
        if let image = messageRow.transactionMessage?.uploadingObject?.image {
            uploading = true
            let progress = messageRow.transactionMessage?.uploadingProgress ?? 0
            
            let bubbleHeight = messageRow.transactionMessage.isPDF() ? PictureSentTableViewCell.kPDFBubbleHeight : PictureSentTableViewCell.kPictureBubbleHeight
            let bubbleSize = CGSize(width: PictureSentTableViewCell.kPictureBubbleHeight, height: bubbleHeight)
            bubbleView.showOutgoingPictureBubble(messageRow: messageRow, size: bubbleSize, image: image)
            
            seenSign.text = ""
            lockSign.text = ""
            
            let uploadedString = String(format: "uploaded.progress".localized, progress)
            dateLabel.text = uploadedString
            dateLabel.font = UIFont(name: "Roboto-Medium", size: 10.0)!
            
            pictureImageView.image = nil
            uploadCancelButton.alpha = 1.0
            toggleLoadingImage(loading: true)
            
            for subview in messageBubbleView.getSubviews() {
                if subview.tag == MessageBubbleView.kMessageLabelTag {
                    subview.alpha = 0.5
                }
            }
        }
    }
    
    func isUploading() -> Bool {
        return uploading && self.messageRow?.transactionMessage.uploadingObject?.image != nil
    }
    
    func configureUploadingProgress(progress: Int, finishUpload: Bool) {
        let uploadedString = String(format: "uploaded.progress".localized, progress)
        dateLabel.text = uploadedString
        uploadCancelButton.alpha = finishUpload ? 0.0 : 1.0
    }
    
    @IBAction func cancelUploadButtonTouched() {
        if let message = messageRow?.transactionMessage {
            delegate?.didTapAttachmentCancel?(message: message)
        }
    }
}
