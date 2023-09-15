//
//  ThreadMediaView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/08/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class ThreadMediaView: UIView {
    
    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var mediaImageView: UIImageView!
    @IBOutlet weak var loadingContainer: UIView!
    @IBOutlet weak var loadingImageView: UIImageView!
    @IBOutlet weak var gifOverlay: GifOverlayView!
    @IBOutlet weak var videoOverlay: UIView!
    @IBOutlet weak var mediaNotAvailableView: UIView!
    @IBOutlet weak var mediaNotAvailableIcon: UILabel!
    @IBOutlet weak var fileContainer: UIView!
    @IBOutlet weak var fileIcon: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("ThreadMediaView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        fileContainer.backgroundColor = UIColor.Sphinx.ReceivedMsgBG.withAlphaComponent(0.9)
    }
    
    func configureWith(
        messageMedia: BubbleMessageLayoutState.MessageMedia,
        mediaData: MessageTableCellState.MediaData?,
        bubble: BubbleMessageLayoutState.Bubble
    ) {
        configureMediaNotAvailableIconWith(messageMedia: messageMedia)
        
        if let mediaData = mediaData {
            fileContainer.isHidden = !messageMedia.isPdf || mediaData.failed
            gifOverlay.isHidden = !messageMedia.isGif || mediaData.failed
            videoOverlay.isHidden = !messageMedia.isVideo || mediaData.failed
            
            mediaImageView.image = mediaData.image
            mediaImageView.contentMode = messageMedia.isPaymentTemplate ? .scaleAspectFit : .scaleAspectFill
            
            if let _ = mediaData.fileInfo, messageMedia.isPdf {
                configureForPDF()
            } else {
                fileContainer.isHidden = true
            }
            
            loadingContainer.isHidden = true
            loadingImageView.stopRotating()
            
            mediaNotAvailableView.isHidden = !mediaData.failed
            mediaNotAvailableIcon.isHidden = !mediaData.failed
        } else {
            fileContainer.isHidden = true
            videoOverlay.isHidden = true
            gifOverlay.isHidden = true
            
            loadingContainer.isHidden = false
            mediaImageView.image = nil
            loadingImageView.rotate()
        }
    }
    
    func configureForGenericFile() {
        fileContainer.isHidden = false
        fileIcon.text = "insert_drive_file"
    }
    
    func configureForPDF() {
        fileContainer.isHidden = false
        fileIcon.text = "picture_as_pdf"
    }
    
    func configureForAudio() {
        fileContainer.isHidden = false
        fileIcon.text = ""
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

}
