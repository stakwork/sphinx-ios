// VideoFeedEpisodePlayerCollectionViewDetailsCell.swift
//
// Created by CypherPoet.
// ✌️
//


import UIKit

class VideoFeedEpisodePlayerCollectionViewDetailsCell: UICollectionViewCell {
    
    @IBOutlet private weak var episodeDescriptionLabel: UILabel!
    @IBOutlet private weak var subscriptionToggleButton: UIButton!
    @IBOutlet weak var customBoostView: CustomBoostView!
    
    weak var boostDelegate: CustomBoostDelegate?
    
    var videoEpisode: Video! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithVideoEpisode()
            }
        }
    }
    
    var contentFeed: ContentFeed? = nil
    
    let feedBoostHelper = FeedBoostHelper()
}


// MARK: - Static Properties
extension VideoFeedEpisodePlayerCollectionViewDetailsCell {
    
    static let reuseID = "VideoFeedEpisodePlayerCollectionViewDetailsCell"
    
    static let nib: UINib = .init(
        nibName: "VideoFeedEpisodePlayerCollectionViewDetailsCell",
        bundle: nil
    )
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
        withVideoEpisode videoEpisode: Video,
        and boostDelegate: CustomBoostDelegate?
    ) {
        self.videoEpisode = videoEpisode
        self.boostDelegate = boostDelegate
        
        if let objectID = videoEpisode.videoFeed?.objectID {
            self.contentFeed = CoreDataManager.sharedManager.getObjectWith(objectId: objectID)
        }
        
        setupActions()
        setupFeedBoostHelper()
    }
    
    func setupFeedBoostHelper() {
        if let contentFeed = contentFeed {
            feedBoostHelper.configure(with: contentFeed.objectID, and: contentFeed.chat)
        }
    }
    
    func setupActions() {
        customBoostView.delegate = self
        
        if contentFeed?.destinationsArray.count == 0 {
            customBoostView.alpha = 0.3
            customBoostView.isUserInteractionEnabled = false
        }
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
}


// MARK: - Private Helpers
extension VideoFeedEpisodePlayerCollectionViewDetailsCell {
    
    private func setupViews() {
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

extension VideoFeedEpisodePlayerCollectionViewDetailsCell : CustomBoostViewDelegate {
    func didStartBoostAmountEdit() {
        
    }
    
    func didTouchBoostButton(withAmount amount: Int) {
        let itemID = videoEpisode.videoID
        
        if let boostMessage = feedBoostHelper.getBoostMessage(itemID: itemID, amount: amount) {
            
            let podcastAnimationVC = PodcastAnimationViewController.instantiate(amount: amount)
            WindowsManager.sharedInstance.showConveringWindowWith(rootVC: podcastAnimationVC)
            podcastAnimationVC.showBoostAnimation()
            
            feedBoostHelper.processPayment(itemID: itemID, amount: amount)
            
            feedBoostHelper.sendBoostMessage(
                message: boostMessage,
                itemObjectID: videoEpisode.objectID,
                amount: amount,
                completion: { (message, success) in
                    self.boostDelegate?.didSendBoostMessage(success: success, message: message)
                }
            )
        }
    }
}
