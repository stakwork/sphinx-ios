//
//  FileDetailsView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol FileDetailsViewDelegate: class {
    func didTapDownloadButton()
}

class FileDetailsView: UIView {
    
    weak var delegate: FileDetailsViewDelegate?

    @IBOutlet private var contentView: UIView!

    @IBOutlet weak var fileIconLabel: UILabel!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var fileSizeLabel: UILabel!
    
    @IBOutlet weak var downloadFileButton: UIButton!
    @IBOutlet weak var downloadingWheel: UIActivityIndicatorView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("FileDetailsView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func configureWith(
        mediaData: MessageTableCellState.MediaData?,
        and delegate: FileDetailsViewDelegate?
    ) {
        self.delegate = delegate
        
        fileNameLabel.text = mediaData?.fileInfo?.fileName ?? "file".localized
        fileSizeLabel.text = mediaData?.fileInfo?.fileSize.formattedSize ?? "- kb"
        
        downloadFileButton.isHidden = mediaData == nil
        downloadingWheel.isHidden = mediaData != nil
        
        if let _ = mediaData {
            downloadFileButton.isHidden = false
            downloadingWheel.isHidden = true
            downloadingWheel.stopAnimating()
        } else {
            downloadFileButton.isHidden = true
            downloadingWheel.isHidden = false
            downloadingWheel.startAnimating()
        }
    }
    
    @IBAction func downloadButtonTouched() {
        delegate?.didTapDownloadButton()
    }
    
}
