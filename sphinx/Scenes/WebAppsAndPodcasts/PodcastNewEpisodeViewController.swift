//
//  PodcastNewEpisodeViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/03/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import UIKit

protocol NewEpisodeDelegate : class {
    func shouldGoToLastEpisodePlayer()
}

class PodcastNewEpisodeViewController: UIViewController {
    
    weak var delegate: NewEpisodeDelegate?
    
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
    
    static func checkForNewEpisode(chat: Chat, rootViewController: RootViewController, delegate: NewEpisodeDelegate) {
        if (chat.podcastPlayer?.podcast?.episodes ?? []).count == 0 { return }
        guard let chatId = rootViewController.getChatVCId() else { return }
        if chatId != chat.id { return }

        let lastStoredEpisodeId = (chat.podcastPlayer?.lastEpisodeId ?? chat.podcastPlayer?.currentEpisodeId) ?? -1

        if let lastEpisode = chat.podcastPlayer?.podcast?.episodes[0] {
            let lastEpisodeId = lastEpisode.id
            
            chat.podcastPlayer?.lastEpisodeId = lastEpisodeId

            if lastStoredEpisodeId > 0 && lastStoredEpisodeId != lastEpisodeId {
                let podcastNewEpisodeVC = PodcastNewEpisodeViewController.instantiate()
                podcastNewEpisodeVC.episode = lastEpisode
                podcastNewEpisodeVC.delegate = delegate
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
        
        if let image = episode.image, let url = URL(string: image) {
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
