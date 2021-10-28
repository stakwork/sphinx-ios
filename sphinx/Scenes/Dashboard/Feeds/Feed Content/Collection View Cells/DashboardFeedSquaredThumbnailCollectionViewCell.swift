//
// DashboardFeedSquaredThumbnailCollectionViewCell.swift
// sphinx
//

import UIKit
import SDWebImage


protocol DashboardFeedSquaredThumbnailCollectionViewItem {
    var imageURLPath: String? { get }
    var title: String? { get }
    var subtitle: String? { get }
    var placeholderImageName: String? { get }
}


class DashboardFeedSquaredThumbnailCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    
    
    var item: DashboardFeedSquaredThumbnailCollectionViewItem! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithItem()
            }
        }
    }
}


extension DashboardFeedSquaredThumbnailCollectionViewCell {
    
    var imageURL: URL? {
        item.imageURLPath.flatMap { URL(string: $0) }
    }
    
    var placeholderImage: UIImage? {
        UIImage(named: item.placeholderImageName ?? "podcastPlaceholder")
    }
}
    

extension DashboardFeedSquaredThumbnailCollectionViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        thumbnailImageView.layer.cornerRadius = 6.0
        thumbnailImageView.clipsToBounds = true
    }
    
    
    func configure(withItem dataItem: DashboardFeedSquaredThumbnailCollectionViewItem) {
        self.item = dataItem
    }
    
    
    private func updateViewsWithItem() {
        if let imageURL = imageURL {
            thumbnailImageView.sd_setImage(
                with: imageURL,
                placeholderImage: placeholderImage,
                options: [.highPriority],
                progress: nil
            )
        } else {
            thumbnailImageView.image = placeholderImage
        }
        
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
    }
}



// MARK: - Static Properties
extension DashboardFeedSquaredThumbnailCollectionViewCell {
    static let reuseID = "DashboardFeedSquaredThumbnailCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "DashboardFeedSquaredThumbnailCollectionViewCell", bundle: nil)
    }()
}


// MARK: - DashboardFeedSquaredThumbnailCollectionViewItem - NSManagedObject Conformance
extension VideoFeed: DashboardFeedSquaredThumbnailCollectionViewItem {
    
    var imageURLPath: String? {
        chat?.photoUrl
    }
    
    var placeholderImageName: String? {
        "podcastPlaceholder"
    }
    
    var subtitle: String? {
        title
    }
}



extension PodcastEpisode: DashboardFeedSquaredThumbnailCollectionViewItem {
    var placeholderImageName: String? {
        "podcastPlaceholder"
    }

    var subtitle: String? {
        formattedDescription
    }
}


extension PodcastFeed: DashboardFeedSquaredThumbnailCollectionViewItem {
    var placeholderImageName: String? {
        "podcastPlaceholder"
    }

    var subtitle: String? {
        podcastDescription ?? ""
    }
}
