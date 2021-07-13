//
//  AudioRecordingTooltip.swift
//  sphinx
//
//  Created by Tomas Timinskas on 09/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class AudioRecordingTooltip: UIView {
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var bottomArrow: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("AudioRecordingTooltip", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        bubbleView.layer.cornerRadius = bubbleView.frame.size.height / 2
        bottomArrow.layer.cornerRadius = bottomArrow.frame.size.width
        
        bubbleView.addShadow(offset: CGSize(width: 0, height: 0), radius: 3.0)
    }
}
