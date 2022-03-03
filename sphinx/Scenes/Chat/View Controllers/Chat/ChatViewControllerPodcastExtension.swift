//
//  ChatViewControllerPodcastExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

extension ChatViewController : CustomBoostDelegate {
    func didSendBoostMessage(success: Bool, message: TransactionMessage?) {
        guard let message = message, success else {
            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                self.didFailSendingMessage(provisionalMessage: message)
            })
            return
        }
        self.insertSentMessage(message: message, completion: { _ in })
        self.scrollAfterInsert()
    }
}

extension ChatViewController : PodcastPlayerVCDelegate {
    func shouldDismissPlayerView() {}
    
    func loadPodcastFeed() {
        guard let chat = chat else {
            return
        }
        
        FeedLoaderHelper.loadPodcastFeedFor(chat: chat, callback: { podcast in
            self.addSmallPlayerFor(podcast, completion: {
                PodcastNewEpisodeViewController.checkForNewEpisode(chat: chat, rootViewController: self.rootViewController)
            })
            self.chatHeaderView.updateSatsEarned()
        })
    }
    
    func shouldShareClip(comment: PodcastComment) {
        accessoryView.addKeyboardObservers()
        accessoryView.configureReplyFor(podcastComment: comment)
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
    }
    
    func addSmallPlayerFor(
        _ podcast: PodcastFeed,
        completion: @escaping () -> ()
    ) {
        accessoryView.configurePlayerViewWith(
            podcast: podcast,
            delegate: self,
            completion: completion
        )
    }
    
    func presentPodcastPlayer(chat: Chat) {
        if let podcast = chat.podcast {
            accessoryView.hide()
            
            let podcastFeedVC = NewPodcastPlayerViewController.instantiate(
                podcast: podcast,
                dismissButtonStyle: .downArrow,
                delegate: self,
                boostDelegate: self
            )

            podcastFeedVC.modalPresentationStyle = .automatic

            present(podcastFeedVC, animated: true, completion: nil)
        }
    }
}
