//
//  MediaMessageView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class MediaMessageView: UIView {
    
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
    
    func configureWith(
        messageMedia: BubbleMessageLayoutState.MessageMedia
    ) {
        mediaImageView.image = messageMedia.image
        
        paidContentOverlay.isHidden = !messageMedia.isPaid
        fileInfoView.isHidden = !messageMedia.isPdf || messageMedia.loading
        gifOverlay.isHidden = !messageMedia.isGif || messageMedia.loading
        videoOverlay.isHidden = !messageMedia.isVideo || messageMedia.loading
        
        loadingContainer.isHidden = !messageMedia.loading
        
        if messageMedia.loading {
            loadingImageView.rotate()
        } else {
            loadingImageView.stopRotating()
        }
        
        mediaNotAvailableView.isHidden = !messageMedia.failed
        mediaNotAvailableIcon.isHidden = !messageMedia.failed
        
        if let fileInfo = messageMedia.fileInfo {
            fileInfoView.configure(fileInfo: fileInfo)
            fileInfoView.isHidden = false
        } else {
            fileInfoView.isHidden = true
        }
    }
}
