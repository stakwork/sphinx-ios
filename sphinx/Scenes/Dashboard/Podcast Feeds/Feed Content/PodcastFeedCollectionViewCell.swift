//
// PodcastFeedCollectionViewCell.swift
// sphinx
//

import UIKit

protocol PodcastFeedCollectionViewCellDelegate: class {

//    func collectionViewCell(
//        _ cell: PodcastFeedCollectionViewCell,
//        didSelect podcastFeed: PodcastFeed
//    )
    func collectionViewCellDidSelect(
        _ cell: PodcastFeedCollectionViewCell
    )
}


protocol DashboardPodcastCollectionViewItem {
    var imageName: String { get }
    var title: String { get }
    var subtitle: String { get }
}


class PodcastFeedCollectionViewCell: UICollectionViewCell {
    
//    weak var delegate: PodcastFeedCollectionViewCellDelegate?
    
    @IBOutlet weak var podcastImageView: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var podcastTitleLabel: UILabel!
    
    
//    var podcastFeed: PodcastFeed! {
//        didSet {
//            DispatchQueue.main.async { [weak self] in
//                self?.updateViewsWithPodcastFeed()
//            }
//        }
//    }
    
    var item: DashboardPodcastCollectionViewItem! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithItem()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        podcastImageView.layer.cornerRadius = 6.0
        podcastImageView.clipsToBounds = true
    }
    
  
//    func configure(withPodcastFeed podcastFeed: PodcastFeed) {
//        self.podcastFeed = podcastFeed
//    }
//
    
      func configure(withItem dataItem: DashboardPodcastCollectionViewItem) {
          self.item = dataItem
      }
    
//    private func updateViewsWithPodcastFeed() {
//        podcastImageView.image = UIImage(named: podcastFeed.image)
//        podcastNameLabel.text = podcastFeed.title
//        podcastTitleLabel.text = podcastFeed.episodes.last?.title
//    }
    
    private func updateViewsWithItem() {
        podcastImageView.image = UIImage(named: item.imageName)
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
