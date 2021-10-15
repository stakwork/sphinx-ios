// DashboardVideoFeedCollectionViewCell.swift
//
// Created by CypherPoet.
// ✌️
//
    

import UIKit


class DashboardVideoFeedCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var feedImageView: UIImageView!
    @IBOutlet weak var feedNameLabel: UILabel!
    @IBOutlet weak var feedDescriptionLabel: UILabel!
    
    
    var videoFeed: VideoFeed! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithVideoFeed()
            }
        }
    }
}


// MARK: - Computeds
extension DashboardVideoFeedCollectionViewCell {
    
    var feedImageViewURL: URL? {
        videoFeed.chat?.photoUrl.flatMap { URL(string: $0) }
    }
}
    

// MARK: - Lifecycle
extension DashboardVideoFeedCollectionViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        feedImageView.layer.cornerRadius = 6.0
        feedImageView.clipsToBounds = true
//        feedImageView.contentMode = .scaleAspectFit
    }
    
    
    func configure(withVideoFeed videoFeed: VideoFeed) {
        self.videoFeed = videoFeed
    }
    
    
    private func updateViewsWithVideoFeed() {
        if let imageURL = feedImageViewURL {
            feedImageView.sd_setImage(
                with: imageURL,
                placeholderImage: UIImage(named: "podcastPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            // 📝 TODO:  Use a video placeholder here
            feedImageView.image = UIImage(named: "podcastPlaceholder")
        }
        
        feedNameLabel.text = videoFeed.title
    }
}



// MARK: - Static Properties
extension DashboardVideoFeedCollectionViewCell {
    static let reuseID = "DashboardVideoFeedCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "DashboardVideoFeedCollectionViewCell", bundle: nil)
    }()
}
