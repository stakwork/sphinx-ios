//
//  ItemDescriptionViewController.swift
//  sphinx
//
//  Created by James Carucci on 4/4/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

protocol ItemDescriptionViewControllerDelegate{
    func shouldDismissAndPlayVideo(video:Video)
    func shouldDismissAndPlayVideo(episodeAsVideo:PodcastEpisode)
    func didDismissDescriptionView(index:Int)
}

class ItemDescriptionViewController : UIViewController{
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerContainerView: UIView!
    @IBOutlet weak var navbarPodcastTitle: UILabel!
    @IBOutlet weak var navBarPlayButton: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    var headerEffectView: UIVisualEffectView? = nil
    
    var podcastPlayerController = PodcastPlayerController.sharedInstance
    let downloadService = DownloadService.sharedInstance
    
    var index : Int?=nil
    
    var podcast : PodcastFeed!
    var episode: PodcastEpisode!
    
    var videoFeed:VideoFeed!
    var video:Video!
    
    var isExpanded : Bool = false
    var delegate : ItemDescriptionViewControllerDelegate? = nil
    
    let kHeaderCellHeight: CGFloat = 276.0
    let kDescriptionCellCollapsedHeight: CGFloat = 150.0
    let kHorizontalMargins: CGFloat = 32.0
    
    override func viewDidLoad() {
        downloadService.setDelegate(
            delegate: self,
            forKey: DownloadServiceDelegateKeys.PodcastPlayerDelegate
        )
        
        setupTableView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let index = index{
            self.delegate?.didDismissDescriptionView(index: index)
        }
    }
    
    static func instantiate(
        podcast: PodcastFeed,
        episode: PodcastEpisode,
        index:Int
    ) -> ItemDescriptionViewController {
        let viewController = StoryboardScene.WebApps.itemDescriptionViewController.instantiate()
        
        viewController.podcast = podcast
        viewController.episode = episode
        viewController.index = index
    
        return viewController
    }
    
    static func instantiate(
        videoFeed:VideoFeed,
        video:Video,
        index:Int
    )->ItemDescriptionViewController{
        let viewController = StoryboardScene.WebApps.itemDescriptionViewController.instantiate()
        
        viewController.video = video
        viewController.videoFeed = videoFeed
        viewController.index = index
    
        return viewController
    }
    
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func setupTableView(){
        navbarPodcastTitle.isHidden = true
        navBarPlayButton.isHidden = true
        navBarPlayButton.makeCircular()
        
        configurePausePlay()
        
        if let episode = episode {
            navbarPodcastTitle.text = episode.title
        } else if let video = video {
            navbarPodcastTitle.text = video.title
        }

        addBlur()
        
        tableView.register(UINib(nibName: "ItemDescriptionTableViewHeaderCell", bundle: nil), forCellReuseIdentifier: ItemDescriptionTableViewHeaderCell.reuseID)
        tableView.register(UINib(nibName: "ItemDescriptionTableViewCell", bundle: nil), forCellReuseIdentifier: ItemDescriptionTableViewCell.reuseID)
        tableView.register(UINib(nibName: "ItemDescriptionImageTableViewCell", bundle: nil), forCellReuseIdentifier: ItemDescriptionImageTableViewCell.reuseID)
        
        tableView.contentInset.top = 60.0
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    
    func addBlur() {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.prominent)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.frame = self.view.bounds
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(effectView)
        self.view.sendSubviewToBack(effectView)
        
        let headerBlurEffect = UIBlurEffect(style: UIBlurEffect.Style.prominent)
        headerEffectView = UIVisualEffectView(effect: headerBlurEffect)
        headerEffectView?.frame = self.headerContainerView.bounds
        headerEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        headerEffectView?.isHidden = true
        
        if let headerEffectView = headerEffectView {
            self.headerContainerView.addSubview(headerEffectView)
            self.headerContainerView.sendSubviewToBack(headerEffectView)
        }
    }
}

