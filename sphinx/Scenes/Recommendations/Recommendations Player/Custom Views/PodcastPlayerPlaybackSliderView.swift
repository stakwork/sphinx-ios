//
//  PodcastPlayerPlaybackSliderView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/12/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

class PodcastPlayerPlaybackSliderView: UIView {
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var durationLine: UIView!
    @IBOutlet weak var progressLine: UIView!
    @IBOutlet weak var progressLineWidth: NSLayoutConstraint!
    @IBOutlet weak var currentTimeDot: UIView!
    @IBOutlet weak var gestureHandlerView: UIView!
    @IBOutlet weak var audioLoadingWheel: UIActivityIndicatorView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("PodcastPlayerPlaybackSliderView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        currentTimeDot.layer.cornerRadius = currentTimeDot.frame.size.height / 2
    }

}
