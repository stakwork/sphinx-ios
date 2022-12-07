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
    var typeIconImage: String? { get }
    var titleFontColor: UIColor? { get }
    var subTitleFontColor: UIColor? { get }
}


class DashboardFeedSquaredThumbnailCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var typeIconImageView: UIImageView!
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
        
        typeIconImageView.layer.cornerRadius = 4.0
        typeIconImageView.clipsToBounds = true
        
        typeIconImageView.isHidden = true
    }
    
    
    func configure(withItem dataItem: DashboardFeedSquaredThumbnailCollectionViewItem) {
        self.item = dataItem
    }
    
    private func updateViewsWithItem() {
        thumbnailImageView.sd_cancelCurrentImageLoad()
        
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
        
        titleLabel.textColor = item.titleFontColor ?? UIColor.Sphinx.Text
        subtitleLabel.textColor = item.subTitleFontColor ?? UIColor.Sphinx.SecondaryText
        
        if let typeIcon = item.typeIconImage {
            typeIconImageView.image = UIImage(named: typeIcon)
            typeIconImageView.isHidden = false
        } else {
            typeIconImageView.isHidden = true
        }
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
extension ContentFeed: DashboardFeedSquaredThumbnailCollectionViewItem {
    
    var imageURLPath: String? {
        imageURL?.absoluteString ?? chat?.photoUrl
    }
    
    var placeholderImageName: String? {
        "videoPlaceholder"
    }
    
    var subtitle: String? {
        get {
            if (feedDescription?.isEmpty == true) {
                return title
            }
            return feedDescription ?? title
        }
    }
    
    var typeIconImage: String? { get { nil }}
    var titleFontColor: UIColor? { get { nil }}
    var subTitleFontColor: UIColor? { get { nil }}
}

extension VideoFeed: DashboardFeedSquaredThumbnailCollectionViewItem {
    
    var imageURLPath: String? {
        imageURL?.absoluteString ?? chat?.photoUrl
    }
    
    var placeholderImageName: String? {
        "videoPlaceholder"
    }
    
    var subtitle: String? {
        title
    }
    
    var typeIconImage: String? { get { nil }}
    var titleFontColor: UIColor? { get { nil }}
    var subTitleFontColor: UIColor? { get { nil }}
}



extension PodcastEpisode: DashboardFeedSquaredThumbnailCollectionViewItem {
    
    var placeholderImageName: String? {
        switch type {
        case RecommendationsHelper.PODCAST_TYPE:
            return "podcastPlaceholder"
        case RecommendationsHelper.YOUTUBE_VIDEO_TYPE:
            return "videoPlaceholder"
        case RecommendationsHelper.NEWSLETTER_TYPE:
            return "newsletterPlaceholder"
        default:
            return "podcastPlaceholder"
        }
    }
    
    var typeIconImage: String? {
        get {
            switch type {
            case RecommendationsHelper.PODCAST_TYPE:
                return "podcastTypeIcon"
            case RecommendationsHelper.YOUTUBE_VIDEO_TYPE:
                return "youtubeVideoTypeIcon"
            case RecommendationsHelper.NEWSLETTER_TYPE:
                return "newsletterPlaceholder"
            default:
                return "podcastTypeIcon"
            }
        }
    }

    var subtitle: String? {
        formattedDescription
    }
    
    var titleFontColor: UIColor? { get { nil }}
    var subTitleFontColor: UIColor? { get { nil }}
}


extension PodcastFeed: DashboardFeedSquaredThumbnailCollectionViewItem {
    var placeholderImageName: String? {
        "podcastPlaceholder"
    }

    var subtitle: String? {
        podcastDescription ?? ""
    }
    
    var typeIconImage: String? { get { nil }}
    var titleFontColor: UIColor? { get { nil }}
    var subTitleFontColor: UIColor? { get { nil }}
}
