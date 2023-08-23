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
    
    func configure(
        fileInfo: MessageTableCellState.FileInfo
    ) {
        contentView.backgroundColor = UIColor.Sphinx.ReceivedMsgBG.withAlphaComponent(0.95)
        iconLabel.text = "insert_drive_file"
        
        fileNameLabel.text = fileInfo.fileName
        pagesLabel.text = "\(fileInfo.pagesCount ?? 0) \("pages".localized)"
    }
    
    func configure(
        data: Data,
        fileName: String
    ) {
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
