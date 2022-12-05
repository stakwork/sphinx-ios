// VideoFeedEpisodeCollectionViewCell.swift
//
// Created by CypherPoet.
// ✌️
//


import UIKit
import SDWebImage


class VideoFeedEpisodeCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var thumbnailImageView: UIImageView!
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
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
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
        thumbnailImageView.sd_cancelCurrentImageLoad()
        
        if let imageURL = thumbnailImageViewURL {
            thumbnailImageView.sd_setImage(
                with: imageURL,
                placeholderImage: UIImage(named: "videoPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            // 📝 TODO:  Use a video placeholder here
            thumbnailImageView.image = UIImage(named: "videoPlaceholder")
        }


        episodeTitleLabel.text = videoEpisode.titleForDisplay
        episodePublishDateLabel.text = videoEpisode.publishDateText
    }
}

