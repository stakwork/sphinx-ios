//
//  PodcastSmallPlayer.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/10/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import UIKit

class PodcastSmallPlayer: UIView {
    
    weak var delegate: PodcastPlayerVCDelegate?

    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var episodeLabel: UILabel!
    @IBOutlet weak var durationLine: UIView!
    @IBOutlet weak var progressLine: UIView!
    @IBOutlet weak var progressLineWidth: NSLayoutConstraint!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var audioLoadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var boostButtonView: BoostButtonView!
    
    var playerHelper: PodcastPlayerHelper! = nil
    
    var wasPlayingOnDrag = false
    
    var audioLoading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: audioLoading, loadingWheel: audioLoadingWheel, loadingWheelColor: UIColor.Sphinx.Text)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func configure(playerHelper: PodcastPlayerHelper, delegate: PodcastPlayerVCDelegate, completion: @escaping () -> ()) {
        self.playerHelper = playerHelper
        self.delegate = delegate
        
        setPlayerDelegate(completion: completion)
    }
    
    func setPlayerDelegate(completion: @escaping () -> ()) {
        playerHelper.delegate = self
        playerHelper.preparePlayer(completion: {
            self.playerHelper.shouldUpdateTimeLabels()
            completion()
        })
    }
    
    func reload() {
        setPlayerDelegate(completion: {})
        showEpisodeInfo()
        configureControls()
    }

    private func setup() {
        Bundle.main.loadNibNamed("PodcastSmallPlayer", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        boostButtonView.delegate = self
        isHidden = true
    }
    
    func getViewHeight() -> CGFloat {
        return isHidden ? 0 : self.frame.height
    }

    func showPlayerInfo() {
        playerHelper?.updateCurrentTime()
        configureControls()
        showEpisodeInfo()
        
        isHidden = false
    }
    
    func showEpisodeInfo() {
        let (title, _) = playerHelper.getEpisodeInfo()
        episodeLabel.text = title
    }
    
    func configureControls() {
        let isPlaying = playerHelper.isPlaying()
        playPauseButton.setTitle(isPlaying ? "pause" : "play_arrow", for: .normal)
    }
    
    func setLabels(duration: Int, currentTime: Int) {
        let durationLineWidth = UIScreen.main.bounds.width
        let progress = (Double(currentTime) * 100 / Double(duration))/100
        var progressWidth = durationLineWidth * CGFloat(progress)
        
        if !progressWidth.isFinite || progressWidth < 0 {
            progressWidth = 0
        }
        
        progressLineWidth.constant = progressWidth
        progressLine.layoutIfNeeded()
    }
    
    func togglePlayState() {
        playerHelper.togglePlayState()
        configureControls()
    }
    
    @IBAction func playPauseButtonTouched() {
        togglePlayState()
    }
    
    @IBAction func forwardButtonTouched() {
        playerHelper.seekTo(seconds: 30)
    }
    
    @IBAction func playerButtonTouched() {
        delegate?.shouldGoToPlayer()
    }
}

extension PodcastSmallPlayer : PodcastPlayerDelegate {
    func shouldUpdateLabels(duration: Int, currentTime: Int) {
        setLabels(duration: duration, currentTime: currentTime)
    }
    
    func shouldToggleLoadingWheel(loading: Bool) {
        audioLoading = loading
    }
    
    func shouldUpdatePlayButton() {
        configureControls()
    }
    
    func shouldUpdateEpisodeInfo() {
        showEpisodeInfo()
    }
}

extension PodcastSmallPlayer : BoostButtonViewDelegate {
    func didTouchButton() {
        let amount = UserContact.kTipAmount
        
        if let boostMessage = playerHelper.getBoostMessage(amount: amount) {
            playerHelper.processPayment(amount: amount)
            let _ = delegate?.shouldSendBoost(message: boostMessage, amount: amount, animation: true)
        }
    }
}
