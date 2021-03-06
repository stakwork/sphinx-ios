//
//  PodcastEpisodesDataSource.swift
//  sphinx
//
//  Created by Tomas Timinskas on 13/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol PodcastEpisodesDSDelegate : class {
    func didTapEpisodeAt(index: Int)
    func downloadTapped(_ indexPath: IndexPath, episode: PodcastEpisode)
    func shouldToggleTopView(show: Bool)
}

class PodcastEpisodesDataSource : NSObject {
    
    weak var delegate: PodcastEpisodesDSDelegate?
    
    let kRowHeight: CGFloat = 64
    let kHeaderHeight: CGFloat = 50
    let kHeaderLabelFont = UIFont(name: "Roboto-Medium", size: 14.0)!
    let windowTopInset = getWindowInsets().top
    
    var tableView: UITableView! = nil
    var playerHelper: PodcastPlayerHelper! = nil
    
    let downloadService = DownloadService.sharedInstance
    
    init(tableView: UITableView, playerHelper: PodcastPlayerHelper, delegate: PodcastEpisodesDSDelegate) {
        super.init()
        
        PodcastEpisodeTableViewCell.podcastImage = nil
        
        self.tableView = tableView
        self.playerHelper = playerHelper
        self.delegate = delegate
        
        self.tableView.registerCell(PodcastEpisodeTableViewCell.self)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
    }
}

extension PodcastEpisodesDataSource : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return kRowHeight
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? PodcastEpisodeTableViewCell {
            let episodes = playerHelper.podcast?.episodes ?? []
            let episode = episodes[indexPath.row]
            let download = downloadService.activeDownloads[episode.url ?? ""]
            let isPlaying = (playerHelper.currentEpisode == indexPath.row && playerHelper.isPlaying())
            cell.configureWith(podcast: playerHelper.podcast, and: episode, download: download, delegate: self, isLastRow: indexPath.row + 1 == episodes.count, playing: isPlaying)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let episodes = playerHelper.podcast?.episodes ?? []
        
        if episodes.count > 0 {
            return kHeaderHeight
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let windowWidth = WindowsManager.getWindowWidth()
        let episodes = playerHelper.podcast?.episodes ?? []
        
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
        let episodes = playerHelper.podcast?.episodes ?? []
        return episodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PodcastEpisodeTableViewCell", for: indexPath) as! PodcastEpisodeTableViewCell
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didTapEpisodeAt(index: indexPath.row)
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

extension PodcastEpisodesDataSource : PodcastEpisodeRowDelegate {
    func shouldStartDownloading(episode: PodcastEpisode, cell: PodcastEpisodeTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            delegate?.downloadTapped(indexPath, episode: episode)
        }
    }
}
