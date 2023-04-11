//
//  UnifiedEpisodeTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 2/28/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class UnifiedEpisodeTableViewCell: UITableViewCell {
    
    @IBOutlet weak var unifiedEpisodeView: UnifiedEpisodeView!
    
    weak var delegate : FeedItemRowDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureWith(
        podcast: PodcastFeed?,
        and episode: PodcastEpisode,
        download: Download?,
        delegate: FeedItemRowDelegate,
        isLastRow: Bool,
        playing: Bool,
        playingSound: Bool = false
    ) {
        self.delegate = delegate
        
        unifiedEpisodeView.configureWith(
            podcast: podcast,
            and: episode,
            download: download,
            delegate: self,
            isLastRow: isLastRow,
            playing: playing,
            playingSound: playingSound
        )
    }
    
}

extension UnifiedEpisodeTableViewCell : PodcastEpisodeRowDelegate {
    func shouldShowDescription(episode:PodcastEpisode){
        delegate?.shouldShowDescription(episode: episode,cell: self)
    }
    
    func shouldShowDescription(video:Video){
        delegate?.shouldShowDescription(video: video)
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