extension ItemDescriptionViewController : UITableViewDelegate, UITableViewDataSource, ItemDescriptionTableViewCellDelegate, UIScrollViewDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return tableView.dequeueReusableCell(
                withIdentifier: ItemDescriptionTableViewHeaderCell.reuseID,
                for: indexPath
            ) as! ItemDescriptionTableViewHeaderCell
        } else if indexPath.row == 1 {
            return tableView.dequeueReusableCell(
                withIdentifier: ItemDescriptionTableViewCell.reuseID,
                for: indexPath
            ) as! ItemDescriptionTableViewCell
        } else {
            return tableView.dequeueReusableCell(
                withIdentifier: ItemDescriptionImageTableViewCell.reuseID,
                for: indexPath
            ) as! ItemDescriptionImageTableViewCell
        }
        
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ItemDescriptionTableViewHeaderCell {
            if let podcast = podcast, let episode = episode {
                let download = downloadService.activeDownloads[episode.getRemoteAudioUrl()?.absoluteString ?? ""]
                cell.configureView(
                    podcast: podcast,
                    episode: episode,
                    download: download
                )
            } else if let video = video, let videoFeed = videoFeed {
                cell.configureView(
                    videoFeed: videoFeed,
                    video: video
                )
            }
            cell.delegate = self
        } else if let cell = cell as? ItemDescriptionTableViewCell {
            if let episode = episode {
                cell.configureView(
                    descriptionText: (episode.episodeDescription ?? "No description for this episode").nonHtmlRawString,
                    isExpanded: self.isExpanded
                )
            } else if let video = video {
                cell.configureView(
                    descriptionText: (video.videoDescription ?? "No description for this episode").nonHtmlRawString,
                    isExpanded: self.isExpanded
                )
            }
        } else if let cell = cell as? ItemDescriptionImageTableViewCell {
            if let episode = episode {
                cell.configureView(
                    imageURL: episode.imageToShow,
                    placeHolderImage: "podcastPlaceholder"
                )
            } else if let video = video {
                cell.configureView(
                    imageURL: video.thumbnailURL?.absoluteString,
                    placeHolderImage: "videoPlaceholder"
                )
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 {
            self.isExpanded = !self.isExpanded
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.row == 0) {
            return kHeaderCellHeight
        } else if(indexPath.row == 1){
            let description = episode?.episodeDescription ?? video?.videoDescription ?? ""
            
            if isExpanded {
                let font = UIFont(name: "Roboto-Regular", size: 14.0)!
                
                return UILabel.getLabelSize(
                    width: UIScreen.main.bounds.width - kHorizontalMargins,
                    text: description.nonHtmlRawString,
                    font: font
                ).height + kHorizontalMargins
                
            } else {
                return kDescriptionCellCollapsedHeight
            }
        } else {
            return UIScreen.main.bounds.width - 32.0
        }
    }
    
    func didExpandCell() {
        self.isExpanded = true
        tableView.reloadData()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let kPlayButtonYPosition: CGFloat = 172
        
        if(scrollView.contentOffset.y < kPlayButtonYPosition){
            if !navbarPodcastTitle.isHidden {
                
                self.navbarPodcastTitle.alpha = 1.0
                self.navBarPlayButton.alpha = 1.0
                self.navBarPlayButton.alpha = 0.0
                self.headerEffectView?.isHidden = true
                
                self.view.bringSubviewToFront(self.tableView)
                self.view.bringSubviewToFront(self.backButton)
                
                UIView.animate(withDuration: 0.25, delay: 0.0, animations: {
                    self.navbarPodcastTitle.alpha = 0.0
                },completion: {_ in
                    self.navbarPodcastTitle.isHidden = true
                    self.navBarPlayButton.isHidden = true
                })
            }
        } else {
            if navbarPodcastTitle.isHidden {
                
                self.navbarPodcastTitle.alpha = 0.0
                self.navBarPlayButton.alpha = 0.0
                self.navBarPlayButton.alpha = 1.0
                self.navbarPodcastTitle.isHidden = false
                self.navBarPlayButton.isHidden = false
                self.headerEffectView?.isHidden = false
                
                self.view.bringSubviewToFront(self.headerContainerView)
                self.view.bringSubviewToFront(self.backButton)
                
                UIView.animate(withDuration: 0.25, delay: 0.0, animations: {
                    self.navbarPodcastTitle.alpha = 1.0
                }, completion: {_ in })
            }
        }
    }
    
    func configurePausePlay(){
        if let episode = episode{
            navBarPlayButton.text = podcastPlayerController.isPlaying(episodeId: episode.itemID) ? "pause" : "play_arrow"
            tableView.reloadData()
        }
    }
    
    @IBAction func navBarTapped(){
        self.tableView.scrollToTop()
    }
    
    @IBAction func tappedPlay(){
        handlePlayerToggle()
    }
    
    func handlePlayerToggle(){
        if let episode = episode, let podcast = podcast, episode.isPodcast, let data = podcast.getPodcastData(episodeId: episode.itemID) {
            
            if podcastPlayerController.isPlaying(episodeId: episode.itemID){
                podcastPlayerController.submitAction(.Pause(data))
            } else{
                podcastPlayerController.submitAction(.Play(data))
            }
            configurePausePlay()
        } else if let video = video {
            self.navigationController?.popViewController(animated: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.delegate?.shouldDismissAndPlayVideo(video: video)
            })
        } else if let episode = episode, episode.isYoutubeVideo && episode.feed?.feedID == "Recommendations-Feed" {
            self.navigationController?.popViewController(animated: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.delegate?.shouldDismissAndPlayVideo(episodeAsVideo: episode)
            })
        }
        
    }
}

