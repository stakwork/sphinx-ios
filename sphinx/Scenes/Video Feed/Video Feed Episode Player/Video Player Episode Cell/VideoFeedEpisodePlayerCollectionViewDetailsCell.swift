// VideoFeedEpisodePlayerCollectionViewDetailsCell.swift
//
// Created by CypherPoet.
// ✌️
//


import UIKit


class VideoFeedEpisodePlayerCollectionViewDetailsCell: UICollectionViewCell {
    
    @IBOutlet private weak var episodeTitleLabel: UILabel!
    @IBOutlet private weak var episodeViewCountLabel: UILabel!
    @IBOutlet private weak var episodePublishDateLabel: UILabel!
    @IBOutlet private weak var episodeDescriptionLabel: UILabel!

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
        
//        thumbnailImageView.layer.cornerRadius = 8.0
//        thumbnailImageView.clipsToBounds = true
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
    
    private func updateViewsWithVideoEpisode() {
//        if let imageURL = feedImageViewURL {
//            thumbnailImageView.sd_setImage(
//                with: imageURL,
//                placeholderImage: UIImage(named: "podcastPlaceholder"),
//                options: [.highPriority],
//                progress: nil
//            )
//        } else {
//            // 📝 TODO:  Use a video placeholder here
//            thumbnailImageView.image = UIImage(named: "podcastPlaceholder")
//        }
//
//
//        feedNameLabel.text = videoEpisode.videoFeed?.title ?? "Untitled"
//        episodeTitleLabel.text = videoEpisode.title ?? "Untitled"
//        //        episodePublishDateLabel.text = Self.publishDateFormatter.string(from: videoEpisode.datePublished)
//        episodePublishDateLabel.text = "Publish Date"
    }
}


