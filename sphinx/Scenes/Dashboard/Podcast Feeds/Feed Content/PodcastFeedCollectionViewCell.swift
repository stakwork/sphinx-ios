//
// PodcastFeedCollectionViewCell.swift
// sphinx
//

import UIKit
import SDWebImage


protocol DashboardPodcastCollectionViewItem {
    var imageURLPath: String? { get }
    var title: String? { get }
    var subtitle: String? { get }
}


class PodcastFeedCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var podcastImageView: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var podcastTitleLabel: UILabel!
    
    
    var item: DashboardPodcastCollectionViewItem! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithItem()
            }
        }
    }
}


extension PodcastFeedCollectionViewCell {
    
    var imageURL: URL? {
        item.imageURLPath.flatMap { URL(string: $0) }
    }
}
    

extension PodcastFeedCollectionViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        podcastImageView.layer.cornerRadius = 6.0
        podcastImageView.clipsToBounds = true
    }
    
    
    func configure(withItem dataItem: DashboardPodcastCollectionViewItem) {
        self.item = dataItem
    }
    
    
    private func updateViewsWithItem() {
        if let imageURL = imageURL {
            podcastImageView.sd_setImage(
                with: imageURL,
                placeholderImage: UIImage(named: "podcastTagIcon"),
                options: [.highPriority],
                progress: nil
            )
            
            podcastImageView.sd_imageIndicator = SDWebImageProgressIndicator.default
        } else {
            // TODO: Use  a placeholder here?
            podcastImageView.image = UIImage(named: "podcastTagIcon")
        }
        
        podcastNameLabel.text = item.title
        podcastTitleLabel.text = item.subtitle
    }
}



// MARK: - Static Properties
extension PodcastFeedCollectionViewCell {
    static let reuseID = "PodcastFeedCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "PodcastFeedCollectionViewCell", bundle: nil)
    }()
}
