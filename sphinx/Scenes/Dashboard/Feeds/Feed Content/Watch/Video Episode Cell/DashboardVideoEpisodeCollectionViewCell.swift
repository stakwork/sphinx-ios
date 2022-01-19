// DashboardVideoEpisodeCollectionViewCell.swift
//
// Created by CypherPoet.
// ✌️
//
    

import UIKit


class DashboardVideoEpisodeCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var feedAvatarImageView: UIImageView!
    @IBOutlet private weak var episodeTitleLabel: UILabel!
    @IBOutlet private weak var feedNameLabel: UILabel!
    @IBOutlet private weak var episodePublishDateLabel: UILabel!
    
    
    var videoEpisode: Video! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithVideoEpisode()
            }
        }
    }
}


// MARK: - Static Properties
extension DashboardVideoEpisodeCollectionViewCell {
    static let reuseID = "DashboardVideoEpisodeCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "DashboardVideoEpisodeCollectionViewCell", bundle: nil)
    }()
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
        
        setupViews()
    }
}


// MARK: -  Public Methods
extension DashboardVideoEpisodeCollectionViewCell {
    
    func configure(withVideoEpisode videoEpisode: Video) {
        self.videoEpisode = videoEpisode
    }
}


// MARK: - Private Helpers
extension DashboardVideoEpisodeCollectionViewCell {
    
    private func setupViews() {
        thumbnailImageView.layer.cornerRadius = 8.0
        thumbnailImageView.clipsToBounds = true
        
        feedAvatarImageView.makeCircular()
    }
    
    
    private func updateViewsWithVideoEpisode() {
        thumbnailImageView.sd_cancelCurrentImageLoad()
        feedAvatarImageView.sd_cancelCurrentImageLoad()
        
        if let imageURL = feedImageViewURL {
            thumbnailImageView.sd_setImage(
                with: imageURL,
                placeholderImage: UIImage(named: "videoPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            // 📝 TODO:  Use a video placeholder here?
            thumbnailImageView.image = UIImage(named: "videoPlaceholder")
        }
        
        if let avatarImageURL = videoEpisode.videoFeed?.avatarImageURL {
            feedAvatarImageView.sd_setImage(
                with: avatarImageURL,
                placeholderImage: UIImage(named: "profile_avatar"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            feedAvatarImageView.image = UIImage(named: "profile_avatar")
        }
        
        feedNameLabel.text = videoEpisode.videoFeed?.titleForDisplay
        episodeTitleLabel.text = videoEpisode.titleForDisplay
        episodePublishDateLabel.text = videoEpisode.publishDateText
    }
}
