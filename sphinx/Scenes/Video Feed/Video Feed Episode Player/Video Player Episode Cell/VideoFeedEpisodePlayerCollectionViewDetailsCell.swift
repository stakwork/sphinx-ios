// VideoFeedEpisodePlayerCollectionViewDetailsCell.swift
//
// Created by CypherPoet.
// ✌️
//


import UIKit


class VideoFeedEpisodePlayerCollectionViewDetailsCell: UICollectionViewCell {
    
    @IBOutlet private weak var episodeDescriptionLabel: UILabel!
    @IBOutlet private weak var showMoreButton: UIButton!
    @IBOutlet private weak var subscriptionToggleButton: UIButton!
    
    
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
    
    func configure(
        withVideoEpisode videoEpisode: Video
    ) {
        self.videoEpisode = videoEpisode
    }
}


// MARK: - Action Handling
extension VideoFeedEpisodePlayerCollectionViewDetailsCell {
    
    private var subscriptionToggleButtonTitle: String {
        (videoEpisode.videoFeed?.isSubscribedToFromSearch ?? false) ?
        "unsubscribe.upper".localized
        : "subscribe.upper".localized
    }
    
    @IBAction func subscriptionButtonTouched() {
        if let videoFeed = videoEpisode.videoFeed {
            
            videoFeed.isSubscribedToFromSearch.toggle()
            
            let contentFeed: ContentFeed? = CoreDataManager.sharedManager.getObjectWith(objectId: videoFeed.objectID)
            contentFeed?.isSubscribedToFromSearch.toggle()
            contentFeed?.managedObjectContext?.saveContext()
        }
        
        subscriptionToggleButton.setTitle(
            subscriptionToggleButtonTitle,
            for: .normal
        )
    }
    
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
        
        subscriptionToggleButton.layer.cornerRadius = subscriptionToggleButton.frame.size.height / 2
    }
    
    private func updateViewsWithVideoEpisode() {
        episodeDescriptionLabel.text = videoEpisode.videoDescription
        
        subscriptionToggleButton.setTitle(
            subscriptionToggleButtonTitle,
            for: .normal
        )
        
        subscriptionToggleButton.isHidden = videoEpisode.videoFeed?.chat != nil
    }
}


extension VideoFeedEpisodePlayerCollectionViewDetailsCell {
    enum ViewMode {
        case fullDetailsCollapsed
        case fullDetailsExpanded
    }
}
