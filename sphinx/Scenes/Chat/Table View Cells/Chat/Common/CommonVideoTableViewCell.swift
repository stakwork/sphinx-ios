//
//  CommonVideoTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 13/02/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import AVFoundation

class CommonVideoTableViewCell : CommonReplyTableViewCell {
    
    @IBOutlet weak var bubbleView: PictureBubbleView!
    @IBOutlet weak var messageBubbleView: MessageBubbleView!
    @IBOutlet weak var lockSign: UILabel!
    @IBOutlet weak var imageLoadingView: UIView!
    @IBOutlet weak var imagePreloader: UIImageView!
    @IBOutlet weak var playButtonContainer: UIView!
    @IBOutlet weak var videoNotAvailableContainer: UIView!
    
    var videoData : Data? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageLoadingView.backgroundColor = UIColor.Sphinx.Body.withAlphaComponent(0.5)
    }
    
    override func getBubbbleView() -> UIView? {
        return messageBubbleView
    }
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        self.configureRow(messageRow: messageRow, contact: contact, chat: chat)
    }
    
    func loadVideo(url: URL, messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        toggleLoadingImage(loading: true)

        MediaLoader.loadVideo(url: url, message: messageRow.transactionMessage, completion: { (messageId, data, image) in
            if self.isDifferentRow(messageId: messageId) { return }
            
            self.videoData = data
            if let image = image {
                self.loadImageInBubble(messageRow: messageRow, size: bubbleSize, image: image)
            }
            self.videoReady()
        }, errorCompletion: { messageId in
            if self.isDifferentRow(messageId: messageId) { return }
            
            self.videoLoadingFailed()
        })
    }
    
    func loadImageInBubble(messageRow: TransactionMessageRow, size: CGSize, image: UIImage) {}
    
    func toggleLoadingImage(loading: Bool) {
        videoNotAvailableContainer.alpha = 0.0
        playButtonContainer.alpha = 0.0
        imageLoadingView.alpha = loading ? 1.0 : 0.0
        if loading {
            imagePreloader.rotate()
        } else {
            imagePreloader.stopRotating()
        }
    }
    
    func videoReady() {
        toggleLoadingImage(loading: false)
        videoNotAvailableContainer.alpha = 0.0
        playButtonContainer.alpha = 1.0
    }
    
    func videoLoadingFailed() {
        toggleLoadingImage(loading: false)
        
        if !(messageRow?.transactionMessage?.isPaidAttachment() ?? false) {
            videoNotAvailableContainer.alpha = 1.0
        }
    }
    
    func configureLockSign() {
        let encrypted = (messageRow?.transactionMessage.encrypted ?? false) && (messageRow?.transactionMessage.hasMediaKey() ?? false)
        lockSign.textColor = UIColor.Sphinx.WashedOutReceivedText
        lockSign.text = encrypted ? "lock" : ""
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        return CommonPictureTableViewCell.getRowHeight(messageRow: messageRow)
    }
    
}
