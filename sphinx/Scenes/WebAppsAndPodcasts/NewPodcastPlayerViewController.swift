//
//  NewPodcastPlayerViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol PodcastPlayerVCDelegate: AnyObject {
    func willDismissPlayer()
    func shouldShareClip(comment: PodcastComment)
    func shouldGoToPlayer(podcast: PodcastFeed)
    func didFailPlayingPodcast()
}

@objc protocol CustomBoostDelegate: AnyObject {
    func didSendBoostMessage(success: Bool, message: TransactionMessage?)
    @objc optional func didStartEditingBoostAmount()
}

class NewPodcastPlayerViewController: UIViewController {
    
    weak var delegate: PodcastPlayerVCDelegate?
    weak var boostDelegate: CustomBoostDelegate?
    
    @IBOutlet weak var topFixingView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var tableHeaderView: PodcastPlayerView?
    
    var podcast: PodcastFeed! = nil
    var deeplinkedEpisode:PodcastEpisode? = nil
    var deeplinkTimestamp:Int? = nil
    
    var chat: Chat? {
        get {
            return podcast.chat
        }
    }
    
    var fromDashboard = false
    
    var podcastPlayerController = PodcastPlayerController.sharedInstance
    
    let downloadService = DownloadService.sharedInstance
    
    var tableDataSource: PodcastEpisodesDataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        downloadService.setDelegate(delegate: self)
        
        showPodcastInfo()
        updateFeed()
        
        NotificationCenter.default.addObserver(forName: .onConnectionStatusChanged, object: nil, queue: OperationQueue.main) { (n: Notification) in
            self.tableView.reloadData()
        }
        
        NotificationCenter.default.removeObserver(self, name: .refreshFeedUI, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showPodcastInfo), name: .refreshFeedUI, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let episode = deeplinkedEpisode{
            self.tableHeaderView?.playEpisode(episode: episode)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .onConnectionStatusChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: .refreshFeedUI, object: nil)
        
        if isBeingDismissed {
            delegate?.willDismissPlayer()
            NotificationCenter.default.post(name: .refreshFeedUI, object: nil)
        }
    }
    
    override func endAppearanceTransition() {
        super.endAppearanceTransition()
        
        if isBeingDismissed {
            podcastPlayerController.finishAndSaveContentConsumed()
            podcastPlayerController.removeFromDelegatesWith(key: PodcastDelegateKeys.PodcastPlayerView.rawValue)
        }
    }
    
    static func instantiate(
        podcast: PodcastFeed,
        delegate: PodcastPlayerVCDelegate,
        boostDelegate: CustomBoostDelegate,
        fromDashboard: Bool
    ) -> NewPodcastPlayerViewController {
        let viewController = StoryboardScene.WebApps.newPodcastPlayerViewController.instantiate()
        
        viewController.podcast = podcast
        viewController.delegate = delegate
        viewController.boostDelegate = boostDelegate
        viewController.fromDashboard = fromDashboard
    
        return viewController
    }
    
    @objc func showPodcastInfo() {
        tableHeaderView = PodcastPlayerView(
            podcast: podcast,
            delegate: self,
            boostDelegate: self,
            fromDashboard: fromDashboard
        )
        
        tableView.tableHeaderView = tableHeaderView
        
        tableDataSource = PodcastEpisodesDataSource(
            tableView: tableView,
            podcast: podcast,
            delegate: self
        )
        
        podcastPlayerController.addDelegate(tableHeaderView!, withKey: PodcastDelegateKeys.PodcastPlayerView.rawValue)
    }
    
    private func updateFeed() {
        if let feedUrl = podcast.feedURLPath, let objectID = podcast.objectID {
            
            let feedsManager = FeedsManager.sharedInstance
            feedsManager.fetchItemsFor(feedUrl: feedUrl, objectID: objectID)
        }
    }
}

extension NewPodcastPlayerViewController : PodcastEpisodesDSDelegate {
    func deleteTapped(_ indexPath: IndexPath, episode: PodcastEpisode) {
        episode.shouldDeleteFile {
            self.reload(indexPath.row)
        }
    }
    
    func didTapEpisodeAt(index: Int) {
        tableHeaderView?.didTapEpisodeAt(index: index)
    }
    
    func shouldToggleTopView(show: Bool) {
        topFixingView.isHidden = !show
    }
    
    func cancelTapped(_ indexPath: IndexPath, episode: PodcastEpisode) {
        downloadService.cancelDownload(episode)
        reload(indexPath.row)
    }

    func downloadTapped(_ indexPath: IndexPath, episode: PodcastEpisode) {
        downloadService.startDownload(episode)
        reload(indexPath.row)
    }
    
    func showEpisodeDetails(episode: PodcastEpisode, indexPath:IndexPath) {
        let vc = FeedItemDetailVC.instantiate(episode: episode, delegate: self, indexPath: indexPath)
        self.present(vc, animated: true)
    }

    func pauseTapped(_ indexPath: IndexPath, episode: PodcastEpisode) {
        downloadService.pauseDownload(episode)
        reload(indexPath.row)
    }

    func resumeTapped(_ indexPath: IndexPath, episode: PodcastEpisode) {
        downloadService.resumeDownload(episode)
        reload(indexPath.row)
    }
    
    func reload(_ row: Int) {
        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
    }
}

extension NewPodcastPlayerViewController : PodcastPlayerViewDelegate {
    
