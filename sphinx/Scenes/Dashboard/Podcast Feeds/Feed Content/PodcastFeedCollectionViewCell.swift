//
// PodcastFeedCollectionViewCell.swift
// sphinx
//

import UIKit


protocol DashboardPodcastCollectionViewItem {
    var imageName: String? { get }
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        podcastImageView.layer.cornerRadius = 6.0
        podcastImageView.clipsToBounds = true
    }
    
    
    func configure(withItem dataItem: DashboardPodcastCollectionViewItem) {
        self.item = dataItem
    }
    
    
    private func updateViewsWithItem() {
        // TODO: This is probably going to have to use SDWebImage and the item's url
        podcastImageView.image = UIImage(named: item.imageName ?? "podcastTagIcon")
        
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
