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
    @IBOutlet weak var clipLine: UIView!
    @IBOutlet weak var clipLineWidth: NSLayoutConstraint!
    @IBOutlet weak var clipLineStart: NSLayoutConstraint!
    @IBOutlet weak var audioLoadingWheel: UIActivityIndicatorView!
    
    var audioLoading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: audioLoading, loadingWheel: audioLoadingWheel, loadingWheelColor: UIColor.Sphinx.Text)
        }
    }
    
    var playerHelper: PodcastPlayerHelper = PodcastPlayerHelper.sharedInstance
    var podcast: PodcastFeed!
    
    var wasPlayingOnDrag = false

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
        
        addDotGesture()
    }
    
    func setProgress(
        duration: Int,
        currentTime: Int,
        clipStartTime: Int? = 0,
        clipEndTime: Int? = 0
    ) -> Bool {
        let currentTimeString = currentTime.getPodcastTimeString()
        let didChangeCurrentTime = currentTimeLabel.text != currentTimeString
        
        currentTimeLabel.text = currentTimeString
        durationLabel.text = duration.getPodcastTimeString()
        
        let progress = (Double(currentTime) * 100 / Double(duration))/100
        let durationLineWidth = UIScreen.main.bounds.width - 64
        let progressWidth = (durationLineWidth * CGFloat(progress)).finiteNonZero
        
        progressLineWidth.constant = progressWidth
        progressLine.layoutIfNeeded()
        
        configureClip(
            duration: duration,
            clipStartTime: clipStartTime,
            clipEndTime: clipEndTime
        )
        
        return didChangeCurrentTime
    }
    
    private func configureClip(
        duration: Int,
        clipStartTime: Int? = 0,
        clipEndTime: Int? = 0
    ) {
        guard let clipStartTime = clipStartTime, let clipEndTime = clipEndTime else {
            clipLineWidth.constant = 0
            clipLineStart.constant = 0
            clipLine.superview?.layoutIfNeeded()
            return
        }
        
        let durationLineWidth = UIScreen.main.bounds.width - 64
        
        let startProgress = (Double(clipStartTime) * 100 / Double(duration))/100
        let startProgressWidth = (durationLineWidth * CGFloat(startProgress)).finiteNonZero
        
        let clipDuration = clipEndTime - clipStartTime
        let durationProgress = (Double(clipDuration) * 100 / Double(duration))/100
        let clipDurationWidth = (durationLineWidth * CGFloat(durationProgress)).finiteNonZero
        
        if (
            clipLineStart.constant == startProgressWidth &&
            clipLineWidth.constant == clipDurationWidth
        ) {
            return
        }
        
        clipLineStart.constant = startProgressWidth
        clipLineWidth.constant = clipDurationWidth
        
        clipLine.superview?.layoutIfNeeded()
        
    }
    
    func configureWith(podcast: PodcastFeed) {
        self.podcast = podcast
    }
    
    func addDotGesture() {
        let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(wasDragged))
        gestureHandlerView.addGestureRecognizer(dragGesture)
    }
    
    @objc func wasDragged(gestureRecognizer: UIPanGestureRecognizer) {
        let gestureXLocation = gestureRecognizer.location(in: durationLine).x
        
        if gestureRecognizer.state == .began {
            gestureDidBegin(gestureXLocation: gestureXLocation)
        } else if gestureRecognizer.state == .changed {
            updateProgressLineAndLabel(gestureXLocation: gestureXLocation)
        } else if gestureRecognizer.state == .ended {
            let progress = ((progressLineWidth.constant * 100) / durationLine.frame.size.width) / 100
            
            playerHelper.seek(podcast, to: Double(progress), playAfterSeek: wasPlayingOnDrag)
            wasPlayingOnDrag = false
        }
    }
    
    func gestureDidBegin(gestureXLocation: CGFloat) {
        wasPlayingOnDrag = playerHelper.isPlaying(podcast.feedID)
        playerHelper.didStartDraggingProgressFor(podcast)
        updateProgressLineAndLabel(gestureXLocation: gestureXLocation)
    }
    
    func updateProgressLineAndLabel(gestureXLocation: CGFloat) {
        let totalProgressWidth = CGFloat(durationLine.frame.size.width)
        let translation = (gestureXLocation < 0) ? 0 : ((gestureXLocation > totalProgressWidth) ? totalProgressWidth : gestureXLocation)
        
        if !translation.isFinite || translation < 0 {
            return
        }
        
        progressLineWidth.constant = translation
        progressLine.layoutIfNeeded()
        
        let progress = ((progressLineWidth.constant * 100) / durationLine.frame.size.width) / 100
        
        playerHelper.shouldUpdateTimeLabelsTo(
            progress: Double(progress),
            with: podcast.getCurrentEpisode()?.duration ?? 0,
            in: podcast
        )
    }

}
