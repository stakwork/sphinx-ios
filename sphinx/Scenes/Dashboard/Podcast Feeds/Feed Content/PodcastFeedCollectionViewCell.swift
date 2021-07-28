//
// PodcastFeedCollectionViewCell.swift
// sphinx
//

import UIKit

protocol PodcastFeedCollectionViewCellDelegate: class {

    func collectionViewCell(
        _ cell: PodcastFeedCollectionViewCell,
        didSelect podcastFeed: PodcastFeed
    )
}


class PodcastFeedCollectionViewCell: UICollectionViewCell {
    
    weak var delegate: PodcastFeedCollectionViewCellDelegate?
    
    @IBOutlet weak var podcastImageView: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var podcastTitleLabel: UILabel!
    
    
    var podcastFeed: PodcastFeed! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithPodcastFeed()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        podcastImageView.layer.cornerRadius = 6.0
        podcastImageView.clipsToBounds = true
    }
    
  
    func configure(withPodcastFeed podcastFeed: PodcastFeed) {
        self.podcastFeed = podcastFeed
    }
    
    
    private func updateViewsWithPodcastFeed() {
        if let imageName = podcastFeed.image {
            podcastImageView.image = UIImage(named: imageName)
        }

        podcastNameLabel.text = podcastFeed.title
        podcastTitleLabel.text = podcastFeed.episodes.last?.title
    }
}
