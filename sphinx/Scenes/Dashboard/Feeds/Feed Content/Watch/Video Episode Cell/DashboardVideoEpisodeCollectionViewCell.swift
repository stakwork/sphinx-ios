// DashboardVideoEpisodeCollectionViewCell.swift
//
// Created by CypherPoet.
// ✌️
//
    

import UIKit


class DashboardVideoEpisodeCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var thumbnailImageView: UIImageView!
//    @IBOutlet weak var episodeTitleLabel: UILabel!
//    @IBOutlet weak var feedNameLabel: UILabel!
    
    
    var videoEpisode: Video! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithVideoEpisode()
            }
        }
    }
}


// MARK: - Computeds
extension DashboardVideoEpisodeCollectionViewCell {
    
    var feedImageViewURL: URL? {
        videoEpisode.thumbnailURL
    }
}
    

// MARK: - Lifecycle
extension DashboardVideoEpisodeCollectionViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        thumbnailImageView.layer.cornerRadius = 8.0
        thumbnailImageView.clipsToBounds = true
    }
    
    
    func configure(withVideoEpisode videoEpisode: Video) {
        self.videoEpisode = videoEpisode
    }
    
    
    private func updateViewsWithVideoEpisode() {
        if let imageURL = feedImageViewURL {
            thumbnailImageView.sd_setImage(
                with: imageURL,
                placeholderImage: UIImage(named: "podcastPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            // 📝 TODO:  Use a video placeholder here
            thumbnailImageView.image = UIImage(named: "podcastPlaceholder")
        }
        
//        episodeTitleLabel.text = videoEpisode.title
    }
}



// MARK: - Static Properties
extension DashboardVideoEpisodeCollectionViewCell {
    static let reuseID = "DashboardVideoEpisodeCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "DashboardVideoEpisodeCollectionViewCell", bundle: nil)
    }()
}
