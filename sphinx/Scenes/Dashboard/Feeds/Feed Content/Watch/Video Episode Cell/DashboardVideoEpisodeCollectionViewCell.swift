// DashboardVideoEpisodeCollectionViewCell.swift
//
// Created by CypherPoet.
// ✌️
//
    

import UIKit


class DashboardVideoEpisodeCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var feedAvatarImageView: UIImageView!
    @IBOutlet private weak var feedNameLabel: UILabel!
    @IBOutlet private weak var episodeTitleLabel: UILabel!
    @IBOutlet private weak var episodePublishDateLabel: UILabel!
    
    
    var videoEpisode: Video! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithVideoEpisode()
            }
        }
    }
}


// MARK: - Computeds
extension DashboardVideoEpisodeCollectionViewCell {
    
    var feedImageViewURL: URL? {
        videoEpisode.thumbnailURL
    }
}
    

// MARK: - Lifecycle
extension DashboardVideoEpisodeCollectionViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        thumbnailImageView.layer.cornerRadius = 8.0
        thumbnailImageView.clipsToBounds = true
        
        feedAvatarImageView.makeCircular()
    }
    
    
    func configure(withVideoEpisode videoEpisode: Video) {
        self.videoEpisode = videoEpisode
    }
    
    
    private func updateViewsWithVideoEpisode() {
        if let imageURL = feedImageViewURL {
            thumbnailImageView.sd_setImage(
                with: imageURL,
                placeholderImage: UIImage(named: "podcastPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            // 📝 TODO:  Use a video placeholder here
            thumbnailImageView.image = UIImage(named: "podcastPlaceholder")
        }
        
        if
            // 📝 TODO:  Clean up the logic for computing this
            let avatarImageURLPath = videoEpisode.videoFeed?.chat?.photoUrl,
            let avatarImageURL = URL(string: avatarImageURLPath)
        {
            feedAvatarImageView.sd_setImage(
                with: avatarImageURL,
                placeholderImage: UIImage(named: "profile_avatar"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            feedAvatarImageView.image = UIImage(named: "profile_avatar")
        }

        feedNameLabel.text = videoEpisode.videoFeed?.title ?? "Untitled"
        episodeTitleLabel.text = videoEpisode.title ?? "Untitled"
//        episodePublishDateLabel.text = Self.publishDateFormatter.string(from: videoEpisode.datePublished)
        episodePublishDateLabel.text = "Publish Date"
    }
}



// MARK: - Static Properties
extension DashboardVideoEpisodeCollectionViewCell {
    static let reuseID = "DashboardVideoEpisodeCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "DashboardVideoEpisodeCollectionViewCell", bundle: nil)
    }()
}
