// VideoFeedEpisodesSectionHeaderView.swift
//
// Created by CypherPoet.
// ✌️
//


import UIKit


protocol VideoFeedEpisodesSectionHeaderViewDelegate: AnyObject {

    func headerViewDidTapSubscribeButton(
        _ headerView: VideoFeedEpisodesSectionHeaderView
    )
}


class VideoFeedEpisodesSectionHeaderView: UICollectionReusableView {
    @IBOutlet private weak var episodeCountNumberLabel: UILabel!
    @IBOutlet private weak var episodeCountTextLabel: UILabel!
    
    
    var videoFeedEpisode: Video! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithVideoEpisode()
            }
        }
    }
}


// MARK: - Static Properties
extension VideoFeedEpisodesSectionHeaderView {
    static let reuseID = "VideoFeedEpisodesSectionHeaderView"

    static let nib: UINib = {
        UINib(nibName: "VideoFeedEpisodesSectionHeaderView", bundle: nil)
    }()
}



// MARK: - Lifecycle
extension VideoFeedEpisodesSectionHeaderView {

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}



// MARK: - Computeds
extension VideoFeedEpisodesSectionHeaderView {

    private var episodeCount: Int {
        videoFeedEpisode.videoFeed?.videosArray.count ?? 0
    }
}


// MARK: - Public Methods
extension VideoFeedEpisodesSectionHeaderView {

    func configure(withEpisode videoFeedEpisode: Video) {
        self.videoFeedEpisode = videoFeedEpisode
    }
}



// MARK: - Private Helpers
extension VideoFeedEpisodesSectionHeaderView {

    private func updateViewsWithVideoEpisode() {
        episodeCountNumberLabel.text = "\(episodeCount)"

        episodeCountTextLabel.text = (
            episodeCount == 1 ?
                "video"
                : "videos"
        )
        .localized
        .capitalized
    }
}
