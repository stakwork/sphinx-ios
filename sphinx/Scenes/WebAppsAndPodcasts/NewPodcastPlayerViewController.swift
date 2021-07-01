//
//  NewPodcastPlayerViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol PodcastPlayerVCDelegate: class {
    func willDismissPlayer(playing: Bool)
    func shouldShareClip(comment: PodcastComment)
    func shouldGoToPlayer()
    func shouldSendBoost(message: String, amount: Int, animation: Bool) -> TransactionMessage?
}

class NewPodcastPlayerViewController: UIViewController {
    
    weak var delegate: PodcastPlayerVCDelegate?
    
    @IBOutlet weak var topFixingView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var tableHeaderView: PodcastPlayerView? = nil
    
    var chat: Chat! = nil
    var playerHelper: PodcastPlayerHelper! = nil
    var tableDataSource: PodcastEpisodesDataSource!
    
    let downloadService = DownloadService.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        downloadService.setDelegate(delegate: self)
        
        showPodcastInfo()
        
        NotificationCenter.default.addObserver(forName: .onConnectionStatusChanged, object: nil, queue: OperationQueue.main) { (n: Notification) in
            self.tableView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .onConnectionStatusChanged, object: nil)
        
        if isBeingDismissed {
            let playing = playerHelper.isPlaying()
            delegate?.willDismissPlayer(playing: playing)
        }
    }
    
    static func instantiate(chat: Chat, playerHelper: PodcastPlayerHelper, delegate: PodcastPlayerVCDelegate) -> NewPodcastPlayerViewController {
        let viewController = StoryboardScene.WebApps.newPodcastPlayerViewController.instantiate()
        viewController.chat = chat
        viewController.playerHelper = playerHelper
        viewController.delegate = delegate
        return viewController
    }
    
    func preparePlayer() {
        tableHeaderView?.preparePlayer()
        tableView.reloadData()
    }
    
    func showPodcastInfo() {
        showEpisodesTable()
        preparePlayer()
    }
    
    func showEpisodesTable() {
        if let _ = playerHelper.podcast {
            tableHeaderView = PodcastPlayerView(playerHelper: playerHelper, chat: chat, delegate: self)
            tableView.tableHeaderView = tableHeaderView!
            tableDataSource = PodcastEpisodesDataSource(tableView: tableView, playerHelper: playerHelper, delegate: self)
        } else {
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized, completion: {
                self.dismiss(animated: true, completion: nil)
            })
        }
    }
}

extension NewPodcastPlayerViewController : PodcastEpisodesDSDelegate {
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
    func didTapDismissButton() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func shouldReloadEpisodesTable() {
        tableView.reloadData()
    }
    
    func shouldShareClip(comment: PodcastComment) {
        self.delegate?.shouldShareClip(comment: comment)
        self.dismiss(animated: true, completion: nil)
    }
    
    func shouldSendBoost(message: String, amount: Int, animation: Bool) -> TransactionMessage? {
        return delegate?.shouldSendBoost(message: message, amount: amount, animation: animation)
    }
    
    func shouldSyncPodcast() {
        chat?.updateMetaData()
    }
    
    func shouldShowSpeedPicker() {
        let selectedValue = playerHelper.playerSpeed
        let pickerVC = PickerViewController.instantiate(values: ["0.5", "0.8", "1.0", "1.2", "1.5", "2.1"], selectedValue: "\(selectedValue)", delegate: self)
        self.present(pickerVC, animated: false, completion: nil)
    }
}

extension NewPodcastPlayerViewController : PickerViewDelegate {
    func didSelectValue(value: String) {
        if let floatValue = Float(value), floatValue >= 0.5 && floatValue <= 2.1 {
            playerHelper.changeSpeedTo(value: floatValue)
            tableHeaderView?.configureControls()
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
        if let index = playerHelper.getIndexFor(episode: download.episode) {
            DispatchQueue.main.async {
              self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            }
        }
    }
    
    func shouldUpdateProgressFor(download: Download) {
        if let index = playerHelper.getIndexFor(episode: download.episode) {
            if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? PodcastEpisodeTableViewCell {
                cell.updateProgress(progress: download.progress)
            }
        }
    }
}
