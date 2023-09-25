//
//  FeedItemDetailVM.swift
//  sphinx
//
//  Created by James Carucci on 3/2/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class FeedItemDetailVM : NSObject {
    
    var delegate: PodcastEpisodesDSDelegate?
    
    weak var vc: FeedItemDetailVC?
    weak var tableView:UITableView?
    
    var episode : PodcastEpisode?
    var video: Video?
    var indexPath : IndexPath
    
    let downloadService = DownloadService.sharedInstance
    
    func getActionsList() -> [FeedItemActionType]{
        if (video != nil) {
            return [
                .share,
                .copyLink
            ]
        }
        let isInQueue = FeedsManager.sharedInstance.queuedPodcastEpisodes.contains(where: {$0.itemID == episode?.itemID})
        if (episode?.feed?.isRecommendationsPodcast ?? false) {
            return [
                .share,
                .copyLink,
                (episode?.wasPlayed == true) ? .markAsUnplayed : .markAsPlayed,
                isInQueue ? .removeFromQueue : .addToQueue
            ]
        } else {
            return [
                episode?.isDownloaded ?? false ? .erase : .download,
                .share,
                .copyLink,
                (episode?.wasPlayed == true) ? .markAsUnplayed : .markAsPlayed,
                isInQueue ? .removeFromQueue : .addToQueue
            ]
        }
    }
    
    init(
        vc:FeedItemDetailVC,
        tableView:UITableView,
        episode:PodcastEpisode,
        delegate:PodcastEpisodesDSDelegate,
        indexPath:IndexPath
    ){
        self.vc = vc
        self.tableView = tableView
        self.episode = episode
        self.delegate = delegate
        self.indexPath = indexPath
        
        super.init()
        
        downloadService.setDelegate(
            delegate: self,
            forKey: DownloadServiceDelegateKeys.FeedItemDetailsDelegate
        )
    }
    
    init(
        vc:FeedItemDetailVC,
        tableView:UITableView,
        video:Video,
        delegate:PodcastEpisodesDSDelegate,
        indexPath:IndexPath
    ){
        self.vc = vc
        self.tableView = tableView
        self.video = video
        self.indexPath = indexPath
        
        super.init()
        
        downloadService.setDelegate(
            delegate: self,
            forKey: DownloadServiceDelegateKeys.FeedItemDetailsDelegate
        )
    }
    
    func setupTableView() {
        tableView?.register(UINib(nibName: "FeedItemDetailHeaderCell", bundle: nil), forCellReuseIdentifier: FeedItemDetailHeaderCell.reuseID)
        tableView?.register(UINib(nibName: "FeedItemDetailActionCell", bundle: nil), forCellReuseIdentifier: "FeedItemDetailActionCell")
        
        tableView?.delegate = self
        tableView?.dataSource = self
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.1, completion: {
            self.tableView?.scrollToBottom()
        })
    }
    
    func doAction(
        action: FeedItemActionType
    ) {
        switch(action){
        case .download:
            if let episode = episode {
                self.delegate?.downloadTapped(self.indexPath, episode: episode)
            }
            self.tableView?.reloadData()
            break
        case .markAsPlayed:
            setPlayedStatus(playStatus: true)
            break
        case .copyLink:
            if let episode = episode {
                if let link = episode.linkURLPath {
                    ClipboardHelper.copyToClipboard(text: link, message: "link.copied.clipboard".localized)
                }
            }
            else if let video = video {
                if let link = video.itemURL {
                    ClipboardHelper.copyToClipboard(text: link.absoluteString, message: "link.copied.clipboard".localized)
                }
            }
            
            break
        case .share:
            if let episode = episode {
                vc?.shareTapped(episode: episode)
            } else if let episode = video {
                vc?.shareTapped(video: episode)
            }
            break
        case .markAsUnplayed:
            setPlayedStatus(playStatus: false)
            break
        case .erase:
            if let episode = episode {
                self.delegate?.deleteTapped(self.indexPath, episode: episode)
                self.tableView?.reloadData()
            }
            break
        case .addToQueue:
            if let episode = episode{
                FeedsManager.sharedInstance.queuedPodcastEpisodes.append(episode)
                let fm = FeedsManager.sharedInstance
                let episodes = fm.queuedPodcastEpisodes
                print(episodes)
                self.tableView?.reloadData()
            }
            break
        case .removeFromQueue:
            if let episode = episode{
                FeedsManager.sharedInstance.queuedPodcastEpisodes = FeedsManager.sharedInstance.queuedPodcastEpisodes.filter({$0 != episode})
                self.tableView?.reloadData()
            }
            break
        }
    }
    
    func setPlayedStatus(
        playStatus: Bool
    ) {
        if let valid_episode = episode {
            
            valid_episode.wasPlayed = playStatus
            
            if let delegate = self.delegate as? NewPodcastPlayerViewController {
                delegate.reload(self.indexPath.row)
            } else if let delegate = self.delegate as? RecommendationFeedItemsCollectionViewController {
                delegate.configureDataSource(for: delegate.collectionView)
            }
            
            tableView?.reloadData()
        }
    }
    
}

extension FeedItemDetailVM : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 + getActionsList().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row  == 0 {
            return tableView.dequeueReusableCell(
                withIdentifier: FeedItemDetailHeaderCell.reuseID,
                for: indexPath
            ) as! FeedItemDetailHeaderCell
        } else {
            return tableView.dequeueReusableCell(
                withIdentifier: "FeedItemDetailActionCell",
                for: indexPath
            ) as! FeedItemDetailActionCell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? FeedItemDetailHeaderCell {
            if let episode = episode {
                cell.configureView(episode: episode)
            } else if let video = video {
                cell.configureView(video: video)
            }
        }
        
        if let cell = cell as? FeedItemDetailActionCell {
            let action = getActionsList()[indexPath.row - 1]
            
            if (action == .download) {
                if let episode = episode,
                    let url = episode.getRemoteAudioUrl()?.absoluteString,
                    let download = downloadService.activeDownloads[url] {
                    
                    cell.configureDownloading(download: download)
                    return
                }
            }
            cell.configureView(type: getActionsList()[indexPath.row - 1])
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row == 0) {
            return
        } else {
            let action = getActionsList()[indexPath.row - 1]
            doAction(action: action)
        }
    }
}

extension FeedItemDetailVM : DownloadServiceDelegate {
    func shouldReloadRowFor(download: Download) {
        if let episode = episode {
            if episode.getRemoteAudioUrl()?.absoluteString == download.originalUrl {
                tableView?.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
            }
        }
    }
}
