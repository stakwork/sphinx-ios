//
//  PodcastAudioView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol PodcastAudioViewDelegate: class {
    func didTapClipPlayPauseButtonAt(time: Double)
    func shouldSeekTo(time: Double)
    func shouldToggleReplyGesture(enable: Bool)
}

class PodcastAudioView: UIView {
    
    weak var delegate: PodcastAudioViewDelegate?
    
    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var episodeTitleLabel: UILabel!
    @IBOutlet weak var playButtonView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    
    @IBOutlet weak var durationView: UIView!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var currentTimeView: UIView!
    @IBOutlet weak var tapHandlerView: UIView!
    
    @IBOutlet weak var progressViewWidthConstraint: NSLayoutConstraint!
    
    let kProgressBarLeftMargin: CGFloat = 108
    let kProgressBarRightMargin: CGFloat = 73
    
    var audioInfo: MessageTableCellState.AudioInfo? = nil
    var bubbleWidth: CGFloat? = nil
    var preventUIUpdates = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("PodcastAudioView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        playButtonView.layer.cornerRadius = playButtonView.bounds.height / 2
        durationView.layer.cornerRadius = durationView.bounds.height / 2
        progressView.layer.cornerRadius = progressView.bounds.height / 2
        currentTimeView.layer.cornerRadius = currentTimeView.bounds.height / 2
        
        loadingWheel.color = UIColor.Sphinx.Text
        
        addDotGesture()
    }
    
    func addDotGesture() {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(wasDragged))
        tapHandlerView.addGestureRecognizer(gesture)
        tapHandlerView.isUserInteractionEnabled = true
    }

    @objc func wasDragged(gestureRecognizer: UIPanGestureRecognizer) {
        guard let bubbleWidth = self.bubbleWidth else {
            return
        }

        let x = getGestureXPosition(gestureRecognizer)
        let progressBarWidth = bubbleWidth - kProgressBarLeftMargin - kProgressBarRightMargin
        let progress = ((x * 100) / progressBarWidth) / 100

        switch(gestureRecognizer.state) {
        case .began:
            delegate?.shouldToggleReplyGesture(enable: false)
            preventUIUpdates = true
        case .changed:
            configureTimeWith(progress: progress)
        case .ended:
            delegate?.shouldToggleReplyGesture(enable: true)
            configureTimeWith(progress: progress, shouldSync: true)
        default:
            break
        }
    }

    func getGestureXPosition(_ gestureRecognizer: UIPanGestureRecognizer) -> CGFloat {
        guard let bubbleWidth = self.bubbleWidth else {
            return 0.0
        }
        
        let progressBarWidth = bubbleWidth - kProgressBarLeftMargin - kProgressBarRightMargin
        let dotMinimumX: CGFloat = kProgressBarLeftMargin
        let x = gestureRecognizer.location(in: self).x - dotMinimumX
        return (x < 0) ? 0 : ((x > progressBarWidth) ? progressBarWidth : x)
    }
    
    func configureWith(
        podcastComment: BubbleMessageLayoutState.PodcastComment,
        mediaData: MessageTableCellState.MediaData?,
        bubble: BubbleMessageLayoutState.Bubble,
        and delegate: PodcastAudioViewDelegate?
    ) {
        self.delegate = delegate
        
        durationView.backgroundColor = bubble.direction.isIncoming() ? UIColor.Sphinx.WashedOutReceivedText : UIColor.Sphinx.WashedOutSentText
        episodeTitleLabel.text = podcastComment.title
        
        if let mediaData = mediaData, let audioInfo = mediaData.audioInfo {
            if !preventUIUpdates {
                configureTimeWith(
                    audioInfo: audioInfo,
                    and: podcastComment.bubbleWidth
                )
            }
        } else {
            startTimeLabel.text = Int(podcastComment.timestamp).getPodcastTimeString()
            configureLoadingWheel(loading: true)
            progressViewWidthConstraint.constant = 0
            progressView.layoutIfNeeded()
        }
    }
    
    func configureTimeWith(
        audioInfo: MessageTableCellState.AudioInfo,
        and bubbleWidth: CGFloat
    ) {
        self.audioInfo = audioInfo
        self.bubbleWidth = bubbleWidth
        
        playButton.setTitle(audioInfo.playing ? "pause" : "play_arrow", for: .normal)
        
        startTimeLabel.text = Int(audioInfo.currentTime).getPodcastTimeString()
        endTimeLabel.text = Int(audioInfo.duration).getPodcastTimeString()
        
        configureLoadingWheel(
            loading: audioInfo.loading && !audioInfo.playing
        )
        
        let progressBarWidth = bubbleWidth - kProgressBarLeftMargin - kProgressBarRightMargin
        let progress = audioInfo.currentTime * 1 / audioInfo.duration
        progressViewWidthConstraint.constant = progressBarWidth * progress
        progressView.layoutIfNeeded()
    }
    
    func configureTimeWith(
        progress: Double,
        shouldSync: Bool = false
    ) {
        guard let audioInfo = self.audioInfo, let bubbleWidth = self.bubbleWidth else {
            return
        }
        
        let currentTime = audioInfo.duration * progress
        startTimeLabel.text = Int(currentTime).getPodcastTimeString()
        
        let progressBarWidth = bubbleWidth - kProgressBarLeftMargin - kProgressBarRightMargin
        progressViewWidthConstraint.constant = progressBarWidth * progress
        
        if shouldSync {
            delegate?.shouldSeekTo(time: currentTime)
            
            DelayPerformedHelper.performAfterDelay(seconds: 1.0, completion: {
                self.preventUIUpdates = false
            })
        }
    }
    
    func configureLoadingWheel(
        loading: Bool
    ) {
        playButton.isHidden = loading
        playButtonView.isHidden = loading
        loadingWheel.isHidden = !loading
        
        if loading {
            loadingWheel.startAnimating()
        } else {
            loadingWheel.stopAnimating()
        }
    }
    
    @IBAction func playPauseButtonTouched() {
        guard let audioInfo = self.audioInfo, let bubbleWidth = self.bubbleWidth else {
            return
        }
        
        preventUIUpdates = true
        
        let progressBarWidth = bubbleWidth - kProgressBarLeftMargin - kProgressBarRightMargin
        let progress = progressViewWidthConstraint.constant / progressBarWidth
        let currentTime = audioInfo.duration * progress
        
        delegate?.didTapClipPlayPauseButtonAt(time: currentTime)
        
        DelayPerformedHelper.performAfterDelay(seconds: 1.0, completion: {
            self.preventUIUpdates = false
        })
    }
    
}
