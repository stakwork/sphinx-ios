//
//  PodcastNewEpisodeViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/03/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import UIKit

class PodcastNewEpisodeViewController: UIViewController {
    
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var newEpisodeView: UIView!
    @IBOutlet weak var bubbleArrowView: UIView!
    @IBOutlet weak var newEpisodeImage: UIImageView!
    @IBOutlet weak var newEpisodeTitle: UILabel!
    @IBOutlet weak var newEpisodeDescription: UILabel!
    
    var episode: PodcastEpisode! = nil
    
    static func instantiate() -> PodcastNewEpisodeViewController {
        let viewController = StoryboardScene.WebApps.podcastNewEpisodeViewController.instantiate()
        return viewController
    }
    
    static func checkForNewEpisode(
        chatId: Int?
    ) {
        if let chatId = chatId, let chat = Chat.getChatWith(id: chatId) {
            if let podcast = chat.podcast {
                checkForNewEpisode(podcast: podcast)
            }
        }
    }
    
    static func checkForNewEpisode(
        chat: Chat
    ) {
        if let podcast = chat.podcast {
            checkForNewEpisode(podcast: podcast)
        }
    }
    
    static func checkForNewEpisode(
        podcast: PodcastFeed
    ) {
        if podcast.episodes?.count == 0 { return }

        let lastStoredEpisodeId = podcast.lastEpisodeId ?? podcast.currentEpisodeId

        if podcast.episodesArray.count > 0 {
            
            let lastEpisode = podcast.episodesArray[0]
            let lastEpisodeId = lastEpisode.itemID
            
            podcast.lastEpisodeId = lastEpisodeId

            if !lastStoredEpisodeId.isEmpty &&
                lastStoredEpisodeId != lastEpisodeId {
                
                let podcastNewEpisodeVC = PodcastNewEpisodeViewController.instantiate()
                podcastNewEpisodeVC.episode = lastEpisode
                WindowsManager.sharedInstance.showConveringWindowWith(rootVC: podcastNewEpisodeVC)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        bubbleView.layer.cornerRadius = 4
        newEpisodeView.layer.cornerRadius = 2
        
        newEpisodeImage.roundCorners(corners: [.topLeft, .bottomLeft], radius: 4)
        bubbleArrowView.addDownTriangle(color: UIColor.Sphinx.BodyInverted)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.view.addGestureRecognizer(tap)
        
        configureEpisode()
        
        UIView.animate(withDuration: 0.2, delay: 0.2, options: [], animations: {
            self.viewContainer.alpha = 1.0
        }, completion: {_ in})
    }
    
    func configureEpisode() {
        newEpisodeTitle.text = episode.title ?? "title.not.available"
        newEpisodeTitle.layoutIfNeeded()
        
        if newEpisodeTitle.frame.height > 20 {
            newEpisodeTitle.font = UIFont(name: "Roboto-Medium", size: 14.0)!
        }
        
        if let imageURLPath = episode.imageURLPath, let url = URL(string: imageURLPath) {
            MediaLoader.asyncLoadImage(imageView: newEpisodeImage, nsUrl: url, placeHolderImage: UIImage(named: "profile_avatar"), completion: { img in
                self.newEpisodeImage.image = img
            }, errorCompletion: { _ in
                self.newEpisodeImage.image = nil
            })
        }
    }
    
    @objc func viewTapped() {
        dismissTooltip()
    }
    
    func dismissTooltip() {
        WindowsManager.sharedInstance.removeCoveringWindow()
    }
}
