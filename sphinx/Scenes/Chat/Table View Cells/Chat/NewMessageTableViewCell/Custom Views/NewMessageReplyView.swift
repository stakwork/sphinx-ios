//
//  NewMessageReplyView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class NewMessageReplyView: UIView {
    
    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var coloredLineView: UIView!
    
    @IBOutlet weak var imageVideoView: UIView!
    @IBOutlet weak var mediaImageView: UIImageView!
    @IBOutlet weak var videoOverlay: UIView!
    
    @IBOutlet weak var audioIconLabel: UILabel!
    
    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
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

    @IBAction func buttonTouched() {
    }
}