extension ItemDescriptionViewController : ItemDescriptionTableViewHeaderCellDelegate{
    func itemShareTapped(video: Video) {
        self.shareTapped(video: video)
    }
    
    func itemShareTapped(episode: PodcastEpisode) {
        self.askForShareType(episode: episode)
    }
    
    func itemMoreTapped(episode: PodcastEpisode) {
        let vc = FeedItemDetailVC.instantiate(episode: episode, delegate: self, indexPath: IndexPath(item: 0, section: 0))
        self.present(vc, animated: true)
    }
    
    func itemMoreTapped(video: Video) {
        let vc = FeedItemDetailVC.instantiate(video: video, delegate: self, indexPath: IndexPath(item: 0, section: 0))
        self.present(vc, animated: true)
    }
    
    func itemDownloadTapped(episode: PodcastEpisode) {
        downloadService.startDownload(episode)
        tableView.reloadRows(at: [IndexPath(item: 0, section: 0)], with: .none)
    }
    
    func didTogglePausePlay() {
        self.handlePlayerToggle()
    }
    
}

extension ItemDescriptionViewController: PodcastEpisodesDSDelegate {
    func didDismiss() {
        self.tableView.reloadData()
    }
    
    func didTapForDescriptionAt(episode: PodcastEpisode,cell:UITableViewCell) {}
    
    func didTapEpisodeWith(episodeId: String) {}
    
    func downloadTapped(_ indexPath: IndexPath, episode: PodcastEpisode) {
        itemDownloadTapped(episode: episode)
    }
    
    func deleteTapped(_ indexPath: IndexPath, episode: PodcastEpisode) {
        episode.shouldDeleteFile {
            self.tableView.reloadData()
        }
    }
    
    func shouldToggleTopView(show: Bool) {}
    
    func showEpisodeDetails(episode: PodcastEpisode, indexPath: IndexPath) {}
}


extension ItemDescriptionViewController:DownloadServiceDelegate {
    func shouldReloadRowFor(download: Download) {
        if let episode = episode {
            if episode.getRemoteAudioUrl()?.absoluteString == download.originalUrl {
                tableView?.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            }
        }
    }
}
