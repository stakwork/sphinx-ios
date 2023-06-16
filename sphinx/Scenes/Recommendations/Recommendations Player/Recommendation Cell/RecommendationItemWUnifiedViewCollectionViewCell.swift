//
//  RecommendationItemWUnifiedViewCollectionViewCell.swift
//  sphinx
//
//  Created by James Carucci on 3/6/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class RecommendationItemWUnifiedViewCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var unifiedEpisodeView: UnifiedEpisodeView!
    
    weak var delegate : FeedItemRowDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(
        withItem item: PodcastEpisode,
        andDelegate delegate: FeedItemRowDelegate,
        isPlaying: Bool
    ) {
        if let feed = item.feed {
            self.delegate = delegate
            
            unifiedEpisodeView.configureWith(
                podcast: feed,
                and: item,
                download: nil,
                delegate: self,
                isLastRow: false,
                playing: isPlaying
            )
        }
    }
    
    func configure(
        withVideoEpisode videoEpisode: Video,
        and delegate: FeedItemRowDelegate
    ) {
        self.delegate = delegate
        
        let url = URL(string: "https://s3.amazonaws.com/stakwork-uploads/uploads/customers/4291/media_to_local/cd7cae99-bb29-4f40-b050-4ade06b2fbf7/_-9RGlBIma8.mp4")
        let download = DownloadService.sharedInstance.activeVideoDownloads[url!.absoluteString]
        
        unifiedEpisodeView.configure(
            withVideoEpisode: videoEpisode,
            download: download,
            and: self
        )
    }
    
}

extension RecommendationItemWUnifiedViewCollectionViewCell : PodcastEpisodeRowDelegate {
    func shouldShowDescription(episode: PodcastEpisode) {
        delegate?.shouldShowDescription(episode: episode,cell:UITableViewCell())
    }
    func shouldStartDownloading(episode: PodcastEpisode) {
        delegate?.shouldStartDownloading(episode: episode, cell: self)
    }
    
    func shouldDeleteFile(episode: PodcastEpisode) {
        delegate?.shouldDeleteFile(episode: episode, cell: self)
    }
    
    func shouldShowMore(episode: PodcastEpisode) {
        delegate?.shouldShowMore(episode: episode, cell: self)
    }
    
    func shouldShare(episode: PodcastEpisode) {
        delegate?.shouldShare(episode: episode)
    }
}

extension RecommendationItemWUnifiedViewCollectionViewCell : VideoRowDelegate {
    func shouldStartDownloading(video: Video) {
        if let delegate = delegate as? VideoFeedEpisodePlayerCollectionViewController{
            delegate.shouldDownloadVideo(video: video)
        }
    }
    
    func shouldShowDescription(video: Video) {
        delegate?.shouldShowDescription(video: video)
    }
    
    func shouldShowMore(video: Video) {
        delegate?.shouldShowMore(video: video, cell: self)
    }
    
    func shouldShare(video: Video) {
        delegate?.shouldShare(video: video)
    }
    
}

// MARK: - Static Properties
extension RecommendationItemWUnifiedViewCollectionViewCell {
    
    static let reuseID = "RecommendationItemWUnifiedViewCollectionViewCell"
    
    static let nib: UINib = .init(
        nibName: "RecommendationItemWUnifiedViewCollectionViewCell",
        bundle: nil
    )
}
