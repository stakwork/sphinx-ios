// VideoFeedEpisodePlayerCollectionViewDetailsCell.swift
//
// Created by CypherPoet.
// ✌️
//


import UIKit


class VideoFeedEpisodePlayerCollectionViewDetailsCell: UICollectionViewCell {
    @IBOutlet private weak var episodeDescriptionLabel: UILabel!
    @IBOutlet private weak var showMoreButton: UIButton!

    
    var videoEpisode: Video! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithVideoEpisode()
            }
        }
    }
    
    private var viewMode: ViewMode = .fullDetailsCollapsed {
        didSet {
            // 📝 TODO:  Implement dynamic resizing around the state change here
            // (see: https://stackoverflow.com/a/60835843/8859365)
//            setNeedsLayout()
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
    
    var showMoreButtonTitle: String {
        switch viewMode {
        case .fullDetailsCollapsed:
            return "video-player.episode-details.button.show-more"
                .localized
                .uppercased()
        case .fullDetailsExpanded:
            return "video-player.episode-details.button.show-less"
                .localized
                .uppercased()
        }
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


// MARK: - Action Handling
extension VideoFeedEpisodePlayerCollectionViewDetailsCell {
    
    @IBAction private func didTapShowMoreButton() {
        switch viewMode {
        case .fullDetailsCollapsed:
            viewMode = .fullDetailsExpanded
        case .fullDetailsExpanded:
            viewMode = .fullDetailsCollapsed
        }
        
        showMoreButton.setTitle(
            showMoreButtonTitle,
            for: .normal
        )
    }
}


// MARK: - Private Helpers
extension VideoFeedEpisodePlayerCollectionViewDetailsCell {
    
    private func setupViews() {
        showMoreButton.setTitle(
            showMoreButtonTitle,
            for: .normal
        )
    }
    
    private func updateViewsWithVideoEpisode() {
        episodeDescriptionLabel.text = videoEpisode.videoDescription
    }
}


extension VideoFeedEpisodePlayerCollectionViewDetailsCell {
    enum ViewMode {
        case fullDetailsCollapsed
        case fullDetailsExpanded
    }
}
