//
//  MessageReplyView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 10/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

@objc protocol MessageReplyViewDelegate: class {
    @objc optional func didCloseView()
    @objc optional func shouldScrollTo(message: TransactionMessage)
}

class MessageReplyView: UIView {
    
    weak var delegate: MessageReplyViewDelegate?

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var topLine: UIView!
    
    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var senderLabelYConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messageLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomDivider: UIView!
    @IBOutlet weak var leftBar: UIView!
    @IBOutlet weak var leftBarLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var imageContainerWidth: NSLayoutConstraint!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var overlay: UIView!
    @IBOutlet weak var overlayIcon: UILabel!
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var rowButton: UIButton!
    
    var message: TransactionMessage? = nil
    var purchaseAcceptMessage: TransactionMessage? = nil
    var podcastComment: PodcastComment? = nil
    
    static let kMessageReplyHeight: CGFloat = 50
    let kWideContainerWidth: CGFloat = 47
    let kThinContainerWidth: CGFloat = 25
    
    let kAudioIcon = ""
    let kVideoIcon = ""
    let kFileIcon = "insert_drive_file"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("MessageReplyView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        toggleMediaContainer(show: false, width: 0)
    }
    
    func resetView() {
        senderLabel.text = ""
        messageLabel.text = ""
        
        imageView.image = nil
        overlay.isHidden = true
        
        senderLabelYConstraint.constant = -10
        senderLabel.superview?.layoutIfNeeded()
        
        toggleImageContainer(show: false)
    }
    
    func toggleElements(isRow: Bool) {
        topLine.isHidden = isRow
        closeButton.isHidden = isRow
        rowButton.isHidden = !isRow
    }
    
    func commonConfiguration(
        message: TransactionMessage?,
        delegate: MessageReplyViewDelegate,
        isIncoming: Bool = true
    ) {
        guard let message = message, let owner = ContactsService.sharedInstance.owner else {
            return
        }
        
        self.delegate = delegate
        self.message = message
        self.purchaseAcceptMessage = message.getPurchaseAcceptItem()
        
        resetView()
        
        leftBar.backgroundColor = ChatHelper.getSenderColorFor(message: message)
        
        let senderAlias = message.getMessageSenderNickname(
            owner: owner,
            contact: ContactsService.sharedInstance.getContactWith(id: message.senderId)
        )
        
        configureWith(
            title: senderAlias,
            message: message.getReplyMessageContent(),
            isIncoming: isIncoming
        )
        
        if
            message.isMediaAttachment() ||
            message.isGiphy()
        {
            configureMediaAttachment()
        }
    }
    
    func configureWith(
        title: String,
        message: String,
        isIncoming: Bool = true
    ) {
        senderLabel.text = title
        senderLabelYConstraint.constant = message.isEmpty ? 0 : -9
        senderLabel.superview?.layoutIfNeeded()
        
        bottomDivider.backgroundColor = isIncoming ? UIColor.Sphinx.ReplyDividerReceived : UIColor.Sphinx.ReplyDividerSent
        messageLabel.textColor = isIncoming ? UIColor.Sphinx.WashedOutReceivedText : UIColor.Sphinx.WashedOutSentText
        messageLabel.text = message
    }
    
    func configureForKeyboard(
        with message: TransactionMessage,
        delegate: MessageReplyViewDelegate
    ) {
        self.backgroundColor = UIColor.Sphinx.HeaderBG
        
        commonConfiguration(message: message, delegate: delegate)
        adjustMargins(isRow: false)
        toggleElements(isRow: false)
        
        isHidden = false
    }
    
    func configureForKeyboard(
        with podcastComment: PodcastComment,
        and delegate: MessageReplyViewDelegate
    ) {
        self.backgroundColor = UIColor.Sphinx.HeaderBG
        
        self.delegate = delegate
        self.podcastComment = podcastComment
        
        resetView()
        
        let timeString = (podcastComment.timestamp ?? 0).getPodcastTimeString()
        let title = podcastComment.title ?? "title.not.available".localized
        let message = "Share audio clip: \(timeString)"
        configureWith(title: title, message: message, isIncoming: true)
        
        adjustMargins(isRow: false, isIncoming: false)
        toggleElements(isRow: false)
        
        isHidden = false
    }
    
    func resetAndHideView() {
        self.podcastComment = nil
        self.message = nil
        self.isHidden = true
    }
    
    func adjustMargins(
        isRow: Bool,
        isIncoming: Bool = false
    ) {
        if isRow {
            let defaultMargin: CGFloat = 10
            messageLabelTrailingConstraint.constant = defaultMargin
            leftBarLeadingConstraint.constant = defaultMargin
        } else {
            messageLabelTrailingConstraint.constant = 45
            leftBarLeadingConstraint.constant = 15
        }
        self.layoutIfNeeded()
    }
    
