//
//  PdfInfoView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol FileInfoViewDelegate : class {
    func didTouchDownloadButton(button: UIButton)
}

class FileInfoView: UIView {
    
    weak var delegate: FileInfoViewDelegate?
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var pagesLabel: UILabel!
    @IBOutlet weak var downloadButton: UIButton!
    
    var message: TransactionMessage! = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("FileInfoView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func configure(message: TransactionMessage) {
        self.message = message
        
        if let data = message.uploadingObject?.getDecryptedData(), let fileName = message.uploadingObject?.fileName {
            showPDFInfo(data: data, fileName: fileName)
        } else {
            fileNameLabel.text = "file.pdf"
            pagesLabel.text = "- \("pages".localized)"
        }
        
        roundCorners()
        
        if let url = message.getMediaUrl(), message.isPDF() {
            if let data = MediaLoader.getMediaDataFromCachedUrl(url: url.absoluteString) {
                self.showPDFInfo(data: data, fileName: message.mediaFileName)
            } else {
                MediaLoader.loadFileData(url: url, message: message, completion: { _, data in
                    DispatchQueue.main.async {
                        self.showPDFInfo(data: data, fileName: message.mediaFileName)
                    }
                }, errorCompletion: { _ in
                    DispatchQueue.main.async {
                        self.isHidden = true
                    }
                })
            }
        }
    }
    
    func roundCorners() {
        if message.hasMessageContent() {
            self.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 0)
        } else {
            if message.consecutiveMessages.nextMessage {
                if message.isOutgoing() {
                    self.roundCorners(corners: [.bottomLeft], radius: 6)
                } else {
                    self.roundCorners(corners: [.bottomRight], radius: 6)
                }
            } else {
                self.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 6)
            }
        }
    }
    
    func showPDFInfo(data: Data, fileName: String?) {
        if let pagesCount = data.getPDFPagesCount() {
            let pagesText = (pagesCount > 1 ? "pages" : "page").localized
            pagesLabel.text = "\(pagesCount) \(pagesText)"
        }
        fileNameLabel.text = fileName ?? "file.pdf"
    }
    
    func configure(data: Data, fileName: String) {
        contentView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        iconLabel.text = "insert_drive_file"
        fileNameLabel.text = fileName
        pagesLabel.text = data.formattedSize
        downloadButton.isHidden = true
    }
    
    @IBAction func downloadButtonTouched() {
        delegate?.didTouchDownloadButton(button: downloadButton)
    }
}
