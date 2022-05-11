//
//  VideoReceivedTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 13/02/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class VideoReceivedTableViewCell: CommonVideoTableViewCell, MessageRowProtocol {
    
    @IBOutlet weak var errorContainer: UIView!
    @IBOutlet weak var errorMessageLabel: UILabel!
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
        
        configureImageAndMessage()
        commonConfigurationForMessages()
        configureStatus()
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
    
    
    func configureImageAndMessage() {
        guard let messageRow = messageRow else {
            return
        }
        
        let hasContent = messageRow.transactionMessage.hasMessageContent()
        let bubbleSize = CGSize(
            width: PictureSentTableViewCell.kPictureBubbleHeight,
            height: PictureSentTableViewCell.kPictureBubbleHeight
        )
        
        lockedPaidItemOverlayView.isHidden = true
        lockedPaidItemOverlayLabel.text = "pay.to.unlock.video".localized.uppercased()
        lockedPaidItemOverlayLabel.addTextSpacing(value: 2)
        
        bubbleView.showIncomingPictureBubble(messageRow: messageRow, size: bubbleSize)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: bubbleSize, incoming: true)
        tryLoadingVideo(messageRow: messageRow, bubbleSize: bubbleSize)
        messageBubbleView.clearBubbleView()
        
        separatorLine.isHidden = !hasContent
        
        if hasContent || messageRow.isBoosted {
            let (label, _) = messageBubbleView.showIncomingMessageBubble(messageRow: messageRow, fixedBubbleWidth: PictureSentTableViewCell.kPictureBubbleHeight)
            addLinksOnLabel(label: label)
        }
        
        configurePayment()
        
        if messageRow.shouldShowRightLine {
            addRightLine()
        }
        
        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func tryLoadingVideo(messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        if let url = messageRow.transactionMessage.getMediaUrl() {
            loadVideo(url: url, messageRow: messageRow, bubbleSize: bubbleSize)
        } else {
            videoLoadingFailed()
        }
    }
    
    override func videoLoadingFailed() {
        super.videoLoadingFailed()
    }
    
    override func toggleLoadingImage(loading: Bool) {
        super.toggleLoadingImage(loading: loading)
    }
    
    override func loadImageInBubble(messageRow: TransactionMessageRow, size: CGSize, image: UIImage) {
        toggleLoadingImage(loading: false)
        bubbleView.showIncomingPictureBubble(messageRow: messageRow, size: size, image: image)
    }
    
    @IBAction func playButtonTouched() {
        if let videoData = videoData {
            delegate?.shouldPlayVideo(url: nil, data: videoData)
        }
    }
}

extension VideoReceivedTableViewCell : PaidAttachmentViewDelegate {
    func didTapPayButton() {
        if let message = messageRow?.transactionMessage {
            let price = message.getAttachmentPrice() ?? 0
            paidAttachmentView.configure(status: TransactionMessage.TransactionMessageType.purchase, price: price)
            delegate?.didTapPayAttachment(message: message)
        }
    }
}