    func configureMediaAttachment() {
        guard let message = message else {
            return
        }
        
        if message.isAudio() {
            configureAudio()
        } else if message.isVideo() {
            configureVideo()
        } else if message.isGiphy() {
            configureGif()
        } else if message.isPDF() || message.isPicture() {
            configureImage()
        } else {
            configureFile()
        }
    }
    
    func configureFile() {
        imageView.image = nil
        toggleOverlay(show: true, color: UIColor.clear, icon: kFileIcon, textColor: UIColor.Sphinx.Text)
        toggleImageContainer(show: true)
    }
    
    func configureGif() {
        guard let message = message else {
            return
        }
        let messageContent = message.messageContent ?? ""
        
        if let url = GiphyHelper.getUrlFrom(message: messageContent) {
            GiphyHelper.getGiphyDataFrom(
                url: url,
                messageId: message.id,
                completion: { (data, messageId) in
                    if let data = data, let img = UIImage.sd_image(withGIFData: data) {
                        self.imageView.image = img
                        self.toggleImageContainer(show: true)
                    } else {
                        self.toggleImageContainer(show: false)
                    }
                }
            )
            return
        }
        
        self.toggleImageContainer(show: false)
    }
    
    func configureImage() {
        guard let message = message else {
            return
        }
        
        toggleImageContainer(show: true)
        
        if let url = purchaseAcceptMessage?.getMediaUrlFromMediaToken() ?? message.getMediaUrlFromMediaToken() {
            MediaLoader.loadImage(
                url: url,
                message: message,
                mediaKey: purchaseAcceptMessage?.mediaKey ?? message.mediaKey,
                completion: { messageId, image in
                    if messageId != message.id {
                        return
                    }
                    self.imageView.image = image
                },
                errorCompletion: { messageId in
                    self.toggleImageContainer(show: false)
                }
            )
        } else {
            toggleImageContainer(show: false)
        }
    }
    
    func configureVideo() {
        guard let message = message else {
            return
        }
        
        toggleVideoContainer(show: true)
        
        if let url = purchaseAcceptMessage?.getMediaUrlFromMediaToken() ?? message.getMediaUrlFromMediaToken() {
            if let image = MediaLoader.getImageFromCachedUrl(url: url.absoluteString) {
                self.imageView.image = image
                return
            }
        }
        toggleMediaContainer(show: true, width: kThinContainerWidth)
        toggleOverlay(show: true, color: UIColor.clear, icon: kVideoIcon, textColor: UIColor.white)
    }
    
    func configureAudio() {
        toggleAudioContainer(show: true)
    }
    
    func toggleMediaContainer(show: Bool, width: CGFloat) {
        imageContainerWidth.constant = show ? width : 0
        imageContainer.superview?.layoutIfNeeded()
        imageContainer.isHidden = !show
    }
    
    func toggleOverlay(show: Bool, color: UIColor, icon: String, textColor: UIColor) {
        overlay.isHidden = false
        overlay.backgroundColor = color
        overlayIcon.text = icon
        overlayIcon.textColor = textColor
    }
    
    func toggleImageContainer(show: Bool) {
        toggleMediaContainer(show: show, width: kWideContainerWidth)
    }
    
    func toggleAudioContainer(show: Bool) {
        toggleMediaContainer(show: show, width: kThinContainerWidth)
        toggleOverlay(show: show, color: UIColor.clear, icon: kAudioIcon, textColor: UIColor.Sphinx.Text)
    }
    
    func toggleVideoContainer(show: Bool) {
        toggleMediaContainer(show: show, width: kWideContainerWidth)
        toggleOverlay(show: show, color: UIColor.black.withAlphaComponent(0.6), icon: kVideoIcon, textColor: UIColor.white)
    }
    
    func getViewHeight() -> CGFloat {
        return isHidden ? 0 : self.frame.height
    }
    
    func getReplyingMessage() -> TransactionMessage? {
        if let message = message, !isHidden {
            return message
        }
        return nil
    }
    
    func getReplyingPodcast() -> PodcastComment? {
        if let podcastComment = podcastComment, !isHidden {
            return podcastComment
        }
        return nil
    }
    
    @IBAction func rowButtonTouched() {
        if let message = self.message {
            delegate?.shouldScrollTo?(message: message)
        }
    }
    
    @IBAction func closeButtonTouched() {
        isHidden = true
        SoundsPlayer.playHaptic()
        delegate?.didCloseView?()
    }
}
