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
    
    func setProgress(duration: Int, currentTime: Int) -> Bool {
        let currentTimeString = currentTime.getPodcastTimeString()
        let didChangeCurrentTime = currentTimeLabel.text != currentTimeString
        
        currentTimeLabel.text = currentTimeString
        durationLabel.text = duration.getPodcastTimeString()
        
        let progress = (Double(currentTime) * 100 / Double(duration))/100
        let durationLineWidth = UIScreen.main.bounds.width - 64
        var progressWidth = durationLineWidth * CGFloat(progress)
        
        if !progressWidth.isFinite || progressWidth < 0 {
            progressWidth = 0
        }
        
        progressLineWidth.constant = progressWidth
        progressLine.layoutIfNeeded()
        
        return didChangeCurrentTime
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
