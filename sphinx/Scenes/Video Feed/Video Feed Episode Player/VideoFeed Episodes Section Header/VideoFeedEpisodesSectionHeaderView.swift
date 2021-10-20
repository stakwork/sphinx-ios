// VideoFeedEpisodesSectionHeaderView.swift
//
// Created by CypherPoet.
// ✌️
//


import UIKit


protocol VideoFeedEpisodesSectionHeaderViewDelegate: AnyObject {

    func headerViewDidTapSubscribeButton(
        _ headerView: VideoFeedEpisodesSectionHeaderView
    )
}


class VideoFeedEpisodesSectionHeaderView: UICollectionReusableView {
    @IBOutlet private weak var feedAvatarImage: UIImageView!
    @IBOutlet private weak var feedAuthorNameLabel: UILabel!
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
    

    private var avatarImageViewURL: URL? {
        guard let photoURL = videoFeed?.chat?.photoUrl else {
            return nil
        }
        
        return URL(string: photoURL)
    }
}


// MARK: - Public Methods
extension VideoFeedEpisodesSectionHeaderView {

    func configure(withEpisode videoFeedEpisode: Video) {
        self.videoFeedEpisode = videoFeedEpisode
    }
}



// MARK: - Private Helpers
extension VideoFeedEpisodesSectionHeaderView {

    private func setupViews() {
        subscriptionButton.setTitle(
            "video-player.button.subscribe".localized,
            for: .normal
        )
        
        feedAvatarImage.makeCircular()
    }
    
    
    private func updateViewsWithVideoEpisode() {
        if let imageURL = avatarImageViewURL {
            feedAvatarImage.sd_setImage(
                with: imageURL,
                placeholderImage: UIImage(named: "userAvatar"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            feedAvatarImage.image = UIImage(named: "userAvatar")
        }
        
        feedAuthorNameLabel.text = videoFeed?.title ?? "Feed Name"
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
