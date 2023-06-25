//
//  NewMessageReplyView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol NewMessageReplyViewDelegate: class {
    func didTapMessageReplyView()
}

class NewMessageReplyView: UIView {
    
    weak var delegate: NewMessageReplyViewDelegate?
    
    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var coloredLineView: UIView!
    
    @IBOutlet weak var mediaContainerView: UIStackView!
    
    @IBOutlet weak var imageVideoView: UIView!
    @IBOutlet weak var mediaImageView: UIImageView!
    @IBOutlet weak var videoOverlay: UIView!
    
    @IBOutlet weak var mediaIconLabel: UILabel!
    
    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var replyDivider: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("NewMessageReplyView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func configureWith(
        messageReply: BubbleMessageLayoutState.MessageReply,
        and bubble: BubbleMessageLayoutState.Bubble,
        delegate: NewMessageReplyViewDelegate? = nil
    ) {
        self.delegate = delegate
        
        messageLabel.textColor = bubble.direction.isIncoming() ? UIColor.Sphinx.WashedOutReceivedText : UIColor.Sphinx.WashedOutSentText
        
        coloredLineView.backgroundColor = messageReply.color
        senderLabel.textColor = messageReply.color
        senderLabel.text = messageReply.alias
        messageLabel.text = messageReply.message
        
        guard let mediaType = messageReply.mediaType else {
            mediaContainerView.isHidden = true
            imageVideoView.isHidden = true
            mediaIconLabel.isHidden = true
            return
        }
        
        switch(mediaType) {
        case TransactionMessage.TransactionMessageType.imageAttachment.rawValue:
            mediaIconLabel.text = "photo_library"
            break
        case TransactionMessage.TransactionMessageType.videoAttachment.rawValue:
            mediaIconLabel.text = "videocam"
            break
        case TransactionMessage.TransactionMessageType.audioAttachment.rawValue:
            mediaIconLabel.text = "mic"
            break
        case TransactionMessage.TransactionMessageType.fileAttachment.rawValue:
            mediaIconLabel.text = "description"
            break
        case TransactionMessage.TransactionMessageType.pdfAttachment.rawValue:
            mediaIconLabel.text = "picture_as_pdf"
            break
        default:
            break
        }
        
        mediaContainerView.isHidden = false
        mediaIconLabel.isHidden = false
    }

    @IBAction func buttonTouched() {
        delegate?.didTapMessageReplyView()
    }
}
