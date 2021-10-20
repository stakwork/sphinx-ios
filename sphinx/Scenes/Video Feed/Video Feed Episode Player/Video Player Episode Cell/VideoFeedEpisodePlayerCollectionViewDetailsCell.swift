// VideoFeedEpisodePlayerCollectionViewDetailsCell.swift
//
// Created by CypherPoet.
// ✌️
//


import UIKit


class VideoFeedEpisodePlayerCollectionViewDetailsCell: UICollectionViewCell {
    
    @IBOutlet private weak var episodeTitleLabel: UILabel!
    @IBOutlet private weak var episodeViewCountLabel: UILabel!
    @IBOutlet weak var episodeSubtitleCircularDivider: UIView!
    @IBOutlet private weak var episodePublishDateLabel: UILabel!
    @IBOutlet private weak var episodeDescriptionLabel: UILabel!
    @IBOutlet private weak var showMoreButton: UIButton!

    
    var videoEpisode: Video! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithVideoEpisode()
            }
        }
    }
}


// MARK: - Static Properties
extension VideoFeedEpisodePlayerCollectionViewDetailsCell {
    
    static let reuseID = "VideoFeedEpisodePlayerCollectionViewDetailsCell"
    
    static let nib: UINib = .init(
        nibName: "VideoFeedEpisodePlayerCollectionViewDetailsCell",
        bundle: nil
    )
}


// MARK: - Computeds
extension VideoFeedEpisodePlayerCollectionViewDetailsCell {
    
    var thumbnailImageViewURL: URL? {
        videoEpisode.thumbnailURL
    }
}


// MARK: - Lifecycle
extension VideoFeedEpisodePlayerCollectionViewDetailsCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupViews()
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
 

// MARK: - Public Methods
extension VideoFeedEpisodePlayerCollectionViewDetailsCell {
    
    func configure(withVideoEpisode videoEpisode: Video) {
        self.videoEpisode = videoEpisode
    }
}


// MARK: - Private Helpers
extension VideoFeedEpisodePlayerCollectionViewDetailsCell {
    
    private func setupViews() {
        showMoreButton.setTitle(
            "video-player.episode-details.button.show-more"
                .localized
                .uppercased(),
            for: .normal
        )
        episodeSubtitleCircularDivider.makeCircular()
    }
    
    
    private func updateViewsWithVideoEpisode() {
        episodeTitleLabel.text = videoEpisode.title ?? "Untitled"
        episodeViewCountLabel.text = "View Count"
        //        episodePublishDateLabel.text = Self.publishDateFormatter.string(from: videoEpisode.datePublished)
        episodePublishDateLabel.text = "Publish Date"
        episodeDescriptionLabel.text = "Episode Description"
    }
}
