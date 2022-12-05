//
//  PodcastPlayerControlsView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/12/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

class PodcastPlayerControlsView: UIView {

    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var speedButton: UIButton!
    @IBOutlet weak var clipButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var skip15BackwardView: UIView!
    @IBOutlet weak var skip30ForwardView: UIView!
    @IBOutlet weak var boostView: CustomBoostView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("PodcastPlayerControlsView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        playPauseButton.layer.cornerRadius = playPauseButton.frame.size.height / 2
    }
    
    public enum ControlButtons: Int {
        case PlayerSpeed
        case ShareClip
        case Replay15
        case PlayPause
        case Forward30
    }
}

// MARK: - Actions handlers
extension PodcastPlayerControlsView {
    @IBAction func controlButtonTouched(_ sender: UIButton) {
        switch(sender.tag) {
        case ControlButtons.PlayerSpeed.rawValue:
//            delegate?.shouldShowSpeedPicker()
            break
        case ControlButtons.ShareClip.rawValue:
//            let comment = podcast.getPodcastComment()
//            delegate?.shouldShareClip(comment: comment)
            break
        case ControlButtons.Replay15.rawValue:
//            seekTo(seconds: -15)
            break
        case ControlButtons.Forward30.rawValue:
//            seekTo(seconds: 30)
            break
        case ControlButtons.PlayPause.rawValue:
//            togglePlayState()
            break
        default:
            break
        }
    }
}

// MARK: - Public methods
extension PodcastPlayerControlsView {
    func configure(withRecommendation recommendation: RecommendationResult) {
        
        speedButton.isHidden = recommendation.isYoutubeVideo
        clipButton.isHidden = recommendation.isYoutubeVideo
        playPauseButton.isHidden = recommendation.isYoutubeVideo
        skip15BackwardView.isHidden = recommendation.isYoutubeVideo
        skip30ForwardView.isHidden = recommendation.isYoutubeVideo
        
        clipButton.alpha = 0.5
        clipButton.isEnabled = false
        
        boostView.alpha = 0.5
    }
}
