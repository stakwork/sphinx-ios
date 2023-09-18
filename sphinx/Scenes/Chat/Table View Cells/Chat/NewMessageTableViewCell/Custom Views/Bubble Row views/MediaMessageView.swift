//
//  MediaMessageView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol MediaMessageViewDelegate: class {
    func didTapMediaButton(isThreadOriginalMsg: Bool)
    
    func shouldLoadOriginalMessageMediaDataFrom(originalMessageMedia: BubbleMessageLayoutState.MessageMedia)
    func shouldLoadOriginalMessageFileDataFrom(originalMessageFile: BubbleMessageLayoutState.GenericFile)
}

class MediaMessageView: UIView {
    
    weak var delegate: MediaMessageViewDelegate?
    
    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var mediaContainer: UIView!
    
    @IBOutlet weak var mediaImageView: UIImageView!
    @IBOutlet weak var paidContentOverlay: UIView!
    @IBOutlet weak var fileInfoView: FileInfoView!
    @IBOutlet weak var loadingContainer: UIView!
    @IBOutlet weak var loadingImageView: UIImageView!
    @IBOutlet weak var gifOverlay: GifOverlayView!
    @IBOutlet weak var videoOverlay: UIView!
    @IBOutlet weak var mediaNotAvailableView: UIView!
    @IBOutlet weak var mediaNotAvailableIcon: UILabel!
    
    @IBOutlet weak var topMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomMarginConstraint: NSLayoutConstraint!
    
    var isThreadOriginalMsg = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("MediaMessageView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        mediaContainer.layer.cornerRadius = 8.0
        mediaContainer.clipsToBounds = true
    }
    
    func removeMargin() {
        setMarginTo(0)
    }
    
    func setMarginTo(
        _ margin: CGFloat
    ) {
        topMarginConstraint.constant = margin
        trailingMarginConstraint.constant = margin
        leadingMarginConstraint.constant = margin
        bottomMarginConstraint.constant = margin
        
        self.layoutIfNeeded()
    }
    
    func configureWith(
        messageMedia: BubbleMessageLayoutState.MessageMedia,
        mediaData: MessageTableCellState.MediaData?,
        isThreadOriginalMsg: Bool,
        bubble: BubbleMessageLayoutState.Bubble,
        and delegate: MediaMessageViewDelegate?
    ) {
        self.delegate = delegate
        self.isThreadOriginalMsg = isThreadOriginalMsg
        
        configureMediaNotAvailableIconWith(messageMedia: messageMedia)
        
        if let mediaData = mediaData {
            fileInfoView.isHidden = !messageMedia.isPdf || mediaData.failed
            gifOverlay.isHidden = !messageMedia.isGif || mediaData.failed
            videoOverlay.isHidden = !messageMedia.isVideo || mediaData.failed
            
            mediaImageView.image = mediaData.image
            mediaImageView.contentMode = messageMedia.isPaymentTemplate ? .scaleAspectFit : .scaleAspectFill
            
            if let fileInfo = mediaData.fileInfo {
                fileInfoView.configure(fileInfo: fileInfo)
                fileInfoView.isHidden = false
            } else {
                fileInfoView.isHidden = true
            }
            
            loadingContainer.isHidden = true
            loadingImageView.stopRotating()
            
            paidContentOverlay.isHidden = true
            
            mediaNotAvailableView.isHidden = !mediaData.failed
            mediaNotAvailableIcon.isHidden = !mediaData.failed
        } else {
            fileInfoView.isHidden = true
            videoOverlay.isHidden = true
            gifOverlay.isHidden = true
            
            if messageMedia.isPendingPayment() &&
                bubble.direction.isIncoming()
            {
                paidContentOverlay.isHidden = false
                loadingContainer.isHidden = true
                
                mediaImageView.image = UIImage(
                    named: messageMedia.isVideo ? "paidVideoBlurredPlaceholder" :  "paidImageBlurredPlaceholder"
                )
            } else {
                paidContentOverlay.isHidden = true
                loadingContainer.isHidden = false
                
                mediaImageView.image = nil
                
                loadingImageView.rotate()
            }
        }
    }
    
    func configureMediaNotAvailableIconWith(
        messageMedia: BubbleMessageLayoutState.MessageMedia
    ) {
        if messageMedia.isPdf {
            mediaNotAvailableIcon.text = "picture_as_pdf"
        } else if messageMedia.isVideo {
            mediaNotAvailableIcon.text = "videocam"
        } else {
            mediaNotAvailableIcon.text = "photo_library"
        }
    }
    
    @IBAction func mediaButtonTouched() {
        delegate?.didTapMediaButton(isThreadOriginalMsg: isThreadOriginalMsg)
    }
}
