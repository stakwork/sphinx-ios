//
//  AudioMessageView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol AudioMessageViewDelegate: class {
    func didTapPlayPauseButton(isThreadOriginalMsg: Bool)
    
    func shouldLoadOriginalMessageAudioDataFrom(originalMessageAudio: BubbleMessageLayoutState.Audio)
}

class AudioMessageView: UIView {
    
    weak var delegate: AudioMessageViewDelegate?

    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var durationView: UIView!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var currentTimeView: UIView!
    @IBOutlet weak var tapHandlerView: UIView!
    
    @IBOutlet weak var progressViewWidthConstraint: NSLayoutConstraint!
    
    let kProgressBarLeftMargin: CGFloat = 60
    let kProgressBarRightMargin: CGFloat = 66
    
    var isThreadOriginalMsg = false
    
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
        
        loadingWheel.color = UIColor.Sphinx.Text
    }
    
    func configureWith(
        audio: BubbleMessageLayoutState.Audio,
        mediaData: MessageTableCellState.MediaData?,
        isThreadOriginalMsg: Bool,
        bubble: BubbleMessageLayoutState.Bubble,
        and delegate: AudioMessageViewDelegate
    ) {
        self.delegate = delegate
        self.isThreadOriginalMsg = isThreadOriginalMsg
        
        durationView.backgroundColor = bubble.direction.isIncoming() ? UIColor.Sphinx.WashedOutReceivedText : UIColor.Sphinx.WashedOutSentText
        
        if let audioInfo = mediaData?.audioInfo {
            playPauseButton.setTitle(
                audioInfo.playing ? "pause" : "play_arrow",
                for: .normal
            )
            
            let progressBarWidth = audio.bubbleWidth - kProgressBarLeftMargin - kProgressBarRightMargin
            let progress = audioInfo.currentTime * 1 / audioInfo.duration
            progressViewWidthConstraint.constant = progressBarWidth * progress
            
            let current:Int = Int(audioInfo.duration - audioInfo.currentTime)
            let minutes:Int = current / 60
            let seconds:Int = current % 60
            timeLabel.text = "\(minutes):\(seconds.timeString)"
            
            playPauseButton.isHidden = false
            loadingWheel.isHidden = true
            loadingWheel.stopAnimating()
        } else {
            playPauseButton.isHidden = true
            loadingWheel.isHidden = false
            loadingWheel.startAnimating()
            
            timeLabel.text = "00:00"
            progressViewWidthConstraint.constant = 0
        }
        
        progressView.layoutIfNeeded()
    }
    
//    func addDotGesture() {
//        let gesture = UIPanGestureRecognizer(target: self, action: #selector(wasDragged))
//        tapHandlerView.addGestureRecognizer(gesture)
//        tapHandlerView.isUserInteractionEnabled = true
//    }
//    
//    @objc func wasDragged(gestureRecognizer: UIPanGestureRecognizer) {
//        switch(gestureRecognizer.state) {
//        case .began:
//            shouldPreventOtherGestures = true
//            setPorgressOnDrag(gestureRecognizer)
//            break
//        case .changed:
//            setPorgressOnDrag(gestureRecognizer)
//            break
//        case .ended:
//            shouldPreventOtherGestures = false
//            break
//        default:
//            break
//        }
//    }

    @IBAction func playPauseButtonTouched() {
        delegate?.didTapPlayPauseButton(isThreadOriginalMsg: isThreadOriginalMsg)
    }
}
