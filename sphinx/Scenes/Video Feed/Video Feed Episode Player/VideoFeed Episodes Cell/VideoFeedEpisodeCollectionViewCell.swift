// VideoFeedEpisodeCollectionViewCell.swift
//
// Created by CypherPoet.
// ✌️
//


import UIKit



class VideoFeedEpisodeCollectionViewCell: UICollectionViewCell {
    
    var videoEpisode: Video! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithVideoEpisode()
            }
        }
    }
}



// MARK: - Static Properties
extension VideoFeedEpisodeCollectionViewCell {
    
    static let reuseID = "VideoFeedEpisodeCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "VideoFeedEpisodeCollectionViewCell", bundle: nil)
    }()
}


// MARK: - Computeds
extension VideoFeedEpisodeCollectionViewCell {
    
    var thumbnailImageViewURL: URL? {
        videoEpisode.thumbnailURL
    }
}


// MARK: - Lifecycle
extension VideoFeedEpisodeCollectionViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        thumbnailImageView.layer.cornerRadius = 8.0
//        thumbnailImageView.clipsToBounds = true
    }
}
 

// MARK: - Public Methods
extension VideoFeedEpisodeCollectionViewCell {
    
    func configure(withVideoEpisode videoEpisode: Video) {
        self.videoEpisode = videoEpisode
    }
}


// MARK: - Private Helpers
extension VideoFeedEpisodeCollectionViewCell {
    
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

