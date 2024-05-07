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
    
    var chat: Chat? {
        get {
            return podcast.chat
        }
    }
    
    var fromDashboard = false
    var fromDownloadedSection = false
    
    var downloadedFeedEpisodeID : String? = nil
    
    var podcastPlayerController = PodcastPlayerController.sharedInstance
    
    let downloadService = DownloadService.sharedInstance
    
    var queuedEpisode : PodcastEpisode? = nil
    
    var tableDataSource: PodcastEpisodesDataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        downloadService.setDelegate(
            delegate: self,
            forKey: DownloadServiceDelegateKeys.PodcastPlayerDelegate
        )
        
        showPodcastInfo()
        updateFeed()
        
        NotificationCenter.default.addObserver(forName: .onConnectionStatusChanged, object: nil, queue: OperationQueue.main) { (n: Notification) in
            self.tableView.reloadData()
        }
        
        NotificationCenter.default.removeObserver(self, name: .refreshFeedUI, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showPodcastInfo), name: .refreshFeedUI, object: nil)
        
        handleQueuedEpisode()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .onConnectionStatusChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: .refreshFeedUI, object: nil)
        
        if let navController = self.navigationController, navController.isBeingDismissed {
            delegate?.willDismissPlayer()
            NotificationCenter.default.post(name: .refreshFeedUI, object: nil)
        }
    }
    
    func handleQueuedEpisode(){
        if let queuedEpisode = queuedEpisode,
           let episodeIndex = tableDataSource.episodes.firstIndex(where: {$0.itemID == queuedEpisode.itemID}){
            self.tableDataSource.tableView(tableDataSource.tableView, didSelectRowAt: IndexPath(item: episodeIndex, section: 0))
            FeedsManager.sharedInstance.queuedPodcastEpisodes.removeAll(where: {$0.itemID == queuedEpisode.itemID})
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
        fromDashboard: Bool = false,
        fromDownloadedSection: Bool = false,
        queuedEpisode:PodcastEpisode? = nil
    ) -> NewPodcastPlayerViewController {
        let viewController = StoryboardScene.WebApps.newPodcastPlayerViewController.instantiate()
        
        viewController.podcast = podcast
        viewController.delegate = delegate
        viewController.boostDelegate = boostDelegate
        viewController.fromDashboard = fromDashboard
        viewController.fromDownloadedSection = fromDownloadedSection
        viewController.queuedEpisode = queuedEpisode
    
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
            delegate: self,
            fromDownloadedSection: fromDownloadedSection
        )
        
        podcastPlayerController.addDelegate(tableHeaderView!, withKey: PodcastDelegateKeys.PodcastPlayerView.rawValue)
    }
    
    private func updateFeed() {
        if let feedUrl = podcast.feedURLPath {
            let feedsManager = FeedsManager.sharedInstance
            feedsManager.fetchItemsFor(feedUrl: feedUrl, feedId: podcast.feedID)
        }
    }
}

extension NewPodcastPlayerViewController : PodcastEpisodesDSDelegate {
    func didDismiss() {}
    
