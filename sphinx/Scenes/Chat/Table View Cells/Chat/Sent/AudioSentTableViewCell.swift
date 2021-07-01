//
//  AudioSentTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 28/02/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import UIKit

class AudioSentTableViewCell: CommonAudioTableViewCell, MediaUploadingCellProtocol, MessageRowProtocol {
    
    @IBOutlet weak var seenSign: UILabel!
    @IBOutlet weak var errorContainer: UIView!
    @IBOutlet weak var errorMessageLabel: UILabel!
    
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
        configureAudio()
        configureUploading()
        configureMessageStatus()

        if messageRow.shouldShowRightLine {
           addRightLine()
        }

        if messageRow.shouldShowLeftLine {
           addLeftLine()
        }
    }
    
    func configureAudio() {
        guard let messageRow = messageRow else {
           return
        }

        let bubbleSize = getBubbleSize()
        bubbleView.showOutgoingAudioBubble(messageRow: messageRow, size: bubbleSize)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: bubbleSize, incoming: false)

        tryLoadingAudio(messageRow: messageRow, bubbleSize: bubbleSize)
    }

    func tryLoadingAudio(messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        uploading = false

        if let url = messageRow.transactionMessage.getMediaUrl() {
            loadAudio(url: url, messageRow: messageRow, bubbleSize: bubbleSize)
        } else if !uploading {
            audioLoadingFailed()
        }
    }

    override func audioLoadingFailed() {
        super.audioLoadingFailed()
        configureMessageStatus()
    }

    override func toggleLoadingAudio(loading: Bool) {
        super.toggleLoadingAudio(loading: loading)
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

        if let _ = messageRow.transactionMessage?.uploadingObject?.getUploadData() {
            uploading = true
            toggleLoadingAudio(loading: true)
            let progress = messageRow.transactionMessage?.uploadingProgress ?? 0

            seenSign.text = ""
            lockSign.text = ""

            let uploadedString = String(format: "uploaded.progress".localized, progress)
            dateLabel.text = uploadedString
            dateLabel.font = UIFont(name: "Roboto-Medium", size: 10.0)!
        }
    }

    func isUploading() -> Bool {
        return uploading && self.messageRow?.transactionMessage.uploadingObject?.getUploadData() != nil
    }

    func configureUploadingProgress(progress: Int, finishUpload: Bool) {
        let uploadedString = String(format: "uploaded.progress".localized, progress)
        dateLabel.text = uploadedString
    }
}