    func didTapSubscriptionToggleButton() {
        if let objectID = podcast.objectID {
            podcast.isSubscribedToFromSearch.toggle()
            
            let contentFeed: ContentFeed? = CoreDataManager.sharedManager.getObjectWith(objectId: objectID)
            contentFeed?.isSubscribedToFromSearch.toggle()
            contentFeed?.managedObjectContext?.saveContext()
        }
    }
    
    func didFailPlayingPodcast() {
        AlertHelper.showAlert(title: "generic.error.title".localized, message: "error.playing".localized, on: self)
    }
    
    func shouldReloadEpisodesTable() {
        tableView.reloadData()
    }
    
    func shouldShareClip(comment: PodcastComment) {
        self.delegate?.shouldShareClip(comment: comment)
        self.dismiss(animated: true)
    }
    
    func shouldSyncPodcast() {
        if let podcast = podcast {
            FeedsManager.sharedInstance.saveContentFeedStatus(for: podcast.feedID)
        }
    }
    
    func shouldShowSpeedPicker() {
        let selectedValue = podcast.playerSpeed
        let pickerVC = PickerViewController.instantiate(values: ["0.5", "0.8", "1.0", "1.2", "1.5", "2.1"], selectedValue: "\(selectedValue)", delegate: self)
        self.present(pickerVC, animated: false, completion: nil)
    }
}

extension NewPodcastPlayerViewController : CustomBoostDelegate {
    func didStartEditingBoostAmount() {
        if tableView.numberOfRows(inSection: 0) < 2{
            return
        }
        let ip = IndexPath(item: 1, section: 0)
        self.tableView.scrollToRow(at: ip, at: .middle, animated: true)
    }
    
    func didSendBoostMessage(success: Bool, message: TransactionMessage?) {
        boostDelegate?.didSendBoostMessage(success: success, message: message)
    }
}

extension NewPodcastPlayerViewController : PickerViewDelegate {
    func didSelectValue(value: String) {
        if let newSpeed = Float(value), newSpeed >= 0.5 && newSpeed <= 2.1 {
            
            guard let podcastData = podcast.getPodcastData(
                playerSpeed: newSpeed
            ) else {
                return
            }
            
            podcastPlayerController.submitAction(
                UserAction.AdjustSpeed(podcastData)
            )
            
            tableHeaderView?.configureControls()
            
            shouldSyncPodcast()
        }
    }
}

extension NewPodcastPlayerViewController: URLSessionDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                appDelegate.backgroundSessionCompletionHandler = nil
                completionHandler()
            }
        }
    }
}

extension NewPodcastPlayerViewController : DownloadServiceDelegate {
    func shouldReloadRowFor(download: Download) {
        if let index = podcast.getIndexForEpisodeWith(id: download.episode.itemID) {
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }
    
    func shouldUpdateProgressFor(download: Download) {
        if let index = podcast.getIndexForEpisodeWith(id: download.episode.itemID) {
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }
}

extension UIViewController {
    func shareTapped(episode: PodcastEpisode){
        let firstActivityItem =
        "Hey I think you'd enjoy this content I found on Sphinx iOS: \(episode.feed?.title ?? "") - \(episode.title ?? "")"
        
        //TODO: need a way to decide whether to use time stamp
        let link = episode.constructShareLink() ?? episode.linkURLPath ?? episode.urlPath ?? ""
        
        let secondActivityItem : NSURL = NSURL(string: link)!
        
        if let imageUrl = episode.imageToShow, let url = URL(string: imageUrl) {
            URLSession.shared.dataTask(with: url) { (data, _, _) in
                guard let data = data, let image = UIImage(data: data) else {
                    self.shouldShare(
                        items: [firstActivityItem, secondActivityItem]
                    )
                    return
                }

                self.shouldShare(
                    items: [firstActivityItem, secondActivityItem, image]
                )
            }.resume()
        } else {
            shouldShare(
                items: [firstActivityItem, secondActivityItem]
            )
        }
    }
    
    func shareTapped(video: Video) {
        let firstActivityItem =
        "Hey I think you'd enjoy this video I found on Sphinx iOS: \(video.videoFeed?.title ?? "") - \(video.title ?? "")"
        
        guard let videoURL = video.itemURL else{
            return
        }
        let secondActivityItem : NSURL = videoURL as NSURL
        
        if let imageUrl = video.videoFeed?.imageToShow, let url = URL(string: imageUrl) {
            URLSession.shared.dataTask(with: url) { (data, _, _) in
                guard let data = data, let image = UIImage(data: data) else {
                    self.shouldShare(
                        items: [firstActivityItem, secondActivityItem]
                    )
                    return
                }

                self.shouldShare(
                    items: [firstActivityItem, secondActivityItem, image]
                )
            }.resume()
        } else {
            shouldShare(
                items: [firstActivityItem, secondActivityItem]
            )
        }
    }
    
    func shouldShare(
        items: [Any]
    ) {
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        // This lines is for the popover you need to show in iPad
        activityViewController.popoverPresentationController?.sourceView = self.view
        
        // This line remove the arrow of the popover to show in iPad
        activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.down
        activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
        
        // Pre-configuring activity items
        activityViewController.activityItemsConfiguration = [
            UIActivity.ActivityType.message
        ] as? UIActivityItemsConfigurationReading
        
        // Anything you want to exclude
        activityViewController.excludedActivityTypes = [
            UIActivity.ActivityType.postToWeibo,
            UIActivity.ActivityType.print,
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.addToReadingList,
            UIActivity.ActivityType.postToFlickr,
            UIActivity.ActivityType.postToVimeo,
            UIActivity.ActivityType.postToTencentWeibo
        ]
        
        activityViewController.isModalInPresentation = true
        
        DispatchQueue.main.async {
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
}