    func didTapForDescriptionAt(episode: PodcastEpisode,cell:UITableViewCell) {
        if let feed = episode.feed,
           let index = tableView.indexPath(for: cell)?.row{
            let vc = ItemDescriptionViewController.instantiate(podcast: feed, episode: episode,index:index)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func deleteTapped(_ indexPath: IndexPath, episode: PodcastEpisode) {
        episode.shouldDeleteFile {
            self.reload(indexPath.row)
        }
    }
    
    func didTapEpisodeWith(
        episodeId: String
    ) {
        tableHeaderView?.didTapEpisodeWith(
            episodeId: episodeId
        )        
    }
    
    func shouldToggleTopView(show: Bool) {
        topFixingView.isHidden = !show
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
        if tableView.numberOfRows(inSection: 0) > row {
            tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
        }
    }
}

extension NewPodcastPlayerViewController : PodcastPlayerViewDelegate {
    
    func didTapSubscriptionToggleButton() {
        podcast.isSubscribedToFromSearch.toggle()
        
        let contentFeed: ContentFeed? = ContentFeed.getFeedById(feedId: podcast.feedID)
        contentFeed?.isSubscribedToFromSearch.toggle()
        contentFeed?.managedObjectContext?.saveContext()
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
}

extension UIViewController {
    func askForShareType(
        episode: PodcastEpisode
    ) {
        if episode.feed?.isRecommendationsPodcast == true {
            self.executeShare(episode: episode,useCurrentTime: false)
            return
        }
        
        let timestampCallback: (() -> ()) = {
            self.executeShare(episode: episode,useCurrentTime: true)
        }
        let noTimestampCallback: (() -> ()) = {
            self.executeShare(episode: episode,useCurrentTime: false)
        }
        
        AlertHelper.showOptionsPopup(
            title: "Share from Current Timestamp?",
            message: "You can share from the beginning or from current timestamp to make it easy for the recipient.",
            options: ["share.from.beginning".localized,"share.from.current.time".localized],
            callbacks: [noTimestampCallback, timestampCallback],
            sourceView: self.view,
            vc: self
        )
    }
    
    func executeShare(
        episode: PodcastEpisode,
        useCurrentTime: Bool = false
    ){
        let firstActivityItem = "Hey I think you'd enjoy this content I found on Sphinx iOS: \(episode.feed?.title ?? "") - \(episode.title ?? "")"
        
        //TODO: need a way to decide whether to use time stamp
        let link = episode.constructShareLink(useTimestamp: useCurrentTime) ?? episode.linkURLPath ?? episode.urlPath ?? ""
        
        let secondActivityItem : NSURL = NSURL(string: link)!
        
        shouldShare(
            items: [firstActivityItem, secondActivityItem]
        )
    }

    func shareTapped(
        newsletterItem: NewsletterItem
    ) {
        if let link = newsletterItem.constructShareLink() {
            let firstActivityItem =
            "Hey I think you'd enjoy this newsletter I found on Sphinx iOS: \(newsletterItem.newsletterFeed?.title ?? "") - \(newsletterItem.title ?? "")"
            
            let secondActivityItem : NSURL = NSURL(string: link)!
            
            if let imageUrl = newsletterItem.imageUrl?.path, let url = URL(string: imageUrl) {
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
    }
    
    func shareTapped(
        episode: PodcastEpisode
    ) {
        askForShareType(episode:episode)
    }
    
    func askForShareType(
        video: Video,
        currentTime: Int
    ) {
        let timestampCallback: (() -> ()) = {
            self.executeShare(video: video, videoTime: currentTime)
        }
        let noTimestampCallback: (() -> ()) = {
            self.executeShare(video: video)
        }
        AlertHelper.showOptionsPopup(
            title: "Share from Current Timestamp?",
            message: "You can share from the beginning or from current timestamp to make it easy for the recipient.",
            options: ["Share from beginning","Share from current time"],
            callbacks: [noTimestampCallback,timestampCallback],
            sourceView: self.view,
            vc: self
        )
    }
    
    func executeShare(
        video: Video,
        videoTime: Int? = nil
    ) {
        let firstActivityItem =
        "Hey I think you'd enjoy this video I found on Sphinx iOS: \(video.videoFeed?.title ?? "") - \(video.title ?? "")"
        
        let videoURL = video.constructShareLink(currentTimeStamp: videoTime) ?? ""
        
        let secondActivityItem : NSURL = NSURL(string: videoURL)!
        
        shouldShare(
            items: [firstActivityItem, secondActivityItem]
        )
    }
    
    func shareTapped(
        video: Video
    ) {
        let videoCurrentTime = UserDefaults.standard.integer(forKey: "videoID-\(video.id)-currentTime")
        
        if videoCurrentTime != 0 {
            askForShareType(video: video, currentTime: videoCurrentTime)
        } else {
            executeShare(video: video)
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

extension NewPodcastPlayerViewController : ItemDescriptionViewControllerDelegate{
    func shouldDismissAndPlayVideo(video:Video){}
    func shouldDismissAndPlayVideo(episodeAsVideo:PodcastEpisode){}
    
    func didDismissDescriptionView(index:Int){
        self.reload(index)
    }
}
