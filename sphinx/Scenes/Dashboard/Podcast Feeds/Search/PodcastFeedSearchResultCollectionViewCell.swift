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
    
    
    var item: PodcastFeedSearchResult! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithItem()
            }
        }
    }
}


extension PodcastFeedSearchResultCollectionViewCell {
    
    var imageURL: URL? {
        item.imageURLPath.flatMap{ URL(string: $0) }
    }
}
    

extension PodcastFeedSearchResultCollectionViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        feedThumbnailImageView.layer.cornerRadius = 6.0
        feedThumbnailImageView.clipsToBounds = true
    }
    
    
    func configure(withItem searchResult: PodcastFeedSearchResult) {
        self.item = searchResult
    }
    
    
    private func updateViewsWithItem() {
        if let imageURL = imageURL {
            feedThumbnailImageView.sd_setImage(
                with: imageURL,
                placeholderImage: UIImage(named: "podcastTagIcon"),
                options: [.highPriority],
                progress: nil
            )
            
            feedThumbnailImageView.sd_imageIndicator = SDWebImageProgressIndicator.default
        } else {
            // TODO: Use  a placeholder here?
            feedThumbnailImageView.image = UIImage(named: "podcastTagIcon")
        }
        
        feedTitleLabel.text = item.title
        feedSubtitleLabel.text = item.subtitle
    }
}



// MARK: - Static Properties
extension PodcastFeedSearchResultCollectionViewCell {
    static let reuseID = "PodcastFeedSearchResultCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "PodcastFeedSearchResultCollectionViewCell", bundle: nil)
    }()
}
