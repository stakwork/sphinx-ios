//
//  PodcastPlayerControlsView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/12/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

protocol RecommendationPlayerViewDelegate: AnyObject {
    func shouldShowSpeedPicker()
}

class PodcastPlayerControlsView: UIView {
    
    weak var delegate: RecommendationPlayerViewDelegate?

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
    
    var playerHelper: PodcastPlayerHelper = PodcastPlayerHelper.sharedInstance
    var podcast: PodcastFeed!
}

// MARK: - Actions handlers
extension PodcastPlayerControlsView {
    @IBAction func controlButtonTouched(_ sender: UIButton) {
        switch(sender.tag) {
        case ControlButtons.PlayerSpeed.rawValue:
            delegate?.shouldShowSpeedPicker()
            break
        case ControlButtons.Replay15.rawValue:
            seekTo(seconds: -15)
            break
        case ControlButtons.Forward30.rawValue:
            seekTo(seconds: 30)
            break
        case ControlButtons.PlayPause.rawValue:
            togglePlayState()
            break
        default:
            break
        }
    }
    
    func togglePlayState() {
        playerHelper.togglePlayStateFor(podcast)
    }
    
    func seekTo(seconds: Double) {
        playerHelper.seek(podcast, to: seconds)
    }
}

// MARK: - Public methods
extension PodcastPlayerControlsView {
    func configure(
        podcast: PodcastFeed,
        andDelegate delegate: RecommendationPlayerViewDelegate?
    ) {
        self.delegate = delegate
        self.podcast = podcast
        
        if let item = podcast.getCurrentEpisode() {
            speedButton.isHidden = item.isYoutubeVideo
            clipButton.isHidden = item.isYoutubeVideo
            playPauseButton.isHidden = item.isYoutubeVideo
            skip15BackwardView.isHidden = item.isYoutubeVideo
            skip30ForwardView.isHidden = item.isYoutubeVideo
        }
        
        clipButton.alpha = 0.5
        clipButton.isEnabled = false
        
        boostView.alpha = 0.5
    }
    
    func configureControls(
        playing: Bool,
        speedDescription: String
    ) {
        playPauseButton.setTitle(playing ? "pause" : "play_arrow", for: .normal)
        speedButton.setTitle(speedDescription + "x", for: .normal)
    }
}
