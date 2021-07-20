//
//  CommonPictureTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 10/02/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class CommonPictureTableViewCell : CommonReplyTableViewCell {
    
    @IBOutlet weak var bubbleView: PictureBubbleView!
    @IBOutlet weak var messageBubbleView: MessageBubbleView!
    @IBOutlet weak var pictureImageView: UIImageView!
    @IBOutlet weak var lockSign: UILabel!
    @IBOutlet weak var imageLoadingView: UIView!
    @IBOutlet weak var imagePreloader: UIImageView!
    @IBOutlet weak var gifOverlayView: GifOverlayView!
    @IBOutlet weak var pictureBubbleHeight: NSLayoutConstraint!
    @IBOutlet weak var pdfInfoView: FileInfoView!
    
    var giphyHelper : GiphyHelper?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageLoadingView.backgroundColor = UIColor.Sphinx.Body.withAlphaComponent(0.5)
        gifOverlayView.configure(delegate: self)
        pdfInfoView.delegate = self
    }
    
    override func getBubbbleView() -> UIView? {
        return messageBubbleView
    }
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        super.configureRow(messageRow: messageRow, contact: contact, chat: chat)
        
        let ratio = GiphyHelper.getAspectRatioFrom(message: messageRow.transactionMessage.messageContent ?? "")
        let height = messageRow.transactionMessage.isPDF() ? PictureSentTableViewCell.kPDFBubbleHeight : PictureSentTableViewCell.kPictureBubbleHeight
        let imageBubbleHeight = height / CGFloat(ratio)
        pictureBubbleHeight.constant = imageBubbleHeight
    }
    
    func loadImage(url: URL, messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        toggleLoadingImage(loading: true)
        pictureImageView.alpha = 0.0
        
        MediaLoader.loadImage(url: url, message: messageRow.transactionMessage, completion: { messageId, image in
            if self.isDifferentRow(messageId: messageId) { return }
            
            self.loadImageInBubble(messageRow: messageRow, size: bubbleSize, image: image)
        }, errorCompletion: { messageId in
            if self.isDifferentRow(messageId: messageId) { return }
            
            self.imageLoadingFailed()
        })
    }
    
    func loadGiphy(messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        toggleLoadingImage(loading: true)
        pictureImageView.alpha = 0.0
        
        let giphyHelper = getGiphyHelper()
        giphyHelper.loadGiphyDataFrom(message: messageRow.transactionMessage, completion: { data, messageId in
            if self.isDifferentRow(messageId: messageId) { return }

            self.loadImageInBubble(messageRow: messageRow, size: bubbleSize, gifData: data)
        }, errorCompletion: { messageId in
            if self.isDifferentRow(messageId: messageId) { return }

            self.imageLoadingFailed()
        })
    }
    
    func getGiphyHelper() -> GiphyHelper {
        if let giphyHelper = self.giphyHelper {
            return giphyHelper
        }
        self.giphyHelper = GiphyHelper()
        return self.giphyHelper!
    }
    
    func loadImageInBubble(messageRow: TransactionMessageRow, size: CGSize, image: UIImage? = nil, gifData: Data? = nil) {
        gifOverlayView.alpha = messageRow.transactionMessage.isGif() ? 1.0 : 0.0
        
        pdfInfoView.configure(message: messageRow.transactionMessage)
        pdfInfoView.isHidden = !messageRow.transactionMessage.isPDF()
    }
    
    func toggleLoadingImage(loading: Bool) {
        imageLoadingView.alpha = loading ? 1.0 : 0.0
        if loading {
            imagePreloader.rotate()
        } else {
            imagePreloader.stopRotating()
        }
    }
    
    func imageLoadingFailed() {
        toggleLoadingImage(loading: false)
        pictureImageView.alpha = 1.0
        pictureImageView.tintColorDidChange()
        
        if !(messageRow?.transactionMessage?.isPaidAttachment() ?? false) {
            pictureImageView.image = UIImage(named: "imageNotAvailable")
        }
    }
    
    func configureLockSign() {
        let encrypted = (messageRow?.transactionMessage.encrypted ?? false)
        let isGiphy = (messageRow?.transactionMessage.isGiphy() ?? false)
        let hasMediaKey = (messageRow?.transactionMessage.hasMediaKey() ?? false)
        let imageEncrypted = encrypted && (hasMediaKey || isGiphy)
        lockSign.textColor = UIColor.Sphinx.WashedOutReceivedText
        lockSign.text = imageEncrypted ? "lock" : ""
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        var height: CGFloat = 0.0
        let payButtonHeight: CGFloat = messageRow.shouldShowPaidAttachmentView() ? PaidAttachmentView.kViewHeight : 0.0
        let replyTopPading = CommonChatTableViewCell.getReplyTopPadding(message: messageRow.transactionMessage)
        let ratio = GiphyHelper.getAspectRatioFrom(message: messageRow.transactionMessage.messageContent ?? "")
        let bubbleHeight = messageRow.transactionMessage.isPDF() ? PictureSentTableViewCell.kPDFBubbleHeight : PictureSentTableViewCell.kPictureBubbleHeight
        let imageBubbleHeight = bubbleHeight / CGFloat(ratio)
        let boostPadding = getReactionsHeight(messageRow: messageRow)
        
        if messageRow.transactionMessage.hasMessageContent() {
            let (_, bubbleSize) = MessageBubbleView.getLabelAndBubbleSize(messageRow: messageRow, maxBubbleWidth: PictureSentTableViewCell.kPictureBubbleHeight)
            height = imageBubbleHeight + bubbleSize.height + PictureSentTableViewCell.kPictureMessageMargin
        } else {
            height = imageBubbleHeight + boostPadding
        }
        
        return height + CommonChatTableViewCell.kBubbleTopMargin + CommonChatTableViewCell.kBubbleBottomMargin + payButtonHeight + replyTopPading
    }
    
    public static func getReactionsHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let isBoosted = messageRow.isBoosted
        let hasMessage = messageRow.transactionMessage.hasMessageContent()
        
        if !isBoosted {
            return 0
        }
        return Constants.kReactionsViewHeight + (hasMessage ? 0 : Constants.kLabelMargins)
    }
}

extension CommonPictureTableViewCell : GifOverlayDelegate {
    func didTapButton() {
        gifOverlayView.alpha = 0.0
        
        if let url = messageRow?.transactionMessage.getMediaUrl(), let gifData = MediaLoader.getMediaDataFromCachedUrl(url: url.absoluteString) {
            bubbleView.addAnimatedImageInBubble(data: gifData)
        }
    }
}

extension CommonPictureTableViewCell : FileInfoViewDelegate {
    func didTouchDownloadButton(button: UIButton) {
        if let message = messageRow?.transactionMessage, let url = message.getMediaUrl() {
            MediaLoader.loadFileData(url: url, message: message, completion: {( _, data) in
                self.delegate?.fileDownloadButtonTouched(message: message, data: data, button: button)
            }, errorCompletion: { _ in })
        }
    }
}
