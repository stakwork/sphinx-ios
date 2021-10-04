//
//  ChatViewControllerPodcastExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

extension ChatViewController : PodcastPlayerVCDelegate {
    func shouldDismissPlayerView() {}
    
    func loadPodcastFeed() {        
        podcastPlayerHelper?.loadPodcastFeed(chat: chat, callback: { success in
            if
                let chat = self.chat,
                let _ = chat.podcastPlayer?.podcast,
                success
            {
                self.addSmallPlayer(completion: {
                    PodcastNewEpisodeViewController.checkForNewEpisode(chat: chat, rootViewController: self.rootViewController, delegate: self)
                })
                self.chatHeaderView.updateSatsEarned()
            }
        })
    }
    
    func shouldShareClip(comment: PodcastComment) {
        accessoryView.addKeyboardObservers()
        accessoryView.configureReplyFor(podcastComment: comment)
    }
    
    func shouldSendBoost(message: String, amount: Int, animation: Bool) -> TransactionMessage? {
        if animation {
            let podcastAnimationVC = PodcastAnimationViewController.instantiate(amount: amount)
            WindowsManager.sharedInstance.showConveringWindowWith(rootVC: podcastAnimationVC)
            podcastAnimationVC.showBoostAnimation()
        }
        let boostType = TransactionMessage.TransactionMessageType.boost.rawValue
        return createProvisionalAndSend(messageText: message, type: boostType, botAmount: 0, completion: { _ in })
    }
    
    func shouldGoToPlayer() {
        guard let chat = chat else {
            return
        }
        presentPodcastPlayer(chat: chat)
    }
    
    func willDismissPlayer(playing: Bool) {
        accessoryView.addKeyboardObservers()
        accessoryView.show(animated: false)
        accessoryView.reloadPlayerView()
    }
    
    func addSmallPlayer(completion: @escaping () -> ()) {
        guard let podcastPlayerHelper = podcastPlayerHelper else {
            return
        }
        accessoryView.configurePlayerView(playerHelper: podcastPlayerHelper, delegate: self, completion: completion)
    }
    
    func presentPodcastPlayer(chat: Chat) {
        guard let podcastPlayerHelper = podcastPlayerHelper else {
            return
        }
        accessoryView.hide()

        let podcastFeedVC = NewPodcastPlayerViewController.instantiate(
            chat: chat,
            playerHelper: podcastPlayerHelper,
            dismissButtonStyle: .downArrow,
            delegate: self
        )
        podcastFeedVC.modalPresentationStyle = .fullScreen
        self.present(podcastFeedVC, animated: true, completion: nil)
    }
}

extension ChatViewController : NewEpisodeDelegate {
    func shouldGoToLastEpisodePlayer() {
        chat?.podcastPlayer?.goToLastEpisode()
        shouldGoToPlayer()
    }
}
