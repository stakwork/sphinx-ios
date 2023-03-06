//
//  CommonFileTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class CommonFileTableViewCell : CommonReplyTableViewCell {
    
    @IBOutlet weak var bubbleView: FileBubbleView!
    @IBOutlet weak var messageBubbleView: MessageBubbleView!
    @IBOutlet weak var lockSign: UILabel!
    @IBOutlet weak var fileInfoContainer: UIView!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var fileSizeLabel: UILabel!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    public static let kPictureMessageMargin: CGFloat = 0.0
    public static var kFileBubbleHeight: CGFloat = 60.0
    public static var kPaidFileBubbleHeight: CGFloat = 80.0
    public static var kFileBubbleWidth: CGFloat = 250.0
    
    var loading = false {
        didSet {
            downloadButton.isHidden = loading
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.Sphinx.Text, view: self.contentView, views: [])
        }
    }
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        super.configureRow(messageRow: messageRow, contact: contact, chat: chat)
    }
    
    func loadFile(url: URL, messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        loadFileInfo(messageRow: messageRow, data: messageRow.transactionMessage.uploadingObject?.getDecryptedData())
        loading = true

        MediaLoader.getFileAttachmentData(url: url, message: messageRow.transactionMessage, completion: { (messageId, data) in
            if self.isDifferentRow(messageId: messageId) { return }
            self.getMediaItemInfo(messageRow: messageRow)
        }, errorCompletion: { messageId in
            if self.isDifferentRow(messageId: messageId) { return }
            self.getMediaItemInfo(messageRow: messageRow)
        })
    }
    
    override func getBubbbleView() -> UIView? {
        return messageBubbleView
    }
    
    func getMediaItemInfo(messageRow: TransactionMessageRow) {
        guard let message = messageRow.transactionMessage else {
            return
        }

        if let filename = message.mediaFileName, !filename.isEmpty && message.mediaFileSize > 0 {
            self.loadFileInfo(fileName: filename, size: message.mediaFileSize)
        } else if let muid = messageRow.transactionMessage.muid, !muid.isEmpty {
            AttachmentsManager.sharedInstance.getMediaItemInfo(message: message, callback: { (messageId, filename, size) in
                if self.isDifferentRow(messageId: messageId) { return }
                self.messageRow?.transactionMessage.saveFileInfo(filename: filename, size: size)
                self.loadFileInfo(fileName: filename, size: size)
            })
        }
    }
    
    func loadFileInfo(messageRow: TransactionMessageRow, data: Data? = nil) {
        loadFileInfo(fileName: messageRow.transactionMessage.mediaFileName, size: data?.count)
    }
    
    func loadFileInfo(fileName: String?, size: Int?) {
        fileNameLabel.text = fileName ?? "file".localized
        fileSizeLabel.text = size?.formattedSize ?? "- kb"
        loading = false
    }
    
    func fileLoadingFailed() {
        loading = false
        fileNameLabel.text = "File"
        fileSizeLabel.text = "- kb"
    }
    
    func configureLockSign() {
        let encrypted = (messageRow?.transactionMessage.encrypted ?? false)
        let hasMediaKey = (messageRow?.transactionMessage.hasMediaKey() ?? false)
        let isGiphy = (messageRow?.transactionMessage.isGiphy() ?? false)
        let imageEncrypted = encrypted && (hasMediaKey || isGiphy)
        lockSign.text = imageEncrypted ? "lock" : ""
    }
    
    @IBAction func downloadButtonClicked(_ sender: Any) {
        let bubbleHelper = NewMessageBubbleHelper()
        if let message = messageRow?.transactionMessage, let url = message.getMediaUrl() {
            bubbleHelper.showLoadingWheel(text: "downloading.file".localized)
            MediaLoader.loadFileData(url: url, message: message, completion: {( _, data) in
                bubbleHelper.hideLoadingWheel()
                self.delegate?.fileDownloadButtonTouched(message: message, data: data, button: self.downloadButton)
            }, errorCompletion: { _ in })
        }
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        var height: CGFloat = 0.0
        let bubbleHeight = messageRow.isPaidSentAttachment ? CommonFileTableViewCell.kPaidFileBubbleHeight : CommonFileTableViewCell.kFileBubbleHeight
        let bubbleWidth = CommonFileTableViewCell.kFileBubbleWidth
        let payButtonHeight: CGFloat = messageRow.shouldShowPaidAttachmentView() ? PaidAttachmentView.kViewHeight : 0.0
        let replyTopPadding = CommonChatTableViewCell.getReplyTopPadding(message: messageRow.transactionMessage)
        let margin = messageRow.isIncoming() ? Constants.kBubbleReceivedArrowMargin : Constants.kBubbleSentArrowMargin

        if messageRow.transactionMessage.hasMessageContent() {
            let (_, bubbleSize) = MessageBubbleView.getLabelAndBubbleSize(messageRow: messageRow, maxBubbleWidth: bubbleWidth, bubbleMargin: margin)
            height = bubbleHeight + bubbleSize.height
        } else {
            let bottomBubblePadding = messageRow.isBoosted ? Constants.kReactionsViewHeight : 0
            height = bubbleHeight + bottomBubblePadding
        }

        return height + CommonChatTableViewCell.kBubbleTopMargin + CommonChatTableViewCell.kBubbleBottomMargin + payButtonHeight + replyTopPadding
    }
    
}
