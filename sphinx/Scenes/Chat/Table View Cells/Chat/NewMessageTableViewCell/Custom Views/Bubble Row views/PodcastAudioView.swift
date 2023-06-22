//
//  PodcastAudioView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class PodcastAudioView: UIView {
    
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
        
        loadingWheel.tintColor = UIColor.Sphinx.Text
    }
    
    func configureWith(
        podcastComment: BubbleMessageLayoutState.PodcastComment,
        mediaData: MessageTableCellState.MediaData?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        
        durationView.backgroundColor = bubble.direction.isIncoming() ? UIColor.Sphinx.WashedOutReceivedText : UIColor.Sphinx.WashedOutSentText
        
        episodeTitleLabel.text = podcastComment.title
        
        if let mediaData = mediaData, let audioInfo = mediaData.audioInfo {
            
            playButton.setTitle(audioInfo.playing ? "pause" : "play_arrow", for: .normal)
            
            startTimeLabel.text = Int(audioInfo.currentTime).getPodcastTimeString()
            endTimeLabel.text = Int(audioInfo.duration).getPodcastTimeString()
            
            playButton.isHidden = false
            playButtonView.isHidden = false
            loadingWheel.isHidden = true
            loadingWheel.stopAnimating()
            
            let progressBarWith = podcastComment.bubbleWidth - kProgressBarLeftMargin - kProgressBarRightMargin
            let progress = audioInfo.currentTime * 1 / audioInfo.duration
            progressViewWidthConstraint.constant = progressBarWith * progress
            
        } else {
            startTimeLabel.text = Int(podcastComment.timestamp).getPodcastTimeString()
            
            playButton.isHidden = true
            playButtonView.isHidden = true
            loadingWheel.isHidden = false
            loadingWheel.startAnimating()
            
            progressViewWidthConstraint.constant = 0
        }
        
        progressView.layoutIfNeeded()
    }

}
