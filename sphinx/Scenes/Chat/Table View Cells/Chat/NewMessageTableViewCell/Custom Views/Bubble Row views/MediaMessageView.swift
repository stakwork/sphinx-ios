//
//  MediaMessageView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol MediaMessageViewDelegate: class {
    func didTapMediaButton()
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
        messageMedia: BubbleMessageLayoutState.MessageMedia,
        mediaData: MessageTableCellState.MediaData?,
        and delegate: MediaMessageViewDelegate?
    ) {
        self.delegate = delegate
        
        if let mediaData = mediaData {
            paidContentOverlay.isHidden = !messageMedia.isPaid
            fileInfoView.isHidden = !messageMedia.isPdf
            gifOverlay.isHidden = !messageMedia.isGif
            videoOverlay.isHidden = !messageMedia.isVideo
            
            mediaImageView.image = mediaData.image
            
            if let fileInfo = mediaData.fileInfo {
                fileInfoView.configure(fileInfo: fileInfo)
                fileInfoView.isHidden = false
            } else {
                fileInfoView.isHidden = true
            }
            
            loadingContainer.isHidden = true
            loadingImageView.stopRotating()
        } else {
            let failed = mediaData?.failed == true
            
            mediaImageView.image = nil
            fileInfoView.isHidden = true
            
            loadingImageView.rotate()
            loadingContainer.isHidden = failed
            
            mediaNotAvailableView.isHidden = !failed
            mediaNotAvailableIcon.isHidden = !failed
        }
    }
    
    @IBAction func mediaButtonTouched() {
        delegate?.didTapMediaButton()
    }
}
