//
//  CommonDirectPaymentTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class CommonDirectPaymentTableViewCell : CommonChatTableViewCell {
    
    @IBOutlet weak var bubbleView: PaymentInvoiceView!
    @IBOutlet weak var lockSign: UILabel!
    @IBOutlet weak var paymentIcon: UIImageView!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var pictureBubbleView: PictureBubbleView!
    @IBOutlet weak var separatorLine: UIView!
    @IBOutlet weak var pictureBubbleViewHeight: NSLayoutConstraint!
    @IBOutlet weak var imageLoadingView: UIView!
    @IBOutlet weak var imagePreloader: UIImageView!
    @IBOutlet weak var imageNotAvailable: UIImageView!
    @IBOutlet weak var bubbleWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var recipientAvatarView: ChatAvatarView!
    
    static let kLabelSideMargins: CGFloat = 46
    static let kBubbleMaximumWidth: CGFloat = 210
    static let kAmountLabelSideMargins: CGFloat = 112
    static let kLabelTopMargin: CGFloat = 60
    static let kLabelBottomMargin: CGFloat = 20
    static let kRecipientViewWidth: CGFloat = 56
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageLoadingView.backgroundColor = UIColor.clear
        messageLabel.font = UIFont.getMessageFont()
        amountLabel.font = UIFont.getAmountFont()
    }
    
    func configurePayment(
        messageRow: TransactionMessageRow,
        contact: UserContact?,
        chat: Chat?,
        incoming: Bool
    ) {
        super.configureRow(messageRow: messageRow, contact: contact, chat: chat)

        commonConfigurationForMessages()
    
        let (bubbleWidth, labelWidth) = CommonDirectPaymentTableViewCell.getBubbleAndLabelWidth(messageRow: messageRow)
        bubbleWidthConstraint.constant = bubbleWidth
        bubbleView.superview?.layoutIfNeeded()

        let labelHeight = CommonDirectPaymentTableViewCell.getLabelHeight(messageRow: messageRow, width: labelWidth)
        let bubbleHeight = labelHeight + CommonDirectPaymentTableViewCell.kLabelTopMargin + CommonDirectPaymentTableViewCell.kLabelBottomMargin
        let bubbleSize = CGSize(width: bubbleWidth, height: bubbleHeight)
        
        if incoming {
            bubbleView.showIncomingDirectPaymentBubble(messageRow: messageRow, size: bubbleSize, hasImage: messageRow.isPaymentWithImage())
        } else {
            bubbleView.showOutgoingDirectPaymentBubble(messageRow: messageRow, size: bubbleSize, hasImage: messageRow.isPaymentWithImage())
        }
        
        let encrypted = messageRow.encrypted
        lockSign.text = encrypted ? "lock" : ""
        
        setAmountAndTextLabels(messageRow: messageRow)
        configureRecipientInfo()
        tryLoadingImage(messageRow: messageRow)

        bubbleView.bringSubviewToFront(paymentIcon)
        bubbleView.bringSubviewToFront(amountLabel)
        bubbleView.bringSubviewToFront(unitLabel)
        bubbleView.bringSubviewToFront(messageLabel)
        bubbleView.bringSubviewToFront(recipientAvatarView)

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    public static func getBubbleAndLabelWidth(messageRow: TransactionMessageRow) -> (CGFloat, CGFloat) {
        let recipientViewWidth = (messageRow.transactionMessage?.chat?.isPublicGroup() ?? false) ? kRecipientViewWidth : 0
        let amountBubbleWidth = getAmountLabelWidth(messageRow: messageRow) + kAmountLabelSideMargins + recipientViewWidth
        var labelBubbleWidth = getLabelSize(messageRow: messageRow).width + kLabelSideMargins
        if labelBubbleWidth > kBubbleMaximumWidth {
            let labelHeight = getLabelHeight(messageRow: messageRow, width: kBubbleMaximumWidth - kLabelSideMargins)
            labelBubbleWidth = getLabelSize(messageRow: messageRow, width: kBubbleMaximumWidth - kLabelSideMargins, height: labelHeight).width + kLabelSideMargins
        }
        let maxBubbleWidth = max(amountBubbleWidth, labelBubbleWidth)
        let hasImage = messageRow.isPaymentWithImage()
        let bubbleWidth = maxBubbleWidth > kBubbleMaximumWidth || hasImage ? kBubbleMaximumWidth : maxBubbleWidth
        let labelWidth = bubbleWidth - kLabelSideMargins
        
        return (bubbleWidth, labelWidth)
    }
    
    func setAmountAndTextLabels(messageRow: TransactionMessageRow) {
        let text = messageRow.transactionMessage.messageContent ?? ""
        let amountString = messageRow.getAmountString()
        amountLabel.text = amountString
        messageLabel.text = text
    }
    
    func configureRecipientInfo() {
        guard let message = messageRow?.transactionMessage, (self.chat?.isPublicGroup() ?? false) else {
            recipientAvatarView.isHidden = true
            return
        }

        recipientAvatarView.isHidden = false
        recipientAvatarView.configureForRecipientWith(message: message)
    }
    
    func tryLoadingImage(messageRow: TransactionMessageRow) {
        let hasImage = messageRow.isPaymentWithImage()
        separatorLine.alpha = hasImage ? 1.0 : 0.0
        pictureBubbleView.clearBubbleView()
        
        toggleLoadingImage(loading: false)
        imageNotAvailable.alpha = 0.0
        
        if hasImage {
            let (bubbleWidth, _) = CommonDirectPaymentTableViewCell.getBubbleAndLabelWidth(messageRow: messageRow)
            let imageHeight = CommonDirectPaymentTableViewCell.getImageHeight(messageRow: messageRow, bubbleWidth: bubbleWidth)
            let bubbleSize = CGSize(width: bubbleWidth, height: imageHeight)
            
            pictureBubbleViewHeight.constant = imageHeight
            pictureBubbleView.superview?.layoutIfNeeded()
            
            loadImageInBubble(messageRow: messageRow, size: bubbleSize, image: nil)
            
            if let url = messageRow.transactionMessage.getTemplateURL() {
                loadImage(url: url, messageRow: messageRow, bubbleSize: bubbleSize)
            } else {
                imageLoadingFailed()
            }
        }
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
        imageNotAvailable.image = UIImage(named: "imageNotAvailable")
        imageNotAvailable.alpha = 1.0
        imageNotAvailable.tintColorDidChange()
    }
    
    func loadImage(url: URL, messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        toggleLoadingImage(loading: true)

        MediaLoader.loadImage(url: url, message: messageRow.transactionMessage, completion: { messageId, image in
            if self.isDifferentRow(messageId: messageId) { return }
            self.loadImageInBubble(messageRow: messageRow, size: bubbleSize, image: image)
        }, errorCompletion: { messageId in
            if self.isDifferentRow(messageId: messageId) { return }
            self.imageLoadingFailed()
        })
    }
    
    func loadImageInBubble(messageRow: TransactionMessageRow, size: CGSize, image: UIImage?) {
        toggleLoadingImage(loading: false)
        let incoming = messageRow.isIncoming()
        
        if incoming {
            pictureBubbleView.showIncomingPictureBubble(messageRow: messageRow, size: size, image: image, contentMode: .resizeAspect)
        } else {
            pictureBubbleView.showOutgoingPictureBubble(messageRow: messageRow, size: size, image: image, contentMode: .resizeAspect)
        }
    }
    
    public static func getLabelHeight(messageRow: TransactionMessageRow, width: CGFloat) -> CGFloat {
        let text = messageRow.transactionMessage.messageContent ?? ""
        let labelHeight = getLabelSize(messageRow: messageRow, width: width).height
        return text.isEmpty ? -17 : labelHeight
    }
    
    public static func getLabelSize(messageRow: TransactionMessageRow, width: CGFloat? = nil, height: CGFloat? = nil) -> CGSize {
        let text = messageRow.transactionMessage.messageContent ?? ""
        let labelSize = UILabel.getLabelSize(width: width, height: height, text: text, font: UIFont.getMessageFont())
        return labelSize
    }
    
    public static func getAmountLabelWidth(messageRow: TransactionMessageRow) -> CGFloat {
        let amountString = messageRow.getAmountString()
        let labelWidth = UILabel.getLabelSize(width: .greatestFiniteMagnitude, text: amountString, font: UIFont.getAmountFont()).width
        return labelWidth
    }
    
    public static func getImageHeight(messageRow: TransactionMessageRow, bubbleWidth: CGFloat) -> CGFloat {
        let hasImage = messageRow.transactionMessage.mediaToken != nil
        let imageRatio = messageRow.transactionMessage.getImageRatio() ?? 1.0
        return hasImage ? bubbleWidth * CGFloat(imageRatio) : 0.0
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let (bubbleWidth, labelWidth) = CommonDirectPaymentTableViewCell.getBubbleAndLabelWidth(messageRow: messageRow)
        
        let labelHeight = getLabelHeight(messageRow: messageRow, width: labelWidth)
        let imageHeight = getImageHeight(messageRow: messageRow, bubbleWidth: bubbleWidth)
            
        return labelHeight + imageHeight + kLabelTopMargin + kLabelBottomMargin + kBubbleTopMargin + kBubbleBottomMargin
    }
}
