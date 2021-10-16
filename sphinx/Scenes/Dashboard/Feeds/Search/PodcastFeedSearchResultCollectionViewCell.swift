// PodcastFeedSearchResultCollectionViewCell.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit
import SDWebImage


class PodcastFeedSearchResultCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var feedThumbnailImageView: UIImageView!
    @IBOutlet weak var feedTitleLabel: UILabel!
    @IBOutlet weak var feedSubtitleLabel: UILabel!
    @IBOutlet weak var feedSubscriptionButton: UIButton!
    @IBOutlet weak var bottomSeparatorView: UIView!
    
    
    var item: PodcastFeedSearchResult! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithItem()
            }
        }
    }

    var onSubscriptionButtonTapped: ((PodcastFeedSearchResult, SubscriptionState) -> Void)?
    
    private var subscriptionState: SubscriptionState = .followedViaTribe
}



// MARK: - Static Properties
extension PodcastFeedSearchResultCollectionViewCell {
    static let reuseID = "PodcastFeedSearchResultCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "PodcastFeedSearchResultCollectionViewCell", bundle: nil)
    }()
}


// MARK: - Computeds
extension PodcastFeedSearchResultCollectionViewCell {
    
    var imageURL: URL? {
        item.imageURLPath.flatMap { URL(string: $0) }
    }
}
    

// MARK: - Lifecycle
extension PodcastFeedSearchResultCollectionViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        feedThumbnailImageView.layer.cornerRadius = 6.0
        feedThumbnailImageView.clipsToBounds = true
    }
}


// MARK: - Public Methods
extension PodcastFeedSearchResultCollectionViewCell {
    
    public func configure(
        withItem searchResult: PodcastFeedSearchResult,
        subscriptionState: SubscriptionState,
        shouldShowSeparator: Bool = false
    ) {
        bottomSeparatorView.isHidden = shouldShowSeparator == false
        
        if subscriptionState == .followedViaTribe {
            disableSubscriptionButton()
        }

        self.subscriptionState = subscriptionState
        item = searchResult
    }
}


// MARK: - Event Handling
extension PodcastFeedSearchResultCollectionViewCell {
    
    @IBAction func subscriptionButtonTapped(_ sender: UIButton) {
        onSubscriptionButtonTapped?(item, subscriptionState)
    }
}


// MARK: - Private Helpers
extension PodcastFeedSearchResultCollectionViewCell {
    
    private func updateViewsWithItem() {
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
        feedSubtitleLabel.text = item.podcastDescription
        
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


extension PodcastFeedSearchResultCollectionViewCell {
    
    enum SubscriptionState {
        case subscribedFromPodcastIndex
        case subscriptionAvailableFromPodcastIndex
        case followedViaTribe
    }
}
