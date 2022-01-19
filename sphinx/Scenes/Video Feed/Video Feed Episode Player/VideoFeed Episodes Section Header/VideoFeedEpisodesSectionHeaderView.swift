// VideoFeedEpisodesSectionHeaderView.swift
//
// Created by CypherPoet.
// ✌️
//


import UIKit


class VideoFeedEpisodesSectionHeaderView: UICollectionReusableView {
    @IBOutlet private weak var feedAvatarImage: UIImageView!
    @IBOutlet private weak var feedAuthorNameLabel: UILabel!
    
    // 📝 TODO:  Re-install this in the xib when we're ready to support it
    @IBOutlet private weak var subscriptionButton: UIButton!
    
    @IBOutlet private weak var episodeCountNumberLabel: UILabel!
    @IBOutlet private weak var episodeCountTextLabel: UILabel!
    
    
    var videoFeedEpisode: Video! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithVideoEpisode()
            }
        }
    }
    
    var onFeedSubscribed: (() -> Void)!
    var onFeedUnsubscribed: (() -> Void)!
}


// MARK: - Static Properties
extension VideoFeedEpisodesSectionHeaderView {
    static let reuseID = "VideoFeedEpisodesSectionHeaderView"

    static let nib: UINib = {
        UINib(nibName: "VideoFeedEpisodesSectionHeaderView", bundle: nil)
    }()
}


// MARK: - Lifecycle
extension VideoFeedEpisodesSectionHeaderView {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupViews()
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}


// MARK: - Computeds
extension VideoFeedEpisodesSectionHeaderView {

    private var videoFeed: VideoFeed? { videoFeedEpisode.videoFeed }
    
    private var episodeCount: Int {
        videoFeed?.videosArray.count ?? 0
    }
}


// MARK: - Public Methods
extension VideoFeedEpisodesSectionHeaderView {

    func configure(
        withEpisode videoFeedEpisode: Video,
        onFeedSubscribed: (() -> Void)!,
        onFeedUnsubscribed: (() -> Void)!
    ) {
        self.videoFeedEpisode = videoFeedEpisode
        self.onFeedSubscribed = onFeedSubscribed
        self.onFeedUnsubscribed = onFeedUnsubscribed
    }
}


// MARK: - Action Handling
extension VideoFeedEpisodesSectionHeaderView {
    
    @IBAction private func didTapSubscriptionButton() {
        onFeedSubscribed()
    }
}


// MARK: - Private Helpers
extension VideoFeedEpisodesSectionHeaderView {

    private func setupViews() {
        subscriptionButton.clipsToBounds = true
        subscriptionButton.roundCorners(
            corners: .allCorners,
            radius: subscriptionButton.frame.width / 2.0
        )
        subscriptionButton.setTitle(
            "video-player.button.subscribe".localized,
            for: .normal
        )
        
        feedAvatarImage.makeCircular()
    }
    
    
    private func updateViewsWithVideoEpisode() {
        feedAvatarImage.sd_cancelCurrentImageLoad()
        
        if let imageURL = videoFeed?.avatarImageURL {
            feedAvatarImage.sd_setImage(
                with: imageURL,
                placeholderImage: videoFeed?.avatarImagePlaceholder,
                options: [.highPriority],
                progress: nil
            )
        } else {
            feedAvatarImage.image = videoFeed?.avatarImagePlaceholder
        }
        
        feedAuthorNameLabel.text = videoFeed?.authorNameForDisplay
        episodeCountNumberLabel.text = "\(episodeCount)"

        episodeCountTextLabel.text = (
            episodeCount == 1 ?
                "video"
                : "videos"
        )
        .localized
        .capitalized
    }
}
