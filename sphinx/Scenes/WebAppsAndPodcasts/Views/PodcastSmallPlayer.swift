//
//  PodcastSmallPlayer.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import Lottie

class PodcastSmallPlayer: UIView {
    
    weak var delegate: PodcastPlayerVCDelegate?
    weak var boostDelegate: CustomBoostDelegate?

    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var episodeImageView: UIImageView!
    @IBOutlet weak var episodeLabel: UILabel!
    @IBOutlet weak var contributorLabel: UILabel!
    @IBOutlet weak var durationLine: UIView!
    @IBOutlet weak var progressLine: UIView!
    @IBOutlet weak var progressLineWidth: NSLayoutConstraint!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var audioLoadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseAnimationView: AnimationView!
    
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
    
    func configure(
        playerHelper: PodcastPlayerHelper,
        delegate: PodcastPlayerVCDelegate,
        completion: @escaping () -> ()
    ) {
        
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
        
        runAnimation()
        
        isHidden = true
    }
    
    func runAnimation() {
        let pauseAnimation = Animation.named("pause_animation")
        pauseAnimationView.animation = pauseAnimation
        pauseAnimationView.loopMode = .autoReverse
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
        let (title, imageUrlString) = playerHelper.getEpisodeInfo()
        episodeLabel.text = title
        contributorLabel.text = playerHelper.podcast?.author ?? playerHelper.podcast?.title ?? ""
        
        if let imageURL = URL(string: imageUrlString), !imageUrlString.isEmpty {
            episodeImageView.sd_setImage(
                with: imageURL,
                placeholderImage: UIImage(named: "podcastPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            episodeImageView.image = UIImage(named: "podcastPlaceholder")
        }
    }
    
    func configureControls() {
        let isPlaying = playerHelper.isPlaying()
        playButton.isHidden = isPlaying
        
        pauseAnimationView.isHidden = !isPlaying
        
        if isPlaying {
            pauseAnimationView.play()
        } else {
            pauseAnimationView.stop()
        }
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(PodcastSmallPlayer.playPauseButtonTouched))
        pauseAnimationView.addGestureRecognizer(gesture)
    }
    
    func setLabels(duration: Int, currentTime: Int) {
        let progressBarMargin:CGFloat = 32
        let durationLineWidth = UIScreen.main.bounds.width - progressBarMargin
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
