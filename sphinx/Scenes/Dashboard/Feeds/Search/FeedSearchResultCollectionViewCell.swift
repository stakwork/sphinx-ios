// FeedSearchResultCollectionViewCell.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit
import SDWebImage


class FeedSearchResultCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var feedThumbnailImageView: UIImageView!
    @IBOutlet weak var feedTitleLabel: UILabel!
    @IBOutlet weak var feedSubtitleLabel: UILabel!
    @IBOutlet weak var feedSubscriptionButton: UIButton!
    @IBOutlet weak var bottomSeparatorView: UIView!
    
    
    var item: FeedSearchResult! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithItem()
            }
        }
    }

    var onSubscriptionButtonTapped: ((PodcastFeed, SubscriptionState) -> Void)?
    
    private var subscriptionState: SubscriptionState = .followedViaTribe
}



// MARK: - Static Properties
extension FeedSearchResultCollectionViewCell {
    static let reuseID = "FeedSearchResultCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "FeedSearchResultCollectionViewCell", bundle: nil)
    }()
}


// MARK: - Computeds
extension FeedSearchResultCollectionViewCell {
    
    var imageURL: URL? {
        item.imageUrl.flatMap { URL(string: $0) }
    }
}
    

// MARK: - Lifecycle
extension FeedSearchResultCollectionViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        feedThumbnailImageView.layer.cornerRadius = 6.0
        feedThumbnailImageView.clipsToBounds = true
    }
}


// MARK: - Public Methods
extension FeedSearchResultCollectionViewCell {
    
    public func configure(
        withItem searchResult: FeedSearchResult,
        shouldShowSeparator: Bool = false
    ) {
        bottomSeparatorView.isHidden = shouldShowSeparator == false
        
        item = searchResult
    }
}


// MARK: - Event Handling
extension FeedSearchResultCollectionViewCell {
    
    @IBAction func subscriptionButtonTapped(_ sender: UIButton) {
//        onSubscriptionButtonTapped?(item, subscriptionState)
    }
}


// MARK: - Private Helpers
extension FeedSearchResultCollectionViewCell {
    
    private func updateViewsWithItem() {
        feedThumbnailImageView.sd_cancelCurrentImageLoad()
        
        if let imageURL = imageURL {
            feedThumbnailImageView.sd_setImage(
                with: imageURL,
                placeholderImage: UIImage(named: "podcastPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            feedThumbnailImageView.image = UIImage(named: "podcastPlaceholder")
        }
        
        feedTitleLabel.text = item.title
        feedSubtitleLabel.text = item.feedDescription
        
        switch subscriptionState {
        case .subscribedFromPodcastIndex:
            feedSubscriptionButton.setImage(UIImage(systemName: "minus.circle"), for: .normal)
            feedSubscriptionButton.isHidden = false
            feedSubscriptionButton.isEnabled = true
        case .subscriptionAvailableFromPodcastIndex:
            feedSubscriptionButton.setImage(UIImage(systemName: "plus"), for: .normal)
            feedSubscriptionButton.isHidden = false
            feedSubscriptionButton.isEnabled = true
        case .followedViaTribe:
            disableSubscriptionButton()
        }
    }
    
    
    private func disableSubscriptionButton() {
        feedSubscriptionButton.isHidden = true
        feedSubscriptionButton.isEnabled = false
    }
}


extension FeedSearchResultCollectionViewCell {
    
    enum SubscriptionState {
        case subscribedFromPodcastIndex
        case subscriptionAvailableFromPodcastIndex
        case followedViaTribe
    }
}
