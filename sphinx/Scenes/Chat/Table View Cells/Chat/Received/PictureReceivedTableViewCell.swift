//
//  PictureReceivedTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 29/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class PictureReceivedTableViewCell: CommonPictureTableViewCell, MessageRowProtocol {
    
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var errorContainer: UIView!
    @IBOutlet weak var lockedPaidItemOverlayView: UIView!
    @IBOutlet weak var lockedPaidItemOverlayLabel: UILabel!
    @IBOutlet weak var paidAttachmentView: PaidAttachmentView!
    @IBOutlet weak var separatorLine: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        paidAttachmentView.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat)

        commonConfigurationForMessages()
        configureStatus()
        configureImageAndMessage()
        configurePayment()

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func configureImageAndMessage() {
        guard let messageRow = messageRow else {
            return
        }
        
        gifOverlayView.alpha = 0.0
        pdfInfoView.isHidden = true
        
        lockedPaidItemOverlayView.isHidden = true
        lockedPaidItemOverlayLabel.text = "pay.to.unlock.image".localized.uppercased()
        lockedPaidItemOverlayLabel.addTextSpacing(value: 2)
        
        let hasContent = messageRow.transactionMessage.hasMessageContent()
        let ratio = GiphyHelper.getAspectRatioFrom(message: messageRow.transactionMessage.messageContent ?? "")
        let bubbleHeight = messageRow.transactionMessage.isPDF() ? PictureSentTableViewCell.kPDFBubbleHeight : PictureSentTableViewCell.kPictureBubbleHeight
        let bubbleSize = CGSize(width: PictureSentTableViewCell.kPictureBubbleHeight, height: bubbleHeight / CGFloat(ratio))
        
        bubbleView.showIncomingPictureBubble(messageRow: messageRow, size: bubbleSize)
        
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: bubbleSize, incoming: true)
        
        tryLoadingImage(messageRow: messageRow, bubbleSize: bubbleSize)
        
        messageBubbleView.clearBubbleView()
        
        separatorLine.isHidden = !hasContent
        
        if hasContent || messageRow.isBoosted {
            let (label, _) = messageBubbleView.showIncomingMessageBubble(messageRow: messageRow, fixedBubbleWidth: PictureSentTableViewCell.kPictureBubbleHeight)
            addLinksOnLabel(label: label)
        }
    }
    
    func configurePayment() {
        guard let messageRow = messageRow else {
            paidAttachmentView.isHidden = true
            return
        }
        
        paidAttachmentView.configure(messageRow: messageRow, delegate: self)
        
        if messageRow.shouldShowPaidAttachmentView() &&
           !messageRow.transactionMessage.isAttachmentAvailable() {
            
            lockedPaidItemOverlayView.isHidden = false
        }
    }
    
    func configureStatus() {
        guard let messageRow = messageRow else {
            return
        }
        
        configureLockSign()
        
        let expired = messageRow.transactionMessage.isMediaExpired()
        errorMessageLabel.text = "media.terms.expired".localized
        errorContainer.alpha = expired ? 1.0 : 0.0
    }
    
    func tryLoadingImage(messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        if let nsUrl = messageRow.transactionMessage.getMediaUrl() {
            loadImage(url: nsUrl, messageRow: messageRow, bubbleSize: bubbleSize)
        } else if messageRow.transactionMessage.isGiphy() {
            loadGiphy(messageRow: messageRow, bubbleSize: bubbleSize)
        } else {
            imageLoadingFailed()
        }
    }
    
    override func imageLoadingFailed() {
        lockedPaidItemOverlayView.isHidden = true
        
        super.imageLoadingFailed()
    }
    
    override func toggleLoadingImage(loading: Bool) {
        super.toggleLoadingImage(loading: loading)
    }
    
    override func loadImageInBubble(
        messageRow: TransactionMessageRow,
        size: CGSize,
        image: UIImage? = nil,
        gifData: Data? = nil
    ) {
        super.loadImageInBubble(messageRow: messageRow, size: size)
    
        toggleLoadingImage(loading: false)
        pictureImageView.image = nil
        
        bubbleView.showIncomingPictureBubble(
            messageRow: messageRow,
            size: size,
            image: image,
            gifData: gifData
        )
    }
}

extension PictureReceivedTableViewCell : PaidAttachmentViewDelegate {
    func didTapPayButton() {
        if let message = messageRow?.transactionMessage {
            let price = message.getAttachmentPrice() ?? 0
            paidAttachmentView.configure(status: TransactionMessage.TransactionMessageType.purchase, price: price)
            delegate?.didTapPayAttachment(message: message)
        }
    }
}
