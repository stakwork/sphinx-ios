//
//  FileSentTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/09/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import UIKit

class FileSentTableViewCell: CommonFileTableViewCell, MediaUploadingCellProtocol, MessageRowProtocol {
    
    @IBOutlet weak var seenSign: UILabel!
    @IBOutlet weak var attachmentPriceView: AttachmentPriceView!
    @IBOutlet weak var bubbleViewHeight: NSLayoutConstraint!
    
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
        setBubbleViewHeight()
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
    
    func setBubbleViewHeight() {
        bubbleViewHeight.constant = messageRow!.isPaidSentAttachment ? CommonFileTableViewCell.kPaidFileBubbleHeight : CommonFileTableViewCell.kFileBubbleHeight
        bubbleView.layoutIfNeeded()
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
        
        let bubbleHeight = messageRow.isPaidSentAttachment ? CommonFileTableViewCell.kPaidFileBubbleHeight : CommonFileTableViewCell.kFileBubbleHeight
        let bubbleSize = CGSize(width: CommonFileTableViewCell.kFileBubbleWidth, height: bubbleHeight)
        bubbleView.showOutgoingFileBubble(messageRow: messageRow, size: bubbleSize)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: bubbleSize, incoming: false)
        
        tryLoadingData(messageRow: messageRow, bubbleSize: bubbleSize)
        
        messageBubbleView.clearBubbleView()
        if messageRow.transactionMessage.hasMessageContent() {
            let (label, _) = messageBubbleView.showOutgoingMessageBubble(messageRow: messageRow, fixedBubbleWidth: CommonFileTableViewCell.kFileBubbleWidth)
            addLinksOnLabel(label: label)
        }
    }
    
    func tryLoadingData(messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        uploading = false
        
        if let nsUrl = messageRow.transactionMessage.getMediaUrl() {
            loadFile(url: nsUrl, messageRow: messageRow, bubbleSize: bubbleSize)
        } else {
            fileLoadingFailed()
        }
    }
    
    func configureMessageStatus() {
        guard let messageRow = messageRow else {
            return
        }
        
        let received = messageRow.transactionMessage.received()
        configureLockSign()
        
        seenSign.text = received ? "flash_on" : ""
        seenSign.alpha = received ? 1.0 : 0.0
    }
    
    func configureUploading() {
        guard let messageRow = messageRow, messageRow.transactionMessage.getMediaUrl() == nil else {
            return
        }
        
        if messageRow.transactionMessage?.isCancelled() ?? false {
            return
        }
        
        if let data = messageRow.transactionMessage?.uploadingObject?.getUploadData() {
            uploading = true
            
            let progress = messageRow.transactionMessage?.uploadingProgress ?? 0
            
            seenSign.text = ""
            lockSign.text = ""
            
            let uploadedString = String(format: "uploaded.progress".localized, progress)
            dateLabel.text = uploadedString
            dateLabel.font = UIFont(name: "Roboto-Medium", size: 10.0)!
            
            let decryptedData = messageRow.transactionMessage?.uploadingObject?.getDecryptedData()
            fileNameLabel.text = messageRow.transactionMessage?.mediaFileName ?? "file".localized
            fileSizeLabel.text = decryptedData?.formattedSize ?? data.formattedSize
            
            loading = true
            
            for subview in messageBubbleView.getSubviews() {
                if subview.tag == MessageBubbleView.kMessageLabelTag {
                    subview.alpha = 0.5
                }
            }
        }
    }
    
    func isUploading() -> Bool {
        return uploading && self.messageRow?.transactionMessage.uploadingObject?.getUploadData() != nil
    }
    
    func configureUploadingProgress(progress: Int, finishUpload: Bool) {
        messageRow?.transactionMessage?.uploadingProgress = progress
        let uploadedString = String(format: "uploaded.progress".localized, progress)
        dateLabel.text = uploadedString
    }
    
}
