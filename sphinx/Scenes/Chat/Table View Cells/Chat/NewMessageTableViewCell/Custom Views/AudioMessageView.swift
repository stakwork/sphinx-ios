//
//  AudioMessageView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class AudioMessageView: UIView {

    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var durationView: UIView!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var currentTimeView: UIView!
    @IBOutlet weak var tapHandlerView: UIView!
    
    @IBOutlet weak var progressViewWidthConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("AudioMessageView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        durationView.layer.cornerRadius = durationView.bounds.height / 2
        progressView.layer.cornerRadius = progressView.bounds.height / 2
        currentTimeView.layer.cornerRadius = currentTimeView.bounds.height / 2
    }

}
