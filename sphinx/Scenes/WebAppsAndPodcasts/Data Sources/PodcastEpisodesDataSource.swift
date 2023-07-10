//
//  PodcastEpisodesDataSource.swift
//  sphinx
//
//  Created by Tomas Timinskas on 13/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol PodcastEpisodesDSDelegate : class {
    func didTapForDescriptionAt(episode:PodcastEpisode,cell:UITableViewCell)
    func didTapEpisodeWith(episodeId: String)
    func downloadTapped(_ indexPath: IndexPath, episode: PodcastEpisode)
    func deleteTapped(_ indexPath: IndexPath, episode: PodcastEpisode)
    func shouldToggleTopView(show: Bool)
    func shareTapped(episode:PodcastEpisode)
    func showEpisodeDetails(episode:PodcastEpisode,indexPath:IndexPath)
    func didDismiss()
}

class PodcastEpisodesDataSource : NSObject {
    
    weak var delegate: PodcastEpisodesDSDelegate?
    
    let kRowHeight: CGFloat = 200
    let kHeaderHeight: CGFloat = 50
    let kHeaderLabelFont = UIFont(name: "Roboto-Medium", size: 14.0)!
    let windowTopInset = getWindowInsets().top
    
    var tableView: UITableView! = nil
    var podcast: PodcastFeed! = nil
    var episodes: [PodcastEpisode] = []
    
    let podcastPlayerController = PodcastPlayerController.sharedInstance
    
    let downloadService = DownloadService.sharedInstance
    
    init(
        tableView: UITableView,
        podcast: PodcastFeed,
        delegate: PodcastEpisodesDSDelegate,
        fromDownloadedSection: Bool
    ) {
        super.init()
        
        self.tableView = tableView
        self.podcast = podcast
        self.episodes = fromDownloadedSection ? podcast.episodesArray.filter({$0.isDownloaded == true}) : podcast.episodesArray
        self.delegate = delegate
        
        self.tableView.registerCell(UnifiedEpisodeTableViewCell.self)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
    }
}

extension PodcastEpisodesDataSource : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return kRowHeight
    }
    
    func getEpisodes() -> [PodcastEpisode] {
        return self.episodes
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? UnifiedEpisodeTableViewCell {
            
            let episodes = getEpisodes()
            let episode = episodes[indexPath.row]
            let download = downloadService.activeDownloads[episode.getRemoteAudioUrl()?.absoluteString ?? ""]
            
            let isPlaying = podcastPlayerController.isPlaying(episodeId: episode.itemID)
            
            cell.configureWith(
                podcast: podcast,
                and: episode,
                download: download,
                delegate: self,
                isLastRow: indexPath.row + 1 == episodes.count,
                playing: isPlaying,
                playingSound: podcastPlayerController.isSoundPlaying
            )
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let episodes = podcast.episodes ?? []
        
        if episodes.count > 0 {
            return kHeaderHeight
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let windowWidth = WindowsManager.getWindowWidth()
        let episodes = podcast.episodes ?? []
        
        let headerView = EpisodesHeaderView(frame: CGRect(x: 0, y: 0, width: windowWidth, height: kHeaderHeight))
        headerView.configureWith(count: episodes.count)
        headerView.addShadow(offset: CGSize(width: 0.0, height: 5.0), opacity: 0.15, radius: 3)
        return headerView
    }
}

extension PodcastEpisodesDataSource : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getEpisodes().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(
            withIdentifier: "UnifiedEpisodeTableViewCell",
            for: indexPath
        ) as! UnifiedEpisodeTableViewCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episode = getEpisodes()
        
        if episode.count > indexPath.row {
            let episodeId = episode[indexPath.row].itemID
            delegate?.didTapEpisodeWith(episodeId: episodeId)
        }
    }
}

extension PodcastEpisodesDataSource : UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let firstVisibleCell = tableView.indexPathsForVisibleRows?.first {
            let rectForRow = tableView.rectForRow(at: firstVisibleCell)
            let shouldShow = (tableView.contentOffset.y + windowTopInset + kHeaderHeight >= rectForRow.origin.y)
            delegate?.shouldToggleTopView(show: shouldShow)
        }
    }
}

extension PodcastEpisodesDataSource : FeedItemRowDelegate {
    func shouldShowDescription(episode: PodcastEpisode,cell:UITableViewCell) {
        delegate?.didTapForDescriptionAt(episode:episode,cell:cell)
    }
    
    func shouldShowDescription(video: Video) {}
    
    func shouldShowMore(video: Video, cell: UICollectionViewCell) {}
    
    func shouldShare(video: Video) {}
    
    func shouldStartDownloading(episode: PodcastEpisode, cell: UICollectionViewCell) {}
    
    func shouldDeleteFile(episode: PodcastEpisode, cell: UICollectionViewCell) {}
    
    func shouldShowMore(episode: PodcastEpisode, cell: UICollectionViewCell) {}
   
    func shouldDeleteFile(episode: PodcastEpisode, cell: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            delegate?.deleteTapped(indexPath, episode: episode)
        }
    }
    
    func shouldStartDownloading(episode: PodcastEpisode, cell: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: cell){
            delegate?.downloadTapped(indexPath, episode: episode)
        }
    }
    
    func shouldShare(episode: PodcastEpisode) {
        delegate?.shareTapped(episode: episode)
    }
    
    func shouldShowMore(episode: PodcastEpisode, cell: UITableViewCell){
        if let indexPath = tableView.indexPath(for: cell) {
            delegate?.showEpisodeDetails(episode: episode,indexPath: indexPath)
        }
    }
}
