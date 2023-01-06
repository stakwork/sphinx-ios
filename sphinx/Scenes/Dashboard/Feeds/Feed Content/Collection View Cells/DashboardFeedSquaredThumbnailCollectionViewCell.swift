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
    var publishDate: Date? { get }
    var placeholderImageName: String? { get }
    var typeIconImage: String? { get }
    var titleLines: Int { get }
}


class DashboardFeedSquaredThumbnailCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var typeIconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    
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
        
        titleLabel.numberOfLines = item.titleLines
        subtitleLabel.numberOfLines = 4 - item.titleLines
        
        titleLabel.textColor = UIColor.Sphinx.Text
        subtitleLabel.textColor = UIColor.Sphinx.SecondaryText
        
        if let typeIcon = item.typeIconImage {
            typeIconImageView.image = UIImage(named: typeIcon)
            typeIconImageView.isHidden = false
        } else {
            typeIconImageView.isHidden = true
        }
        
        dateLabel.text = item.publishDate?.timeIntervalSince1970.getDayDiffString() ?? ""
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
    
    var titleLines: Int {
        1
    }
    
    var publishDate: Date? {
        return nil
    }
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
    
    var titleLines: Int {
        1
    }
    
    var publishDate: Date? {
        return nil
    }
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
            case RecommendationsHelper.TWITTER_TYPE:
                return "twitterTypeIcon"
            default:
                return "podcastTypeIcon"
            }
        }
    }

    var subtitle: String? {
        formattedDescription
    }
    
    var titleLines: Int {
        1
    }
    
    var publishDate: Date? {
        return nil
    }
}


extension PodcastFeed: DashboardFeedSquaredThumbnailCollectionViewItem {
    var placeholderImageName: String? {
        "podcastPlaceholder"
    }

    var subtitle: String? {
        podcastDescription ?? ""
    }
    
    var typeIconImage: String? { get { nil }}
    
    var titleLines: Int {
        1
    }
    
    var publishDate: Date? {
        return nil
    }
}

extension TimeInterval {
    func getDayDiffString() -> String {
        let SECOND_MILLIS = 1000
        let MINUTE_MILLIS = 60 * SECOND_MILLIS
        let HOUR_MILLIS = 60 * MINUTE_MILLIS
        let DAY_MILLIS = 24 * HOUR_MILLIS

        var time = self * 1000
        if (time < 1000000000000) {
            time *= 1000
        }

        let now = Date().timeIntervalSince1970 * 1000
        if (time > now || time <= 0) {
            return "time.in-the-future".localized
        }

        let diff = Int(now - time)
        
        if (diff < MINUTE_MILLIS) { return "time.moments-ago".localized }
        else if (diff < 2 * MINUTE_MILLIS) { return "time.a-minute-ago".localized }
        else if (diff < 60 * MINUTE_MILLIS) { return String(format: "time.minutes-ago".localized, diff / MINUTE_MILLIS) }
        else if (diff < 2 * HOUR_MILLIS) { return "time.an-hour-ago".localized }
        else if (diff < 24 * HOUR_MILLIS) { return String(format: "time.hours-ago".localized, diff / HOUR_MILLIS) }
        else if (diff < 48 * HOUR_MILLIS) { return "time.yesterday".localized }
        else { return String(format: "time.days-ago".localized, diff / DAY_MILLIS) }
    }
}
